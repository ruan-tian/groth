import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/chart_scale_utils.dart';

/// 时长类折线图（自适应分钟/小时）
///
/// 自动根据数据量级切换分钟和小时显示。
class DurationLineChart extends StatelessWidget {
  const DurationLineChart({
    super.key,
    required this.valuesInMinutes,
    required this.labels,
    this.lineColor,
    this.height = 220,
  });

  final List<num> valuesInMinutes;
  final List<String> labels;
  final Color? lineColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (valuesInMinutes.isEmpty ||
        valuesInMinutes.every((value) => value <= 0)) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    final scale = buildDurationChartScale(valuesInMinutes);

    return ClipRect(
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
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFE5E7EB),
                strokeWidth: 0.8,
              ),
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
                    return Text(
                      scale.formatAxisLabel(value),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
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
                barWidth: 3,
                color: lineColor ?? const Color(0xFF6C63FF),
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: (lineColor ?? const Color(0xFF6C63FF))
                      .withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
