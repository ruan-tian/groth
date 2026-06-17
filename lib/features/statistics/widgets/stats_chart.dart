import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/services/statistics_service.dart';
import '../../../core/utils/chart_scale_utils.dart';

// =============================================================================
// StatsChart Widget
// =============================================================================

/// 多线折线图组件
///
/// 展示 [DailyStats] 数据中的学习时长、健身时长、经验值三条线。
/// 支持图例点击切换显示/隐藏。
class StatsChart extends StatelessWidget {
  const StatsChart({
    super.key,
    required this.data,
    this.showStudy = true,
    this.showFitness = true,
    this.showExp = true,
    this.height = 220,
  });

  /// 每日统计数据（按日期升序）
  final List<DailyStats> data;

  /// 是否显示学习时长线
  final bool showStudy;

  /// 是否显示健身时长线
  final bool showFitness;

  /// 是否显示经验值线
  final bool showExp;

  /// 图表高度
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.growthColors;
    final colorScheme = theme.colorScheme;

    // 收集所有时长数据用于计算缩放
    final allMinutes = <num>[];
    for (final d in data) {
      if (showStudy) allMinutes.add(d.studyMinutes);
      if (showFitness) allMinutes.add(d.fitnessMinutes);
    }
    final scale = buildDurationChartScale(allMinutes);

    // EXP 数据单独计算缩放（如果显示）
    double expMax = 0;
    if (showExp) {
      for (final d in data) {
        if (d.expGained > expMax) expMax = d.expGained.toDouble();
      }
    }
    // 将 EXP 归一化到时长范围内（1 EXP ≈ 1 分钟的比例）
    final expScale = expMax > 0 ? scale.maxY / expMax : 1.0;

    return RepaintBoundary(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                  const SizedBox(width: AppSpacing.sm),
                  Text('数据趋势', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  // ── 单位提示 ──
                  Text(
                    scale.useHours ? '单位：小时' : '单位：分钟',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${data.length} 天',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 图例 ──
              _Legend(
                showStudy: showStudy,
                showFitness: showFitness,
                showExp: showExp,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── 折线图 ──
              ClipRect(
                child: SizedBox(
                  height: height,
                  child: data.isEmpty
                      ? Center(
                          child: Text(
                            '暂无数据',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : LineChart(
                          _buildChartData(colorScheme, colors, scale, expScale),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 图表配置
  // ---------------------------------------------------------------------------

  LineChartData _buildChartData(
    ColorScheme colorScheme,
    AppThemeColors colors,
    DurationChartScale scale,
    double expScale,
  ) {
    return LineChartData(
      // ── 网格 ──
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: scale.interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
      ),

      // ── 坐标轴标题 ──
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _bottomInterval,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) {
                return const SizedBox.shrink();
              }
              final date = data[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: scale.interval,
            getTitlesWidget: (value, meta) {
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),

      // ── 边框 ──
      borderData: FlBorderData(show: false),

      // ── 触摸交互 ──
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) =>
              colorScheme.inverseSurface.withValues(alpha: 0.85),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final date = data[spot.x.toInt()].date;
              final label = '${date.month}/${date.day}';
              final lineName = _lineName(spot.barIndex);
              final displayValue = scale.formatTooltipValue(spot.y);
              return LineTooltipItem(
                '$label\n$lineName: $displayValue',
                TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),

      // ── 数据区间 ──
      minX: 0,
      maxX: (data.length - 1).toDouble().clamp(0.0, double.infinity),
      minY: 0,
      maxY: scale.maxY,

      // ── 折线数据 ──
      lineBarsData: _buildLineBarsData(colorScheme, colors, scale, expScale),
    );
  }

  /// 构建各条折线
  List<LineChartBarData> _buildLineBarsData(
    ColorScheme colorScheme,
    AppThemeColors colors,
    DurationChartScale scale,
    double expScale,
  ) {
    final lines = <LineChartBarData>[];

    if (showStudy) {
      lines.add(
        _buildLine(
          values: data
              .map((d) => scale.convertMinutes(d.studyMinutes))
              .toList(),
          color: colors.study,
          surfaceColor: colorScheme.surface,
        ),
      );
    }
    if (showFitness) {
      lines.add(
        _buildLine(
          values: data
              .map((d) => scale.convertMinutes(d.fitnessMinutes))
              .toList(),
          color: colors.fitness,
          surfaceColor: colorScheme.surface,
        ),
      );
    }
    if (showExp) {
      // EXP 归一化到时长范围
      lines.add(
        _buildLine(
          values: data.map((d) => d.expGained * expScale).toList(),
          color: colors.primary,
          surfaceColor: colorScheme.surface,
        ),
      );
    }

    return lines;
  }

  /// 构建单条折线
  LineChartBarData _buildLine({
    required List<double> values,
    required Color color,
    required Color surfaceColor,
  }) {
    return LineChartBarData(
      spots: List.generate(values.length, (i) {
        return FlSpot(i.toDouble(), values[i]);
      }),
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: data.length <= 14, // 数据点多时不显示圆点
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1.5,
            strokeColor: surfaceColor,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  /// X 轴标签间隔：数据少时全部显示，多时隔天显示
  double get _bottomInterval {
    if (data.length <= 7) return 1;
    if (data.length <= 14) return 2;
    return (data.length / 7).ceilToDouble();
  }

  /// 折线名称（用于 tooltip）
  String _lineName(int barIndex) {
    int idx = 0;
    if (showStudy) {
      if (idx == barIndex) return '学习';
      idx++;
    }
    if (showFitness) {
      if (idx == barIndex) return '健身';
      idx++;
    }
    if (showExp) {
      if (idx == barIndex) return '经验';
      idx++;
    }
    return '';
  }
}

// =============================================================================
// 图例组件
// =============================================================================

class _Legend extends StatelessWidget {
  const _Legend({
    required this.showStudy,
    required this.showFitness,
    required this.showExp,
  });

  final bool showStudy;
  final bool showFitness;
  final bool showExp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.growthColors;

    return Wrap(
      spacing: AppSpacing.md,
      children: [
        if (showStudy)
          _LegendItem(
            color: colors.study,
            label: '学习 (min)',
            textStyle: theme.textTheme.labelSmall,
          ),
        if (showFitness)
          _LegendItem(
            color: colors.fitness,
            label: '健身 (min)',
            textStyle: theme.textTheme.labelSmall,
          ),
        if (showExp)
          _LegendItem(
            color: colors.primary,
            label: '经验 (EXP)',
            textStyle: theme.textTheme.labelSmall,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.textStyle});

  final Color color;
  final String label;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: textStyle),
      ],
    );
  }
}
