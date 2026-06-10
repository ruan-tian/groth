import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 日记模块颜色体系
///
/// 奶油白 + 低饱和浅粉 + 浅棕灰文字
/// 温柔、治愈、轻手绘风格
class JournalColors {
  JournalColors._();

  // ── 页面背景 ──
  static const bg = Color(0xFFFFF8F6);

  // ── 卡片白 ──
  static const card = Color(0xFFFFFFFF);

  // ── 极浅粉背景 ──
  static const pinkBg = Color(0xFFFFF1F5);

  // ── 浅粉边框 ──
  static const pinkBorder = Color(0xFFF7D6E0);

  // ── 主粉色 ──
  static const pinkMain = Color(0xFFF56F9C);

  // ── 柔粉色 ──
  static const pinkSoft = Color(0xFFF8A9C2);

  // ── 深文字（统一使用 AppColors）──
  static const textDark = AppColors.textPrimary;

  // ── 次文字（统一使用 AppColors）──
  static const textSecondary = AppColors.textSecondary;

  // ── 弱文字（统一使用 AppColors）──
  static const textMuted = AppColors.textTertiary;

  // ── 阴影色 ──
  static Color get shadow => pinkMain.withValues(alpha: 0.08);

  // ── 柔粉渐变（Hero 卡片）──
  static final heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8A9C2), Color(0xFFF56F9C)],
    stops: [0.0, 1.0],
  );

  // ── 极浅粉渐变（陪伴卡片）──
  static final companionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF1F5), Color(0xFFFFF8FA)],
  );

  // ── 热力图色阶 ──
  static const heat0 = Color(0xFFFFF3F6);
  static const heat1 = Color(0xFFFADDE7);
  static const heat2 = Color(0xFFF6BFD1);
  static const heat3 = Color(0xFFEF8FB2);
  static const heat4 = Color(0xFFF45F91);

  static const heatColors = [heat0, heat1, heat2, heat3, heat4];
}
