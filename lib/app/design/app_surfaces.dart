import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

/// Growth OS unified surface presets.
///
/// Pre-built [BoxDecoration] for common surface types.
/// Use [colored] to tint a surface with a module accent color.
class AppSurfaces {
  AppSurfaces._();

  /// Standard card: white background, subtle border, medium shadow.
  static BoxDecoration card = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(color: AppColors.border, width: 0.6),
    boxShadow: AppShadows.md,
  );

  /// Elevated card: white background, stronger shadow, no border.
  static BoxDecoration elevatedCard = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    boxShadow: AppShadows.lg,
  );

  /// Bottom sheet: white background, top-rounded, strong shadow.
  static BoxDecoration sheet = BoxDecoration(
    color: AppColors.card,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(AppRadius.xxl),
    ),
    boxShadow: AppShadows.xl,
  );

  /// Input field: white background, subtle border.
  static BoxDecoration input = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: AppColors.border),
  );

  /// Pill-shaped chip or badge.
  static BoxDecoration pill = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppRadius.full),
    border: Border.all(color: AppColors.border),
  );

  /// Create a card tinted with a module accent color.
  static BoxDecoration colored(Color color) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: color.withValues(alpha: 0.13)),
      boxShadow: AppShadows.colored(color),
    );
  }
}
