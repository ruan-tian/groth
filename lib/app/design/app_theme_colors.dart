import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.paper,
    required this.card,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.study,
    required this.fitness,
    required this.diet,
    required this.sleep,
    required this.journal,
    required this.focus,
    required this.success,
    required this.warning,
    required this.danger,
    required this.softBlue,
    required this.softGreen,
    required this.softOrange,
    required this.softPink,
    required this.softPurple,
    required this.softGold,
    required this.textOnAccent,
    required this.shadow,
    this.knowledgeBg = AppColors.knowledgeBg,
    this.knowledgePrimary = AppColors.knowledgePrimary,
    this.weakRed = AppColors.weakRed,
    this.dueOrange = AppColors.dueOrange,
    this.masteredGreen = AppColors.masteredGreen,
  });

  final Color background;
  final Color paper;
  final Color card;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceTint;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color study;
  final Color fitness;
  final Color diet;
  final Color sleep;
  final Color journal;
  final Color focus;
  final Color success;
  final Color warning;
  final Color danger;
  final Color softBlue;
  final Color softGreen;
  final Color softOrange;
  final Color softPink;
  final Color softPurple;
  final Color softGold;
  final Color textOnAccent;
  final Color shadow;

  // Knowledge card system colors
  final Color knowledgeBg;
  final Color knowledgePrimary;
  final Color weakRed;
  final Color dueOrange;
  final Color masteredGreen;

  static const light = AppThemeColors(
    background: AppColors.background,
    paper: AppColors.paper,
    card: AppColors.card,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    surfaceTint: AppColors.surfaceTint,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textHint: AppColors.textHint,
    border: AppColors.border,
    divider: AppColors.divider,
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
    accent: AppColors.accent,
    study: AppColors.study,
    fitness: AppColors.fitness,
    diet: AppColors.diet,
    sleep: AppColors.sleep,
    journal: AppColors.journal,
    focus: AppColors.focus,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    softBlue: AppColors.softBlue,
    softGreen: AppColors.softGreen,
    softOrange: AppColors.softOrange,
    softPink: AppColors.softPink,
    softPurple: AppColors.softPurple,
    softGold: AppColors.softGold,
    textOnAccent: AppColors.textOnAccent,
    shadow: Color(0x14172033),
    knowledgeBg: AppColors.knowledgeBg,
    knowledgePrimary: AppColors.knowledgePrimary,
    weakRed: AppColors.weakRed,
    dueOrange: AppColors.dueOrange,
    masteredGreen: AppColors.masteredGreen,
  );

  static const dark = AppThemeColors(
    background: Color(0xFF0F1117),
    paper: Color(0xFF141821),
    card: Color(0xFF1B202B),
    surface: Color(0xFF1B202B),
    surfaceVariant: Color(0xFF252B36),
    surfaceTint: Color(0xFF1F2530),
    textPrimary: Color(0xFFF4F7FB),
    textSecondary: Color(0xFFC6CEDA),
    textTertiary: Color(0xFF9AA4B3),
    textHint: Color(0xFF747F90),
    border: Color(0xFF313847),
    divider: Color(0xFF2A303D),
    primary: Color(0xFFA7B0FF),
    primaryLight: Color(0xFFC4CBFF),
    primaryDark: Color(0xFF7E8BFF),
    accent: Color(0xFFF6B760),
    study: Color(0xFF9FB6FF),
    fitness: Color(0xFFFFB17A),
    diet: Color(0xFFF2C15F),
    sleep: Color(0xFFC0B5FF),
    journal: Color(0xFFFFA6C6),
    focus: Color(0xFF72D4C9),
    success: Color(0xFF74D99F),
    warning: Color(0xFFF5CA69),
    danger: Color(0xFFFF8C86),
    softBlue: Color(0xFF202A45),
    softGreen: Color(0xFF19362F),
    softOrange: Color(0xFF3A2A20),
    softPink: Color(0xFF3A2430),
    softPurple: Color(0xFF2B2746),
    softGold: Color(0xFF332D1F),
    textOnAccent: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
    knowledgeBg: Color(0xFF141821),
    knowledgePrimary: Color(0xFF9FB6FF),
    weakRed: Color(0xFFFF8C86),
    dueOrange: Color(0xFFFFB17A),
    masteredGreen: Color(0xFF74D99F),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? paper,
    Color? card,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceTint,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? accent,
    Color? study,
    Color? fitness,
    Color? diet,
    Color? sleep,
    Color? journal,
    Color? focus,
    Color? success,
    Color? warning,
    Color? danger,
    Color? softBlue,
    Color? softGreen,
    Color? softOrange,
    Color? softPink,
    Color? softPurple,
    Color? softGold,
    Color? textOnAccent,
    Color? shadow,
    Color? knowledgeBg,
    Color? knowledgePrimary,
    Color? weakRed,
    Color? dueOrange,
    Color? masteredGreen,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      paper: paper ?? this.paper,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      study: study ?? this.study,
      fitness: fitness ?? this.fitness,
      diet: diet ?? this.diet,
      sleep: sleep ?? this.sleep,
      journal: journal ?? this.journal,
      focus: focus ?? this.focus,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      softBlue: softBlue ?? this.softBlue,
      softGreen: softGreen ?? this.softGreen,
      softOrange: softOrange ?? this.softOrange,
      softPink: softPink ?? this.softPink,
      softPurple: softPurple ?? this.softPurple,
      softGold: softGold ?? this.softGold,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      shadow: shadow ?? this.shadow,
      knowledgeBg: knowledgeBg ?? this.knowledgeBg,
      knowledgePrimary: knowledgePrimary ?? this.knowledgePrimary,
      weakRed: weakRed ?? this.weakRed,
      dueOrange: dueOrange ?? this.dueOrange,
      masteredGreen: masteredGreen ?? this.masteredGreen,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      study: Color.lerp(study, other.study, t)!,
      fitness: Color.lerp(fitness, other.fitness, t)!,
      diet: Color.lerp(diet, other.diet, t)!,
      sleep: Color.lerp(sleep, other.sleep, t)!,
      journal: Color.lerp(journal, other.journal, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      softBlue: Color.lerp(softBlue, other.softBlue, t)!,
      softGreen: Color.lerp(softGreen, other.softGreen, t)!,
      softOrange: Color.lerp(softOrange, other.softOrange, t)!,
      softPink: Color.lerp(softPink, other.softPink, t)!,
      softPurple: Color.lerp(softPurple, other.softPurple, t)!,
      softGold: Color.lerp(softGold, other.softGold, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      knowledgeBg: Color.lerp(knowledgeBg, other.knowledgeBg, t)!,
      knowledgePrimary: Color.lerp(knowledgePrimary, other.knowledgePrimary, t)!,
      weakRed: Color.lerp(weakRed, other.weakRed, t)!,
      dueOrange: Color.lerp(dueOrange, other.dueOrange, t)!,
      masteredGreen: Color.lerp(masteredGreen, other.masteredGreen, t)!,
    );
  }
}

extension GrowthThemeColors on BuildContext {
  AppThemeColors get growthColors {
    return Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
  }
}
