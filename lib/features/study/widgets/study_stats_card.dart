import 'package:flutter/material.dart';

/// 学习统计卡片
///
/// 展示今日学习时长和本周学习时长。
class StudyStatsCard extends StatelessWidget {
  /// 今日学习时长（分钟）
  final int todayMinutes;

  /// 本周学习时长（分钟）
  final int weeklyMinutes;

  const StudyStatsCard({
    super.key,
    required this.todayMinutes,
    required this.weeklyMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _StatItem(
              icon: Icons.timer,
              label: '今日',
              value: '$todayMinutes 分钟',
              theme: theme,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 40, color: theme.dividerColor),
            const SizedBox(width: 8),
            _StatItem(
              icon: Icons.calendar_today,
              label: '本周',
              value: '$weeklyMinutes 分钟',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
