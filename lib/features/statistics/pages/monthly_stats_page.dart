import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/chart_scale_utils.dart';
import '../../../shared/providers/service_providers.dart';

// =============================================================================
// Providers
// =============================================================================

/// 最近 12 个月的月度统计数据。
final yearlyStatsProvider = FutureProvider<List<MonthlyStats>>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  return service.getYearlyStats();
});

// =============================================================================
// MonthlyStatsPage
// =============================================================================

/// 月度统计页面
///
/// 展示最近 12 个月的学习/健身趋势柱状图，以及汇总卡片。
/// 用户可通过月份选择器查看特定月份的详情。
class MonthlyStatsPage extends ConsumerWidget {
  const MonthlyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearlyAsync = ref.watch(yearlyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('月度统计'),
        centerTitle: true,
      ),
      body: yearlyAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: GrowthColors.error),
              const SizedBox(height: AppTheme.spaceMd),
              Text('加载失败: $e'),
              const SizedBox(height: AppTheme.spaceMd),
              FilledButton(
                onPressed: () => ref.invalidate(yearlyStatsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MonthlyStats> stats) {
    if (stats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: AppTheme.spaceMd),
            Text('暂无统计数据'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      children: [
        // ── 汇总卡片 ──
        _SummaryCards(stats: stats),
        const SizedBox(height: AppTheme.spaceLg),

        // ── 分组柱状图 ──
        _GroupedBarChartCard(stats: stats),
        const SizedBox(height: AppTheme.spaceLg),

        // ── 月份选择器 ──
        _MonthSelector(stats: stats),
        const SizedBox(height: AppTheme.spaceXl),
      ],
    );
  }
}

// =============================================================================
// 汇总卡片
// =============================================================================

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});

  final List<MonthlyStats> stats;

  @override
  Widget build(BuildContext context) {
    final totalStudy = stats.fold<int>(0, (sum, s) => sum + s.studyMinutes);
    final totalFitness = stats.fold<int>(0, (sum, s) => sum + s.fitnessMinutes);
    final totalExp = stats.fold<int>(0, (sum, s) => sum + s.expGained);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.menu_book,
            label: '总学习',
            value: _formatHours(totalStudy),
            color: GrowthColors.studyPrimary,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center,
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
    if (minutes < 60) return '${minutes}min';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: AppTheme.spaceSm),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 分组柱状图卡片
// =============================================================================

class _GroupedBarChartCard extends StatelessWidget {
  const _GroupedBarChartCard({required this.stats});

  final List<MonthlyStats> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 计算 Y 轴最大值（取学习/健身中较大值）
    final allMinutes = <num>[];
    for (final s in stats) {
      allMinutes.add(s.studyMinutes);
      allMinutes.add(s.fitnessMinutes);
    }
    final scale = buildDurationChartScale(allMinutes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 标题 ──
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Text('月度趋势', style: theme.textTheme.titleMedium),
                const Spacer(),
                // ── 单位提示 ──
                Text(
                  scale.useHours ? '单位：小时' : '单位：分钟',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                // ── 图例 ──
                _LegendDot(color: GrowthColors.studyPrimary, label: '学习'),
                const SizedBox(width: AppTheme.spaceMd),
                _LegendDot(color: GrowthColors.fitnessPrimary, label: '健身'),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // ── 柱状图 ──
            ClipRect(
              child: SizedBox(
                height: 220,
                child: BarChart(
                  _buildChartData(colorScheme, scale),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildChartData(ColorScheme colorScheme, DurationChartScale scale) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: scale.maxY,

      // ── 触摸交互 ──
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) =>
              colorScheme.inverseSurface.withValues(alpha: 0.85),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = stats[group.x].month;
            final label = rodIndex == 0 ? '学习' : '健身';
            final value = rod.toY;
            final displayValue = scale.useHours
                ? '${value.toStringAsFixed(1)}h'
                : '${value.toInt()}min';
            return BarTooltipItem(
              '$month\n$label $displayValue',
              TextStyle(
                color: colorScheme.onInverseSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ),

      // ── 标题 ──
      titlesData: FlTitlesData(
        // X 轴：月份
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= stats.length) {
                return const SizedBox.shrink();
              }
              // 只显示月份部分 (MM)
              final monthStr = stats[index].month;
              final parts = monthStr.split('-');
              final mm = parts.length > 1 ? parts[1] : monthStr;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  mm,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
        // Y 轴：时长
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: scale.interval,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > scale.maxY) {
                return const SizedBox.shrink();
              }
              return Text(
                scale.formatAxisLabel(value),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),

      // ── 网格线 ──
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: scale.interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
      ),

      // ── 边框 ──
      borderData: FlBorderData(show: false),

      // ── 柱状数据 ──
      barGroups: List.generate(stats.length, (i) {
        return BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            // 学习（蓝色）
            BarChartRodData(
              toY: scale.convertMinutes(stats[i].studyMinutes),
              color: GrowthColors.studyPrimary,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXs),
              ),
            ),
            // 健身（橙色）
            BarChartRodData(
              toY: scale.convertMinutes(stats[i].fitnessMinutes),
              color: GrowthColors.fitnessPrimary,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXs),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// 图例圆点
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

// =============================================================================
// 月份选择器
// =============================================================================

class _MonthSelector extends StatefulWidget {
  const _MonthSelector({required this.stats});

  final List<MonthlyStats> stats;

  @override
  State<_MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<_MonthSelector> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // 默认选中最后一个月（当前月）
    _selectedIndex = widget.stats.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.stats[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 标题 + 左右切换 ──
        Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Text('月份详情', style: theme.textTheme.titleMedium),
            const Spacer(),
            IconButton(
              onPressed: _selectedIndex > 0
                  ? () => setState(() => _selectedIndex--)
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: '上一月',
            ),
            Text(
              selected.month,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: _selectedIndex < widget.stats.length - 1
                  ? () => setState(() => _selectedIndex++)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: '下一月',
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMd),

        // ── 月份详情卡片 ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.menu_book,
                  label: '学习时长',
                  value: _formatMinutes(selected.studyMinutes),
                  color: GrowthColors.studyPrimary,
                ),
                const Divider(height: AppTheme.spaceLg),
                _DetailRow(
                  icon: Icons.fitness_center,
                  label: '健身时长',
                  value: _formatMinutes(selected.fitnessMinutes),
                  color: GrowthColors.fitnessPrimary,
                ),
                const Divider(height: AppTheme.spaceLg),
                _DetailRow(
                  icon: Icons.star_rounded,
                  label: '获得经验',
                  value: '${selected.expGained} EXP',
                  color: GrowthColors.expFill,
                ),
                const Divider(height: AppTheme.spaceLg),
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: '总活动时长',
                  value: _formatMinutes(
                    selected.studyMinutes + selected.fitnessMinutes,
                  ),
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 将分钟格式化为 "Xmin" 或 "Xh Ym"
  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

/// 详情行
class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spaceSm),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
