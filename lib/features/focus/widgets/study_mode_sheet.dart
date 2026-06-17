import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/settings_provider.dart';
import '../models/study_mode.dart';

/// 显示学习模式选择弹窗
void showStudyModeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _StudyModeSheet(),
  );
}

class _StudyModeSheet extends ConsumerWidget {
  const _StudyModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final currentMode = ref.watch(focusStudyModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 把手
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            const Text('选择学习模式', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            Text('切换后科目列表会自动更新', style: AppTextStyles.caption),
            const SizedBox(height: 20),
            // 模式列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: StudyMode.values.length,
                itemBuilder: (context, index) {
                  final mode = StudyMode.values[index];
                  final isSelected = mode == currentMode;
                  return _ModeTile(
                    mode: mode,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(focusStudyModeProvider.notifier).state = mode;
                      // 持久化
                      ref
                          .read(settingRepositoryProvider)
                          .setSetting('focus_study_mode', mode.name);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final StudyMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.focus.withValues(alpha: 0.10)
                : colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colors.focus.withValues(alpha: 0.32)
                  : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.focus.withValues(alpha: 0.12)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(mode.icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              // 名称 + 科目预览
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? colors.focus : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mode.subjects.take(5).join('、') +
                          (mode.subjects.length > 5 ? '...' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              // 选中指示
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: colors.focus, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
