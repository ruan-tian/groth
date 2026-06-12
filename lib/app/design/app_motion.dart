import 'package:flutter/material.dart';

/// Growth OS unified motion system.
///
/// Standard durations and curves for consistent animation feel.
class AppMotion {
  AppMotion._();

  // ---------------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------------

  /// Instant feedback: button press, toggle, opacity change.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions: card expand, list reorder, tab switch.
  static const Duration normal = Duration(milliseconds: 200);

  /// Emphasis transitions: page enter, dialog open, bottom sheet.
  static const Duration slow = Duration(milliseconds: 300);

  /// Complex transitions: staggered list, multi-step animation.
  static const Duration lazy = Duration(milliseconds: 500);

  /// Page route transitions. Kept under 300ms to preserve a responsive feel.
  static const Duration page = Duration(milliseconds: 260);

  // ---------------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------------

  /// Standard ease-out for most UI transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Decelerate for elements entering the screen.
  static const Curve decelerate = Curves.easeOut;

  /// Subtle overshoot for pop-in effects.
  static const Curve pop = Curves.easeOutBack;

  /// Smooth ease-in-out for continuous animations.
  static const Curve smooth = Curves.easeInOutCubic;

  /// Linear for progress bars and timers.
  static const Curve linear = Curves.linear;

  /// Route enter motion: soft enough for frequent navigation.
  static const Curve pageEnter = Curves.easeOutCubic;

  /// Route exit motion.
  static const Curve pageExit = Curves.easeInCubic;

  /// Returns true when the platform/user requested reduced animations.
  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations ?? false;
  }

  /// Collapses a duration to zero when reduced motion is enabled.
  static Duration duration(BuildContext context, Duration value) {
    return reduceMotion(context) ? Duration.zero : value;
  }
}
