import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 模块进度条组件
///
/// 显示学习/健身/日记的今日进度
class ModuleProgressBar extends StatelessWidget {
  const ModuleProgressBar({
    super.key,
    required this.current,
    required this.target,
    required this.label,
    required this.unit,
    required this.color,
    this.showPercentage = true,
  });

  /// 当前值
  final int current;

  /// 目标值
  final int target;

  /// 标签（如"学习"、"健身"、"日记"）
  final String label;

  /// 单位（如"分钟"、"篇"）
  final String unit;

  /// 进度条颜色
  final Color color;

  /// 是否显示百分比
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();
    final isCompleted = current >= target;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$current/$target$unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCompleted ? color : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (showPercentage) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.success : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 组合进度条（学习+健身+日记）
class CombinedProgressBar extends StatelessWidget {
  const CombinedProgressBar({
    super.key,
    required this.studyMinutes,
    required this.studyTarget,
    required this.fitnessMinutes,
    required this.fitnessTarget,
    required this.journalCount,
    required this.journalTarget,
  });

  final int studyMinutes;
  final int studyTarget;
  final int fitnessMinutes;
  final int fitnessTarget;
  final int journalCount;
  final int journalTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModuleProgressBar(
          current: studyMinutes,
          target: studyTarget,
          label: '学习',
          unit: '分钟',
          color: AppColors.study,
        ),
        const SizedBox(height: AppSpacing.sm),
        ModuleProgressBar(
          current: fitnessMinutes,
          target: fitnessTarget,
          label: '健身',
          unit: '分钟',
          color: AppColors.fitness,
        ),
        const SizedBox(height: AppSpacing.sm),
        ModuleProgressBar(
          current: journalCount,
          target: journalTarget,
          label: '日记',
          unit: '篇',
          color: AppColors.journal,
        ),
      ],
    );
  }
}
