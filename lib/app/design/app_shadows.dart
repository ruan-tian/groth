import 'package:flutter/material.dart';

/// Growth OS unified shadow system.
///
/// 5 elevation levels for consistent depth across all surfaces.
/// Use [colored] to tint shadows with a module accent color.
class AppShadows {
  AppShadows._();

  /// Subtle lift for cards, chips, list items.
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Standard card elevation.
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Prominent cards, bottom sheets.
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Floating elements: FAB, modals, dropdowns.
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 32, offset: Offset(0, 12)),
  ];

  /// Inset shadow for pressed/active states.
  static const List<BoxShadow> inset = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: -1,
    ),
  ];

  /// Create a shadow tinted with a module accent color.
  static List<BoxShadow> colored(
    Color color, {
    double blurRadius = 18,
    double offsetY = 8,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.12),
        blurRadius: blurRadius,
        offset: Offset(0, offsetY),
      ),
    ];
  }
}
