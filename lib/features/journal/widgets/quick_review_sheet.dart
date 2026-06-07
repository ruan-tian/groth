import 'package:flutter/material.dart';
import '../../../app/design/design.dart';
import '../../../shared/widgets/common/common_widgets.dart';

/// 快速复盘底部弹窗
///
/// 用户选择心情 + 写一句话总结，快速完成每日复盘。
/// 通过 [onSave] 回调将结果传递给调用方持久化。
class QuickReviewSheet extends StatefulWidget {
  const QuickReviewSheet({super.key, required this.onSave});

  /// 保存回调 (mood, summary)
  final void Function(String mood, String summary) onSave;

  @override
  State<QuickReviewSheet> createState() => _QuickReviewSheetState();
}

class _QuickReviewSheetState extends State<QuickReviewSheet> {
  String? _selectedMood;
  final _summaryController = TextEditingController();

  bool get _isValid =>
      _selectedMood != null && _summaryController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      title: '快速复盘',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 心情选择 ──
          Text('今天心情如何？', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MoodButton(
                emoji: '😊',
                label: '开心',
                selected: _selectedMood == 'happy',
                onTap: () => setState(() => _selectedMood = 'happy'),
              ),
              _MoodButton(
                emoji: '😐',
                label: '平静',
                selected: _selectedMood == 'neutral',
                onTap: () => setState(() => _selectedMood = 'neutral'),
              ),
              _MoodButton(
                emoji: '😢',
                label: '难过',
                selected: _selectedMood == 'sad',
                onTap: () => setState(() => _selectedMood = 'sad'),
              ),
              _MoodButton(
                emoji: '😡',
                label: '生气',
                selected: _selectedMood == 'angry',
                onTap: () => setState(() => _selectedMood = 'angry'),
              ),
              _MoodButton(
                emoji: '🤔',
                label: '思考',
                selected: _selectedMood == 'thinking',
                onTap: () => setState(() => _selectedMood = 'thinking'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 一句话总结 ──
          Text('今天最值得记录的是什么？', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _summaryController,
            maxLines: 1,
            maxLength: 60,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: '一句话总结今天...',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textHint,
              ),
              counterText: '${_summaryController.text.length}/60',
              counterStyle: AppTextStyles.caption,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 保存按钮 ──
          PrimaryButton(
            text: '保存复盘',
            icon: Icons.check_rounded,
            onTap: _isValid
                ? () {
                    widget.onSave(
                      _selectedMood!,
                      _summaryController.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                : null,
            height: 52,
          ),
        ],
      ),
    );
  }
}

/// 心情选择按钮
class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: selected ? 32 : 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
