import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 日记模块颜色体系
///
/// 奶油白 + 低饱和浅粉 + 浅棕灰文字
/// 温柔、治愈、轻手绘风格
///
/// Legacy static fields are kept for backward compatibility.
/// New code should use the `*Of(BuildContext context)` methods which
/// delegate to `context.growthColors` for theme-awareness.
class JournalColors {
  JournalColors._();

  // ── Theme-aware accessors (preferred for new code) ──

  static Color bgOf(BuildContext context) => context.growthColors.paper;
  static Color cardOf(BuildContext context) => context.growthColors.card;
  static Color pinkBgOf(BuildContext context) => context.growthColors.softPink;
  static Color pinkMainOf(BuildContext context) => context.growthColors.journal;
  static Color textDarkOf(BuildContext context) =>
      context.growthColors.textPrimary;
  static Color textSecondaryOf(BuildContext context) =>
      context.growthColors.textSecondary;
  static Color textMutedOf(BuildContext context) =>
      context.growthColors.textTertiary;
  static Color shadowOf(BuildContext context) =>
      context.growthColors.journal.withValues(alpha: 0.08);
  static Color borderOf(BuildContext context) => context.growthColors.border;
  static Color dividerOf(BuildContext context) => context.growthColors.divider;

  // ── Legacy static fields ──

  static const bg = AppColors.paper;

  static const card = Color(0xFFFFFFFF);

  static const pinkBg = AppColors.softPink;

  static const pinkBorder = Color(0xFFF0D4DE);

  static const pinkMain = AppColors.journal;

  static const pinkSoft = Color(0xFFE88EAD);

  static const textDark = AppColors.textPrimary;

  static const textSecondary = AppColors.textSecondary;

  static const textMuted = AppColors.textTertiary;

  static Color get shadow => pinkMain.withValues(alpha: 0.08);

  static final heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE88EAD), AppColors.journal],
    stops: [0.0, 1.0],
  );

  static final companionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.softPink, Color(0xFFFFF8FA)],
  );

  static const heat0 = Color(0xFFFFF3F6);
  static const heat1 = Color(0xFFF6D6E1);
  static const heat2 = Color(0xFFEFB3C8);
  static const heat3 = Color(0xFFD9789F);
  static const heat4 = AppColors.journal;

  static const heatColors = [heat0, heat1, heat2, heat3, heat4];
}
