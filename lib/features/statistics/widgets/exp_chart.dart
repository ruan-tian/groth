import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/utils/stats_formatters.dart';

/// 经验值柱状图组件
///
/// 展示每日/每周/每月经验值分布，支持触摸提示和自动缩放。
/// 数据点 ≤7 时在柱顶显示数值，>7 时隐藏避免重叠。
class ExpChart extends StatelessWidget {
  const ExpChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 200,
  });

  /// 每个数据点的经验值
  final List<int> values;

  /// X 轴标签（日期或月份名称）
  final List<String> labels;

  /// 图表高度
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ── 空状态 ──
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '暂无数据',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // ── Y 轴自动缩放 ──
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue * 1.2).ceilToDouble().clamp(10.0, double.infinity);
    final interval = maxY <= 50
        ? 10.0
        : maxY <= 200
        ? 50.0
        : 100.0;

    // ── 是否显示柱顶数值标签 ──

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,

              // ── 网格线 ──
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 0.8,
                ),
              ),

              // ── 边框 ──
              borderData: FlBorderData(show: false),

              // ── 坐标轴标题 ──
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
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > maxY) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        formatExp(value.toInt()),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
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
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── 触摸提示 ──
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      colorScheme.inverseSurface.withValues(alpha: 0.85),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x;
                    if (index < 0 || index >= labels.length) {
                      return null;
                    }
                    final label = labels[index];
                    final exp = values[index];
                    return BarTooltipItem(
                      '$label\n经验值: ${formatExp(exp)}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),

              // ── 柱状数据 ──
              barGroups: List.generate(values.length, (index) {
                final y = values[index].toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: y,
                      width: 12,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      color: AppColors.primary,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: AppColors.softPurple,
                      ),
                    ),
                  ],
                );
              }),
            ),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
  }
}
