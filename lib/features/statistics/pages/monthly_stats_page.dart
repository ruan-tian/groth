import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/stats_formatters.dart';
import '../../../shared/providers/service_providers.dart';
import '../widgets/stats_skeleton.dart';
import '../../../shared/widgets/common/stats_summary_card.dart';
import '../../../shared/widgets/common/duration_line_chart.dart';
import '../widgets/heatmap_calendar.dart';

// =============================================================================
// Providers
// =============================================================================

/// 月份偏移量 Provider（0 = 当月，1 = 上月，…）
final monthOffsetProvider = StateProvider<int>((ref) => 0);

/// 目标月份的每日统计 Provider
final monthlyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  final offset = ref.watch(monthOffsetProvider);
  final now = DateTime.now();
  final targetMonth = DateTime(now.year, now.month - offset, 1);
  final start = targetMonth;
  final end = DateTime(targetMonth.year, targetMonth.month + 1, 0);
  return statsService.getDailyStatsRange(start, end);
});

// =============================================================================
// MonthlyStatsPage
// =============================================================================

/// 月统计页面
///
/// 展示指定月份的成长趋势：
/// - 月份导航（前进/后退 + 回到本月）
/// - 汇总卡片（总学习、总健身、总经验）
/// - 折线图（学习+健身时长趋势）
/// - 热力图日历（Phase 5 占位）
/// - 每日明细列表
class MonthlyStatsPage extends ConsumerWidget {
  const MonthlyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStats = ref.watch(monthlyStatsProvider);

    return monthlyStats.when(
      loading: () => const StatsSkeleton(),
      error: (error, stack) => _ErrorView(
        message: '加载失败: $error',
        onRetry: () => ref.invalidate(monthlyStatsProvider),
      ),
      data: (stats) => _MonthlyContent(stats: stats),
    );
  }
}

// =============================================================================
// Content
// =============================================================================

class _MonthlyContent extends ConsumerWidget {
  const _MonthlyContent({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 计算汇总
    final totalStudy = stats.fold<int>(0, (sum, d) => sum + d.studyMinutes);
    final totalFitness = stats.fold<int>(0, (sum, d) => sum + d.fitnessMinutes);
    final totalExp = stats.fold<int>(0, (sum, d) => sum + d.expGained);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── 月份导航 ──
        const _MonthNavigator(),
        const SizedBox(height: AppSpacing.lg),

        // ── 汇总卡片 ──
        _SummaryCards(
          totalStudy: totalStudy,
          totalFitness: totalFitness,
          totalExp: totalExp,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 趋势折线图 ──
        _TrendChart(stats: stats),
        const SizedBox(height: AppSpacing.lg),

        // ── 热力图日历 ──
        _HeatmapPlaceholder(stats: stats),
        const SizedBox(height: AppSpacing.lg),

        // ── 每日明细 ──
        _DailyBreakdown(stats: stats),
      ],
    );
  }
}

// =============================================================================
// 月份导航
// =============================================================================

/// 月份导航组件
///
/// 显示格式：`←  2026年6月  →` + `[本月]` 按钮
class _MonthNavigator extends ConsumerWidget {
  const _MonthNavigator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offset = ref.watch(monthOffsetProvider);
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month - offset, 1);

    return Column(
      children: [
        // ── 月份标题 + 左右箭头 ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 左箭头
            IconButton(
              onPressed: () {
                ref.read(monthOffsetProvider.notifier).state++;
              },
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: '上个月',
            ),
            const SizedBox(width: AppSpacing.sm),
            // 月份文字
            Text(
              formatMonth(targetMonth),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 右箭头（禁用当已是当月）
            IconButton(
              onPressed: offset == 0
                  ? null
                  : () {
                      ref.read(monthOffsetProvider.notifier).state--;
                    },
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: '下个月',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── 回到本月按钮（仅在非当月时显示） ──
        if (offset != 0)
          TextButton.icon(
            onPressed: () {
              ref.read(monthOffsetProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.today_rounded, size: 16),
            label: const Text('本月'),
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
            color: context.growthColors.study,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatsSummaryCard(
            icon: Icons.fitness_center_rounded,
            label: '总健身',
            value: formatMinutesShort(totalFitness),
            color: context.growthColors.fitness,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatsSummaryCard(
            icon: Icons.star_rounded,
            label: '总经验',
            value: formatExp(totalExp),
            color: context.growthColors.primary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 趋势折线图
// =============================================================================

/// 学习+健身时长趋势折线图
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 合并学习 + 健身分钟数
    final values = stats
        .map<num>((d) => d.studyMinutes + d.fitnessMinutes)
        .toList();

    // 标签：每隔 N 天显示一个日期（避免重叠）
    final labels = _buildLabels(stats);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '每日活动趋势',
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
            DurationLineChart(
              valuesInMinutes: values,
              labels: labels,
              lineColor: context.growthColors.primary,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }

  /// 生成底部标签（每隔几天显示一次，避免标签重叠）
  List<String> _buildLabels(List<DailyStats> stats) {
    if (stats.isEmpty) return [];

    // 根据数据量决定间隔
    final int interval;
    if (stats.length <= 10) {
      interval = 1;
    } else if (stats.length <= 20) {
      interval = 3;
    } else {
      interval = 5;
    }

    return List.generate(stats.length, (i) {
      if (i % interval == 0) {
        return '${stats[i].date.month}/${stats[i].date.day}';
      }
      return '';
    });
  }
}

// =============================================================================
// 热力图日历（Phase 5 占位）
// =============================================================================

class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build heatmap data from daily stats
    final heatmapData = <DateTime, int>{};
    for (final stat in stats) {
      if (stat.isActiveDay) {
        heatmapData[stat.date] = stat.activeModules;
      }
    }

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
                  color: context.growthColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '活跃热力图',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (heatmapData.isEmpty)
              Container(
                height: 80,
                alignment: Alignment.center,
                child: Text(
                  '暂无数据',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              HeatmapCalendar(
                data: heatmapData,
                monthsToShow: 1,
                showLegend: true,
              ),
          ],
        ),
      ),
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

    // 过滤掉无数据的天（全为 0），按日期倒序
    final activeStats =
        stats
            .where((d) => d.studyMinutes + d.fitnessMinutes + d.expGained > 0)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('每日明细', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (activeStats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                '本月暂无活动记录',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...activeStats.map(
            (day) => _DailyBreakdownItem(day: day, maxMinutes: _maxDayMinutes),
          ),
      ],
    );
  }

  /// 所有天中单日最大总分钟数（用于进度条比例）
  int get _maxDayMinutes {
    if (stats.isEmpty) return 1;
    return stats
        .map((d) => d.studyMinutes + d.fitnessMinutes)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 9999);
  }
}

/// 单日明细项
class _DailyBreakdownItem extends StatelessWidget {
  const _DailyBreakdownItem({required this.day, required this.maxMinutes});

  final DailyStats day;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = formatDateChinese(day.date);
    final weekday = formatWeekday(day.date);

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
              // ── 日期 ──
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

              // ── 数据条 ──
              Expanded(
                child: _MiniBar(
                  studyMinutes: day.studyMinutes,
                  fitnessMinutes: day.fitnessMinutes,
                  maxMinutes: maxMinutes,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── 经验值 ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${formatExp(day.expGained)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: context.growthColors.primary,
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
                      child: Container(color: context.growthColors.study),
                    ),
                    Expanded(
                      flex: fitnessMinutes.clamp(1, 9999),
                      child: Container(color: context.growthColors.fitness),
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
    final colors = context.growthColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
