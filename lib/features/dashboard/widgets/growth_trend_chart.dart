import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/services/statistics_service.dart';
import '../../../shared/widgets/common/growth_card.dart';

class GrowthTrendChart extends StatelessWidget {
  const GrowthTrendChart({super.key, required this.weeklyStats});

  final List<DailyStats> weeklyStats;

  @override
  Widget build(BuildContext context) {
    final maxExp = weeklyStats.isEmpty
        ? 0
        : weeklyStats.map((s) => s.expGained).reduce((a, b) => a > b ? a : b);
    final yMax = (maxExp * 1.22).clamp(10.0, double.infinity);

    return GrowthCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('成长趋势', style: AppTextStyles.cardTitle),
              ),
              const Text('最近 7 天', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 18),
          ClipRect(
            child: SizedBox(
              height: 184,
              child: weeklyStats.isEmpty
                  ? Center(
                      child: Text(
                        '暂无数据',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : RepaintBoundary(
                      child: LineChart(_buildChartData(yMax)),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(double yMax) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yMax / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.border.withValues(alpha: 0.8),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= weeklyStats.length) {
                return const SizedBox.shrink();
              }
              final date = weeklyStats[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: yMax / 4,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.ink.withValues(alpha: 0.9),
          getTooltipItems: (spots) => spots.map((spot) {
            final date = weeklyStats[spot.x.toInt()].date;
            return LineTooltipItem(
              '${date.month}/${date.day}\n${spot.y.toInt()} EXP',
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ),
      minX: 0,
      maxX: (weeklyStats.length - 1).toDouble().clamp(0.0, double.infinity),
      minY: 0,
      maxY: yMax,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            weeklyStats.length,
            (i) => FlSpot(i.toDouble(), weeklyStats[i].expGained.toDouble()),
          ),
          isCurved: true,
          preventCurveOverShooting: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.accent,
              strokeWidth: 2,
              strokeColor: AppColors.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.22),
                AppColors.primary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
