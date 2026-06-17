import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// Music module color system.
///
/// Colors extracted from watercolor assets for cohesive visual design.
/// Legacy static fields are kept for backward compatibility.
/// New code should use the `*Of(BuildContext context)` methods which
/// delegate to `context.growthColors` for theme-awareness.
class MusicColors {
  MusicColors._();

  // ── Theme-aware accessors (preferred for new code) ──

  static Color primaryOf(BuildContext context) => context.growthColors.primary;
  static Color primaryLightOf(BuildContext context) =>
      context.growthColors.primaryLight;
  static Color cardOf(BuildContext context) => context.growthColors.card;
  static Color textPrimaryOf(BuildContext context) =>
      context.growthColors.textPrimary;
  static Color textSecondaryOf(BuildContext context) =>
      context.growthColors.textSecondary;
  static Color textTertiaryOf(BuildContext context) =>
      context.growthColors.textTertiary;
  static Color borderOf(BuildContext context) => context.growthColors.border;
  static Color shadowOf(BuildContext context) => context.growthColors.shadow;
  static Color dangerOf(BuildContext context) => context.growthColors.danger;
  static Color successOf(BuildContext context) => context.growthColors.success;

  // ── Legacy static fields (from watercolor assets) ──

  static const primary = Color(0xFF9B8FE8);
  static const primaryLight = Color(0xFFB8AEF5);
  static const primaryDark = Color(0xFF7B6FD6);

  static const pink = Color(0xFFFFB8C6);
  static const pinkLight = Color(0xFFFFD4DE);
  static const gold = Color(0xFFFFD97A);
  static const goldLight = Color(0xFFFFE8A8);

  static const cream = Color(0xFFFFFCF6);
  static const creamDark = Color(0xFFF8F4EE);
  static const lavender = Color(0xFFF3EDFF);

  static const ink = Color(0xFF352F4F);
  static const muted = Color(0xFF8B8498);
  static const hint = Color(0xFFB8B3C5);

  static const border = Color(0xFFE8DDF7);
  static const borderLight = Color(0xFFF0EAF8);

  static const shadow = Color(0x2A7155B9);
  static const shadowLight = Color(0x1A7155B9);

  static const favorite = Color(0xFFFF7BA9);
  static const danger = Color(0xFFFF4757);
  static const success = Color(0xFF35C976);

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cream, lavender],
  );

  static const pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEDF5), Color(0xFFFFF7FA)],
  );

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
}
