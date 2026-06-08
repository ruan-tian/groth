import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/stats_formatters.dart';
import '../../../shared/providers/service_providers.dart';
import '../widgets/stats_skeleton.dart';
import '../../../shared/widgets/common/stats_summary_card.dart';
import '../../../shared/widgets/common/duration_bar_chart.dart';
import '../widgets/exp_chart.dart';
import '../widgets/heatmap_calendar.dart';

// =============================================================================
// Providers
// =============================================================================

/// 年份偏移量 Provider（0 = 今年，1 = 去年，…）
final yearOffsetProvider = StateProvider<int>((ref) => 0);

/// 目标年份的月度聚合统计 Provider
///
/// 使用 [StatisticsService.getDailyStatsRange] 获取整年每日数据后
/// 在 Dart 层按月聚合为 [MonthlyAggregate]。
final yearlyStatsProvider = FutureProvider<List<MonthlyAggregate>>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final offset = ref.watch(yearOffsetProvider);
  final now = DateTime.now();
  final year = now.year - offset;
  final start = DateTime(year, 1, 1);
  final end = DateTime(year, 12, 31);
  final dailyList = await statsService.getDailyStatsRange(start, end);

  // 按月聚合
  final monthMap = <String, List<DailyStats>>{};
  for (final d in dailyList) {
    final key = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
    (monthMap[key] ??= []).add(d);
  }

  // 生成 12 个月的标签（保证顺序）
  final months = List.generate(
    12,
    (i) => '$year-${(i + 1).toString().padLeft(2, '0')}',
  );

  return months.map((m) {
    final days = monthMap[m] ?? [];
    return MonthlyAggregate(
      month: m,
      studyMinutes: days.fold(0, (s, d) => s + d.studyMinutes),
      fitnessMinutes: days.fold(0, (s, d) => s + d.fitnessMinutes),
      journalCount: days.fold(0, (s, d) => s + d.journalCount),
      dietCount: days.fold(0, (s, d) => s + d.dietCount),
      sleepMinutes: days.fold(0, (s, d) => s + d.sleepMinutes),
      focusMinutes: days.fold(0, (s, d) => s + d.focusMinutes),
      expGained: days.fold(0, (s, d) => s + d.expGained),
      activeDays: days.where((d) => d.isActiveDay).length,
      taskTotal: days.fold(0, (s, d) => s + d.taskTotal),
      taskCompleted: days.fold(0, (s, d) => s + d.taskCompleted),
    );
  }).toList();
});

/// 目标年份的每日统计 Provider（用于热力图）
final yearlyDailyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final offset = ref.watch(yearOffsetProvider);
  final now = DateTime.now();
  final year = now.year - offset;
  final start = DateTime(year, 1, 1);
  final end = DateTime(year, 12, 31);
  return statsService.getDailyStatsRange(start, end);
});

// =============================================================================
// YearlyStatsPage
// =============================================================================

/// 年统计页面
///
/// 最全面的统计视图，展示整年成长数据：
/// - 年份导航（前进/后退 + 回到今年）
/// - 汇总卡片（总学习、总健身、总经验）
/// - 月度趋势柱状图（12 个月）
/// - 成长热力图（GitHub 风格）
/// - EXP 趋势占位（Phase 5）
/// - 月度明细列表
class YearlyStatsPage extends ConsumerWidget {
  const YearlyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearlyStats = ref.watch(yearlyStatsProvider);

    return yearlyStats.when(
      loading: () => const StatsSkeleton(),
      error: (error, stack) => _ErrorView(
        message: '加载失败: $error',
        onRetry: () => ref.invalidate(yearlyStatsProvider),
      ),
      data: (stats) => _YearlyContent(monthlyStats: stats),
    );
  }
}

// =============================================================================
// Content
// =============================================================================

class _YearlyContent extends ConsumerWidget {
  const _YearlyContent({required this.monthlyStats});

  final List<MonthlyAggregate> monthlyStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyStats = ref.watch(yearlyDailyStatsProvider);

    // 计算年度汇总
    final totalStudy = monthlyStats.fold<int>(0, (s, m) => s + m.studyMinutes);
    final totalFitness =
        monthlyStats.fold<int>(0, (s, m) => s + m.fitnessMinutes);
    final totalExp = monthlyStats.fold<int>(0, (s, m) => s + m.expGained);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── 年份导航 ──
        const _YearNavigator(),
        const SizedBox(height: AppSpacing.lg),

        // ── 汇总卡片 ──
        _SummaryCards(
          totalStudy: totalStudy,
          totalFitness: totalFitness,
          totalExp: totalExp,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 月度趋势柱状图 ──
        _MonthlyTrendChart(monthlyStats: monthlyStats),
        const SizedBox(height: AppSpacing.lg),

        // ── 成长热力图 ──
        _HeatmapSection(dailyStats: dailyStats),
        const SizedBox(height: AppSpacing.lg),

        // ── EXP 趋势图 ──
        _ExpTrendPlaceholder(monthlyStats: monthlyStats),
        const SizedBox(height: AppSpacing.lg),

        // ── 月度明细 ──
        _MonthlyBreakdown(monthlyStats: monthlyStats),
      ],
    );
  }
}

// =============================================================================
// 年份导航
// =============================================================================

/// 年份导航组件
///
/// 显示格式：`←  2026年度  →` + `[今年]` 按钮
class _YearNavigator extends ConsumerWidget {
  const _YearNavigator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offset = ref.watch(yearOffsetProvider);
    final now = DateTime.now();
    final year = now.year - offset;

    return Column(
      children: [
        // ── 年份标题 + 左右箭头 ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 左箭头
            IconButton(
              onPressed: () {
                ref.read(yearOffsetProvider.notifier).state++;
              },
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: '上一年',
            ),
            const SizedBox(width: AppSpacing.sm),
            // 年份文字
            Text(
              formatYear(year),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 右箭头（禁用当已是今年）
            IconButton(
              onPressed: offset == 0
                  ? null
                  : () {
                      ref.read(yearOffsetProvider.notifier).state--;
                    },
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: '下一年',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── 回到今年按钮（仅在非今年时显示） ──
        if (offset != 0)
          TextButton.icon(
            onPressed: () {
              ref.read(yearOffsetProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.today_rounded, size: 16),
            label: const Text('今年'),
          ),
      ],
    );
  }
}

// =============================================================================
// 汇总卡片
// =============================================================================

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.totalStudy,
    required this.totalFitness,
    required this.totalExp,
  });

  final int totalStudy;
  final int totalFitness;
  final int totalExp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatsSummaryCard(
            icon: Icons.menu_book_rounded,
            label: '总学习',
            value: formatMinutesShort(totalStudy),
            color: AppColors.study,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatsSummaryCard(
            icon: Icons.fitness_center_rounded,
            label: '总健身',
            value: formatMinutesShort(totalFitness),
            color: AppColors.fitness,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatsSummaryCard(
            icon: Icons.star_rounded,
            label: '总经验',
            value: formatExp(totalExp),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 月度趋势柱状图
// =============================================================================

/// 12 个月的学习+健身时长柱状图
class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.monthlyStats});

  final List<MonthlyAggregate> monthlyStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '月度趋势',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '学习 + 健身时长',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DurationBarChart(
              valuesInMinutes: monthlyStats
                  .map((m) => m.studyMinutes + m.fitnessMinutes)
                  .toList(),
              labels: monthlyStats
                  .map((m) => '${int.parse(m.month.split('-')[1])}月')
                  .toList(),
              barColor: AppColors.study,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 成长热力图
// =============================================================================

/// 热力图区域 — 将每日统计转换为热力图格式
class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({required this.dailyStats});

  final AsyncValue<List<DailyStats>> dailyStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '成长热力图',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            dailyStats.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    '热力图加载失败',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              data: (stats) {
                final heatmapData = <DateTime, int>{};
                for (final stat in stats) {
                  if (stat.isActiveDay) {
                    heatmapData[DateTime(
                      stat.date.year,
                      stat.date.month,
                      stat.date.day,
                    )] = stat.activeModules;
                  }
                }
                return HeatmapCalendar(
                  data: heatmapData,
                  monthsToShow: 12,
                  showLegend: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EXP 趋势图
// =============================================================================

class _ExpTrendPlaceholder extends StatelessWidget {
  const _ExpTrendPlaceholder({required this.monthlyStats});

  final List<MonthlyAggregate> monthlyStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'EXP 趋势',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExpChart(
              values: monthlyStats.map((m) => m.expGained).toList(),
              labels: monthlyStats.map((m) {
                final month = int.parse(m.month.split('-')[1]);
                return '$month月';
              }).toList(),
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 月度明细列表
// =============================================================================

class _MonthlyBreakdown extends StatelessWidget {
  const _MonthlyBreakdown({required this.monthlyStats});

  final List<MonthlyAggregate> monthlyStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算最大月度分钟数（用于进度条比例）
    final maxMinutes = monthlyStats
        .map((m) => m.studyMinutes + m.fitnessMinutes)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 99999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('月度明细', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...monthlyStats.map(
          (month) => _MonthlyBreakdownItem(
            month: month,
            maxMinutes: maxMinutes,
          ),
        ),
      ],
    );
  }
}

/// 单月明细项
class _MonthlyBreakdownItem extends StatelessWidget {
  const _MonthlyBreakdownItem({
    required this.month,
    required this.maxMinutes,
  });

  final MonthlyAggregate month;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthNum = int.parse(month.month.split('-')[1]);
    final label = '$monthNum月';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // ── 月份标签 ──
              SizedBox(
                width: 48,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── 学习+健身迷你条 ──
              Expanded(
                child: _MonthlyMiniBar(
                  studyMinutes: month.studyMinutes,
                  fitnessMinutes: month.fitnessMinutes,
                  maxMinutes: maxMinutes,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── 活跃天数 ──
              SizedBox(
                width: 48,
                child: Text(
                  '${month.activeDays}天',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── 经验值 ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${formatExp(month.expGained)}',
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
  }
}

/// 月度迷你进度条：学习（蓝）+ 健身（绿）
class _MonthlyMiniBar extends StatelessWidget {
  const _MonthlyMiniBar({
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
                      flex: studyMinutes.clamp(1, 99999),
                      child: Container(color: AppColors.study),
                    ),
                    Expanded(
                      flex: fitnessMinutes.clamp(1, 99999),
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
