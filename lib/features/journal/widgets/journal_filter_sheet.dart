import 'package:flutter/material.dart';
import '../../../app/design/design.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../shared/widgets/sort_button.dart';

/// 日记筛选底部弹窗
///
/// 支持按心情/标签筛选，以及排序方式切换。
/// 通过 [onApply] 回调将筛选结果传递给调用方。
class JournalFilterSheet extends StatefulWidget {
  const JournalFilterSheet({
    super.key,
    required this.selectedTag,
    required this.sortOrder,
    required this.onApply,
  });

  /// 当前选中的标签（null 表示全部）
  final String? selectedTag;

  /// 当前排序方式
  final SortOption sortOrder;

  /// 确认筛选回调
  final void Function(String? tag, SortOption sort) onApply;

  @override
  State<JournalFilterSheet> createState() => _JournalFilterSheetState();
}

class _JournalFilterSheetState extends State<JournalFilterSheet> {
  late String? _selectedTag;
  late SortOption _sortOrder;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.selectedTag;
    _sortOrder = widget.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      title: '筛选日记',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 心情筛选区 ──
          Text('按心情筛选', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MoodFilterButton(
                label: '全部',
                selected: _selectedTag == null,
                onTap: () => setState(() => _selectedTag = null),
              ),
              _MoodFilterButton(
                label: '😊 开心',
                selected: _selectedTag == 'happy',
                onTap: () => setState(() => _selectedTag = 'happy'),
              ),
              _MoodFilterButton(
                label: '😐 平静',
                selected: _selectedTag == 'neutral',
                onTap: () => setState(() => _selectedTag = 'neutral'),
              ),
              _MoodFilterButton(
                label: '😢 难过',
                selected: _selectedTag == 'sad',
                onTap: () => setState(() => _selectedTag = 'sad'),
              ),
              _MoodFilterButton(
                label: '🤔 思考',
                selected: _selectedTag == 'thinking',
                onTap: () => setState(() => _selectedTag = 'thinking'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 标签筛选区 ──
          Text('按标签筛选', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ['学习', '生活', '情绪', '成长', '工作', '健康'].map((tag) {
              final isSelected = _selectedTag == tag;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedTag = isSelected ? null : tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 排序控件 ──
          Text('排序方式', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<SortOption>(
              value: _sortOrder,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: SortOption.newest,
                  child: Text('最新在前'),
                ),
                DropdownMenuItem(
                  value: SortOption.oldest,
                  child: Text('最早在前'),
                ),
                DropdownMenuItem(
                  value: SortOption.highestExp,
                  child: Text('经验值最高'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOrder = value);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 操作按钮 ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTag = null;
                      _sortOrder = SortOption.newest;
                    });
                  },
                  child: const Text('重置'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  text: '确认筛选',
                  onTap: () {
                    widget.onApply(_selectedTag, _sortOrder);
                    Navigator.pop(context);
                  },
                  height: 48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 心情筛选按钮
class _MoodFilterButton extends StatelessWidget {
  const _MoodFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
