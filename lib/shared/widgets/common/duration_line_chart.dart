import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/utils/chart_goal_line.dart';
import '../../../core/utils/chart_scale_utils.dart';

/// 时长类折线图（自适应分钟/小时）
///
/// 自动根据数据量级切换分钟和小时显示。
///
/// 增强功能（可选）：
/// - [goalValue] 目标参考线（虚线）
/// - [goalLabel] 目标线标签
/// - 触摸时显示垂直指示线（Apple Health 风格）
/// - Tooltip 防溢出（fitInside）
class DurationLineChart extends StatelessWidget {
  const DurationLineChart({
    super.key,
    required this.valuesInMinutes,
    required this.labels,
    this.lineColor,
    this.height = 220,
    this.goalValue,
    this.goalLabel,
  });

  final List<num> valuesInMinutes;
  final List<String> labels;
  final Color? lineColor;
  final double height;

  /// 目标值（分钟），显示为虚线参考线
  final num? goalValue;

  /// 目标线标签（如 '目标' 或 '60min'）
  final String? goalLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    if (valuesInMinutes.isEmpty ||
        valuesInMinutes.every((value) => value <= 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
        ),
      );
    }

    final scale = buildDurationChartScale(valuesInMinutes);
    final effectiveColor = lineColor ?? colors.primary;

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: scale.maxY,
              clipData: FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: scale.interval,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: colors.divider, strokeWidth: 0.8),
              ),
              extraLinesData: goalValue != null
                  ? ExtraLinesData(
                      horizontalLines: [
                        ChartGoalLine.create(
                          goalValue: scale.convertMinutes(goalValue!),
                          colors: colors,
                          label: goalLabel,
                        ),
                      ],
                    )
                  : null,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
                          color: colors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(valuesInMinutes.length, (index) {
                    return FlSpot(
                      index.toDouble(),
                      scale.convertMinutes(valuesInMinutes[index]),
                    );
                  }),
                  isCurved: true,
                  preventCurveOverShooting: true,
                  curveSmoothness: 0.3,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  color: effectiveColor,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        effectiveColor.withValues(alpha: 0.15),
                        effectiveColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchSpotThreshold: 15,
                getTouchLineStart: (barData, spotIndex) => 0,
                getTouchLineEnd: (barData, spotIndex) => double.infinity,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: colors.border.withValues(alpha: 0.4),
                        strokeWidth: 1.5,
                        dashArray: const [4, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 6,
                          color: colors.card,
                          strokeColor: effectiveColor,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colors.surfaceVariant,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        scale.formatTooltipValue(spot.y),
                        TextStyle(
                          color: colors.textOnAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
