import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/services/statistics_service.dart';
import '../../../shared/providers/service_providers.dart';
import '../widgets/stats_chart.dart';

// =============================================================================
// Providers
// =============================================================================

/// 最近 7 天每日统计 Provider
final weeklyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final statsService = ref.watch(statisticsServiceProvider);
  return statsService.getWeeklyStats();
});

// =============================================================================
// WeeklyStatsPage
// =============================================================================

/// 周统计页面
///
/// 展示最近 7 天的成长趋势：
/// - 折线图（学习/健身/经验）
/// - 汇总卡片（总学习、总健身、总经验）
class WeeklyStatsPage extends ConsumerWidget {
  const WeeklyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyStatsProvider);

    return weeklyStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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

class _WeeklyStatsContent extends StatelessWidget {
  const _WeeklyStatsContent({required this.stats});

  final List<DailyStats> stats;

  @override
  Widget build(BuildContext context) {
    // 计算汇总
    final totalStudy = stats.fold<int>(0, (sum, d) => sum + d.studyMinutes);
    final totalFitness = stats.fold<int>(0, (sum, d) => sum + d.fitnessMinutes);
    final totalExp = stats.fold<int>(0, (sum, d) => sum + d.expGained);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        // ── 时间范围标题 ──
        _WeekRangeHeader(),
        const SizedBox(height: AppTheme.spaceLg),

        // ── 汇总卡片 ──
        _SummaryCards(
          totalStudy: totalStudy,
          totalFitness: totalFitness,
          totalExp: totalExp,
        ),
        const SizedBox(height: AppTheme.spaceLg),

        // ── 趋势折线图 ──
        StatsChart(
          data: stats,
          showStudy: true,
          showFitness: true,
          showExp: true,
          height: 220,
        ),
        const SizedBox(height: AppTheme.spaceLg),

        // ── 每日明细 ──
        _DailyBreakdown(stats: stats),
      ],
    );
  }
}

// =============================================================================
// 时间范围标题
// =============================================================================

class _WeekRangeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '周统计',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Text(
          '${start.month}/${start.day} — ${now.month}/${now.day} · 最近 7 天',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
          child: _SummaryCard(
            icon: Icons.menu_book_rounded,
            label: '总学习',
            value: _formatHours(totalStudy),
            color: GrowthColors.studyPrimary,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center_rounded,
            label: '总健身',
            value: _formatHours(totalFitness),
            color: GrowthColors.fitnessPrimary,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.star_rounded,
            label: '总经验',
            value: '$totalExp',
            color: GrowthColors.expFill,
          ),
        ),
      ],
    );
  }

  /// 将分钟格式化为小时（保留一位小数）
  static String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSm,
          vertical: AppTheme.spaceMd,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('每日明细', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spaceSm),
        // 倒序显示（最近的在前）
        ...stats.reversed.map((day) {
          final weekday = weekdays[day.date.weekday - 1];
          final dateStr = '${day.date.month}/${day.date.day}';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                  vertical: AppTheme.spaceSm,
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
                    const SizedBox(width: AppTheme.spaceSm),

                    // 数据条
                    Expanded(
                      child: _MiniBar(
                        studyMinutes: day.studyMinutes,
                        fitnessMinutes: day.fitnessMinutes,
                        maxMinutes: _maxDayMinutes,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),

                    // 经验值
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${day.expGained}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: GrowthColors.expFill,
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
      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
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
                      child: Container(color: GrowthColors.studyPrimary),
                    ),
                    Expanded(
                      flex: fitnessMinutes.clamp(1, 9999),
                      child: Container(color: GrowthColors.fitnessPrimary),
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
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppTheme.spaceMd),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spaceMd),
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
