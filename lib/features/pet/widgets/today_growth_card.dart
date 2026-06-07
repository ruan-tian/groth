import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/dashboard_provider.dart';

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
    final items = <_GrowthItem>[
      _GrowthItem(
        icon: Icons.menu_book_rounded,
        label: '学习',
        value: data.todayStudyMinutes,
        unit: '分钟',
        color: const Color(0xFF5D68F2),
      ),
      _GrowthItem(
        icon: Icons.fitness_center_rounded,
        label: '健身',
        value: data.todayFitnessMinutes,
        unit: '分钟',
        color: const Color(0xFFFF8A3D),
      ),
      _GrowthItem(
        icon: Icons.edit_note_rounded,
        label: '日记',
        value: data.todayJournalCount,
        unit: '篇',
        color: const Color(0xFFFF7EAA),
      ),
      _GrowthItem(
        icon: Icons.restaurant_rounded,
        label: '饮食',
        value: data.todayDietCount,
        unit: '次',
        color: const Color(0xFF6B8E23),
      ),
      _GrowthItem(
        icon: Icons.bedtime_rounded,
        label: '睡眠',
        value: _sleepHours(data.lastNightSleepDuration),
        unit: '小时',
        color: const Color(0xFF9B8FE8),
        isNull: data.lastNightSleepDuration == null,
      ),
      _GrowthItem(
        icon: Icons.center_focus_strong_rounded,
        label: '专注',
        value: data.todayFocusMinutes,
        unit: '分钟',
        color: const Color(0xFF00897B),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              const Text('今日成长',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
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
    if (isNull) return '—';
    if (value == 0) return '—';
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
    final dimmed = item.isEmpty;
    final effectiveColor = dimmed ? item.color.withValues(alpha: 0.35) : item.color;
    final bgColor = item.color.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
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
          Text(item.label,
              style: TextStyle(
                  fontSize: 12,
                  color: dimmed
                      ? AppColors.textTertiary.withValues(alpha: 0.4)
                      : AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(item.displayValue,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: effectiveColor)),
          if (!dimmed)
            Text(item.unit,
                style: TextStyle(
                    fontSize: 10,
                    color: effectiveColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 72,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.border,
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
                  color: AppColors.border.withValues(alpha: 0.5),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D4F)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('加载失败：$message',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
