import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/design/app_theme_colors.dart';

/// Growth OS 图表目标参考线工具
///
/// 提供统一的目标虚线创建方法，用于在图表中显示用户设定的目标值。
/// 风格：虚线 [6, 4]，颜色使用 colors.textTertiary，与网格线协调。
///
/// 使用方式：
/// ```dart
/// extraLinesData: ExtraLinesData(
///   horizontalLines: [
///     ChartGoalLine.create(
///       goalValue: 60,
///       colors: colors,
///       label: '目标',
///     ),
///   ],
/// )
/// ```
class ChartGoalLine {
  ChartGoalLine._();

  /// 创建目标参考线（虚线水平线）
  ///
  /// - [goalValue] 目标值（Y轴坐标）
  /// - [colors] 主题色
  /// - [label] 可选标签文字（如 '目标' 或 '60min'）
  /// - [labelAlignment] 标签位置，默认右上角
  static HorizontalLine create({
    required double goalValue,
    required AppThemeColors colors,
    String? label,
    Alignment labelAlignment = Alignment.topRight,
  }) {
    return HorizontalLine(
      y: goalValue,
      color: colors.textTertiary.withValues(alpha: 0.5),
      strokeWidth: 1.5,
      dashArray: const [6, 4],
      label: label != null
          ? HorizontalLineLabel(
              show: true,
              alignment: labelAlignment,
              labelResolver: (_) => label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            )
          : null,
    );
  }

  /// 创建带色带的目标区间（最佳训练负荷色带）
  ///
  /// 用于 Garmin 风格的"最佳区间"可视化。
  /// - [minValue] 区间下限
  /// - [maxValue] 区间上限
  /// - [color] 区间颜色
  static List<HorizontalLine> createRange({
    required double minValue,
    required double maxValue,
    required Color color,
    String? label,
  }) {
    return [
      HorizontalLine(
        y: minValue,
        color: color.withValues(alpha: 0.3),
        strokeWidth: 1,
        dashArray: const [4, 4],
      ),
      HorizontalLine(
        y: maxValue,
        color: color.withValues(alpha: 0.3),
        strokeWidth: 1,
        dashArray: const [4, 4],
        label: label != null
            ? HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              )
            : null,
      ),
    ];
  }
}
