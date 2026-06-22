import 'package:flutter/material.dart';

import '../../../app/design/app_theme_colors.dart';

/// Growth OS 图表 Tooltip 统一样式
///
/// 提供统一的 Tooltip 配置方法，确保所有图表的 Tooltip 风格一致。
/// 颜色使用现有 colors.surfaceVariant，与学习图表保持一致。
///
/// 使用方式：
/// ```dart
/// touchTooltipData: LineTouchTooltipData(
///   getTooltipColor: (_) => ChartTooltipTheme.backgroundColor(colors),
///   tooltipBorderRadius: ChartTooltipTheme.borderRadius,
///   tooltipPadding: ChartTooltipTheme.padding,
///   fitInsideHorizontally: true,
///   fitInsideVertically: true,
///   // ...
/// )
/// ```
class ChartTooltipTheme {
  ChartTooltipTheme._();

  /// Tooltip 背景色
  ///
  /// 使用 colors.surfaceVariant（#F2F5F0），与学习图表一致。
  static Color backgroundColor(AppThemeColors colors) =>
      colors.surfaceVariant;

  /// Tooltip 圆角
  static BorderRadius borderRadius = BorderRadius.circular(8);

  /// Tooltip 内边距
  static EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  /// 标题文字样式（日期/标签）
  static TextStyle titleStyle(AppThemeColors colors) => TextStyle(
    color: colors.textOnAccent.withValues(alpha: 0.70),
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  /// 数值文字样式（主要数值）
  static TextStyle valueStyle(AppThemeColors colors) => TextStyle(
    color: colors.textOnAccent,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  /// 辅助文字样式（次要信息）
  static TextStyle captionStyle(AppThemeColors colors) => TextStyle(
    color: colors.textOnAccent.withValues(alpha: 0.70),
    fontSize: 11,
  );
}
