import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class TodayGrowthCard extends ConsumerWidget {
  const TodayGrowthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const _LoadingSkeleton(),
      error: (error, _) => _ErrorBanner(message: error.toString()),
      data: (data) => _buildCard(context, data),
    );
  }

  Widget _buildCard(BuildContext context, DashboardData data) {
    final colors = context.growthColors;
    final items = <_GrowthItem>[
      _GrowthItem(
        icon: Icons.menu_book_rounded,
        label: '学习',
        value: data.todayStudyMinutes,
        unit: '分钟',
        color: colors.study,
      ),
      _GrowthItem(
        icon: Icons.fitness_center_rounded,
        label: '健身',
        value: data.todayFitnessMinutes,
        unit: '分钟',
        color: colors.fitness,
      ),
      _GrowthItem(
        icon: Icons.edit_note_rounded,
        label: '日记',
        value: data.todayJournalCount,
        unit: '篇',
        color: colors.journal,
      ),
      _GrowthItem(
        icon: Icons.restaurant_rounded,
        label: '饮食',
        value: data.todayDietCount,
        unit: '次',
        color: colors.diet,
      ),
      _GrowthItem(
        icon: Icons.bedtime_rounded,
        label: '睡眠',
        value: _sleepHours(data.lastNightSleepDuration),
        unit: '小时',
        color: colors.sleep,
        isNull: data.lastNightSleepDuration == null,
      ),
      _GrowthItem(
        icon: Icons.center_focus_strong_rounded,
        label: '专注',
        value: data.todayFocusMinutes,
        unit: '分钟',
        color: colors.focus,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '今日成长',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) => _GrowthTile(item: items[index]),
          ),
        ],
      ),
    );
  }

  static double _sleepHours(int? minutes) {
    if (minutes == null) return 0;
    return (minutes / 60).roundToDouble();
  }
}

class _GrowthItem {
  const _GrowthItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isNull = false,
  });

  final IconData icon;
  final String label;
  final num value;
  final String unit;
  final Color color;
  final bool isNull;

  bool get isEmpty => value == 0 || isNull;

  String get displayValue {
    if (isNull) return '-';
    if (value == 0) return '-';
    if (value is double && value == (value as double).roundToDouble()) {
      return (value as double).toInt().toString();
    }
    return value.toString();
  }
}

class _GrowthTile extends StatelessWidget {
  const _GrowthTile({required this.item});

  final _GrowthItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final dimmed = item.isEmpty;
    final effectiveColor = dimmed
        ? item.color.withValues(alpha: 0.35)
        : item.color;

    return Container(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: effectiveColor),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: dimmed
                  ? colors.textTertiary.withValues(alpha: 0.4)
                  : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.displayValue,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
          if (!dimmed)
            Text(
              item.unit,
              style: TextStyle(
                fontSize: 11,
                color: effectiveColor.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 72,
                height: 16,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.danger.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '加载失败：$message',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
