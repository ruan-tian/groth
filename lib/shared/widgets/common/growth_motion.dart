import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// Consistent press feedback for cards, buttons, and icon actions.
class GrowthPressable extends StatefulWidget {
  const GrowthPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.scale = 0.985,
    this.borderRadius,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final double scale;
  final BorderRadius? borderRadius;
  final HitTestBehavior behavior;

  @override
  State<GrowthPressable> createState() => _GrowthPressableState();
}

class _GrowthPressableState extends State<GrowthPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final content = GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed && enabled ? widget.scale : 1,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );

    final clipped = widget.borderRadius == null
        ? content
        : ClipRRect(borderRadius: widget.borderRadius!, child: content);

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      child: clipped,
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }
}

/// Lightweight one-shot entrance animation for sections that appear in-place.
class GrowthEntrance extends StatelessWidget {
  const GrowthEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = const Offset(0, 12),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: AppMotion.standard,
      builder: (context, value, child) {
        final delayed = delay == Duration.zero
            ? value
            : ((value * (duration + delay).inMilliseconds -
                          delay.inMilliseconds) /
                      duration.inMilliseconds)
                  .clamp(0.0, 1.0);
        final eased = AppMotion.standard.transform(delayed);

        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - eased), offset.dy * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated size + fade wrapper for sections whose content changes height.
class GrowthAnimatedSection extends StatelessWidget {
  const GrowthAnimatedSection({
    super.key,
    required this.child,
    this.duration = AppMotion.normal,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppMotion.duration(context, duration);

    return AnimatedSize(
      duration: effectiveDuration,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: effectiveDuration,
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.pageExit,
        child: child,
      ),
    );
  }
}
