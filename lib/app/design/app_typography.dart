import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Growth OS extended typography scale.
///
/// Supplements [AppTextStyles] with additional semantic styles.
class AppTypography {
  AppTypography._();

  /// Large headline for hero sections.
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// Button text: medium weight, tight spacing.
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// Small button text.
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// Label for form fields, tabs, navigation.
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.3,
  );

  /// Overline: smallest semantic text for categories, timestamps.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    height: 1.3,
    letterSpacing: 0.8,
  );

  /// Number display: large tabular figures for stats.
  static const TextStyle numberSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
