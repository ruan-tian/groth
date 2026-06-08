import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/stats_formatters.dart';
import '../../../shared/providers/service_providers.dart';
import '../widgets/stats_skeleton.dart';
import '../../../shared/widgets/common/duration_line_chart.dart';
import '../../../shared/widgets/common/stats_summary_card.dart';

// =============================================================================
// Providers
// =============================================================================

/// 周偏移量 Provider：0 = 本周, -1 = 上周, -2 = 两周前
final weekOffsetProvider = StateProvider<int>((ref) => 0);

/// 指定周的每日统计 Provider
final weeklyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final offset = ref.watch(weekOffsetProvider);
  final now = DateTime.now();
  final end = now.subtract(Duration(days: offset * 7));
  final start = end.subtract(const Duration(days: 6));
  return statsService.getDailyStatsRange(start, end);
});

// =============================================================================
// WeeklyStatsPage
// =============================================================================

/// 周统计页面
///
/// 展示最近 7 天的成长趋势：
/// - 折线图（学习/健身时长）
/// - 汇总卡片（总学习、总健身、总经验）
/// - 周导航（上一周/下一周/回到本周）
class WeeklyStatsPage extends ConsumerWidget {
  const WeeklyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyStatsProvider);

    return weeklyStats.when(
      loading: () => const StatsSkeleton(),
      error: (error, stack) => _ErrorView(
        message: '加载失败: $error',
        onRetry: () => ref.invalidate(weeklyStatsProvider),
      ),
      data: (stats) => _WeeklyStatsContent(stats: stats),
    );
  }
}

// =============================================================================
// Content
// =============================================================================

class _WeeklyStatsContent extends ConsumerWidget {
  const _WeeklyStatsContent({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(weekOffsetProvider);

    // 计算汇总
    final totalStudy = stats.fold<int>(0, (sum, d) => sum + d.studyMinutes);
    final totalFitness = stats.fold<int>(0, (sum, d) => sum + d.fitnessMinutes);
    final totalExp = stats.fold<int>(0, (sum, d) => sum + d.expGained);

    // 计算周范围
    final now = DateTime.now();
    final end = now.subtract(Duration(days: offset * 7));
    final start = end.subtract(const Duration(days: 6));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── 周导航 ──
        _WeekNavigator(
          start: start,
          end: end,
          offset: offset,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 汇总卡片 ──
        Row(
          children: [
            Expanded(
              child: StatsSummaryCard(
                icon: Icons.menu_book_rounded,
                label: '总学习',
                value: formatMinutesShort(totalStudy),
                color: AppColors.study,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatsSummaryCard(
                icon: Icons.fitness_center_rounded,
                label: '总健身',
                value: formatMinutesShort(totalFitness),
                color: AppColors.fitness,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatsSummaryCard(
                icon: Icons.star_rounded,
                label: '总经验',
                value: formatExp(totalExp),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 时长趋势折线图（学习+健身） ──
        DurationLineChart(
          valuesInMinutes: stats
              .map((d) => d.studyMinutes + d.fitnessMinutes)
              .toList(),
          labels: stats.map((d) => '${d.date.month}/${d.date.day}').toList(),
          lineColor: AppColors.study,
          height: 200,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 每日明细 ──
        _DailyBreakdown(stats: stats),
      ],
    );
  }
}

// =============================================================================
// 周导航
// =============================================================================

class _WeekNavigator extends ConsumerWidget {
  const _WeekNavigator({
    required this.start,
    required this.end,
    required this.offset,
  });

  final DateTime start;
  final DateTime end;
  final int offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCurrentWeek = offset == 0;

    return Row(
      children: [
        // 左箭头（更早一周）
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            ref.read(weekOffsetProvider.notifier).state = offset - 1;
          },
        ),

        // 日期范围
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '周统计',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatWeekRange(start, end)} · ${isCurrentWeek ? '最近7天' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // 右箭头（更近一周，本周时禁用）
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: isCurrentWeek
              ? null
              : () {
                  ref.read(weekOffsetProvider.notifier).state = offset + 1;
                },
        ),

        // "本周"按钮（非本周时显示）
        if (!isCurrentWeek)
          TextButton(
            onPressed: () {
              ref.read(weekOffsetProvider.notifier).state = 0;
            },
            child: const Text('本周'),
          ),
      ],
    );
  }
}

// =============================================================================
// 每日明细列表
// =============================================================================

class _DailyBreakdown extends StatelessWidget {
  const _DailyBreakdown({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('每日明细', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        // 倒序显示（最近的在前）
        ...stats.reversed.map((day) {
          final weekday = weekdays[day.date.weekday - 1];
          final dateStr = '${day.date.month}/${day.date.day}';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    // 日期
                    SizedBox(
                      width: 72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weekday,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // 数据条
                    Expanded(
                      child: _MiniBar(
                        studyMinutes: day.studyMinutes,
                        fitnessMinutes: day.fitnessMinutes,
                        maxMinutes: _maxDayMinutes,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // 经验值
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${formatExp(day.expGained)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'EXP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 7 天中单日最大总分钟数（用于进度条比例）
  int get _maxDayMinutes {
    if (stats.isEmpty) return 1;
    return stats
        .map((d) => d.studyMinutes + d.fitnessMinutes)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 9999);
  }
}

/// 迷你进度条：学习 + 健身
class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.studyMinutes,
    required this.fitnessMinutes,
    required this.maxMinutes,
  });

  final int studyMinutes;
  final int fitnessMinutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final total = studyMinutes + fitnessMinutes;
    final totalRatio = maxMinutes > 0 ? total / maxMinutes : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxs),
      child: SizedBox(
        height: 8,
        child: total == 0
            ? Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            : FractionallySizedBox(
                widthFactor: totalRatio.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      flex: studyMinutes.clamp(1, 9999),
                      child: Container(color: AppColors.study),
                    ),
                    Expanded(
                      flex: fitnessMinutes.clamp(1, 9999),
                      child: Container(color: AppColors.fitness),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// =============================================================================
// Error View
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
