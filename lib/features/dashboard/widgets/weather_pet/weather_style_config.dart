import 'package:flutter/material.dart';

/// 天气卡片样式配置
class WeatherStyleConfig {
  WeatherStyleConfig._();

  // 卡片尺寸
  static const double cardRadius = 24.0;
  static const double cardPadding = 20.0;
  static const double aspectRatio = 16 / 9;

  // 字体大小
  static const double tempFontSize = 48.0;
  static const double weatherTextFontSize = 16.0;
  static const double rangeFontSize = 13.0;
  static const double cityFontSize = 12.0;
  static const double tipFontSize = 13.0;
  static const double catFontSize = 64.0;

  // 阴影
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowFor(Color accentColor) => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.18),
      blurRadius: 26,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.9),
      blurRadius: 2,
      offset: const Offset(0, -1),
    ),
  ];

  static BoxDecoration get emptyDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(cardRadius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF1EDFF), Color(0xFFDDEAFF)],
    ),
    border: Border.all(color: Colors.white, width: 1.2),
    boxShadow: cardShadow,
  );

  // 气泡装饰
  static List<BubbleConfig> bubbles = [
    BubbleConfig(top: -20, right: -10, size: 100, opacity: 0.1),
    BubbleConfig(top: 40, left: -30, size: 80, opacity: 0.08),
    BubbleConfig(bottom: 20, right: 20, size: 60, opacity: 0.06),
    BubbleConfig(bottom: -10, left: 40, size: 120, opacity: 0.05),
  ];
}

class BubbleConfig {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double opacity;

  const BubbleConfig({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });
}
