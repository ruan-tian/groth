import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

import '../../../core/utils/chart_scale_utils.dart';

/// 时长类柱状图（自适应分钟/小时）
///
/// 自动根据数据量级切换分钟和小时显示。
class DurationBarChart extends StatelessWidget {
  const DurationBarChart({
    super.key,
    required this.valuesInMinutes,
    required this.labels,
    this.barColor,
    this.height = 220,
  });

  final List<num> valuesInMinutes;
  final List<String> labels;
  final Color? barColor;
  final double height;

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

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: scale.maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: scale.interval,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: colors.divider, strokeWidth: 0.8),
              ),
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
                      if (value < 0 || value > scale.maxY) {
                        return const SizedBox.shrink();
                      }
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
              barGroups: List.generate(valuesInMinutes.length, (index) {
                final y = scale.convertMinutes(valuesInMinutes[index]);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: y,
                      width: 12,
                      borderRadius: BorderRadius.circular(999),
                      color: barColor ?? colors.primary,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: scale.maxY,
                        color: colors.softPurple,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
