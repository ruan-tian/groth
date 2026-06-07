import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

class GrowthCard extends StatefulWidget {
  const GrowthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 14,
    this.backgroundColor,
    this.borderColor,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadow;

  @override
  State<GrowthCard> createState() => _GrowthCardState();
}

class _GrowthCardState extends State<GrowthCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
        onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
        onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppColors.surface,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.borderColor ?? AppColors.border,
                width: 0.6,
              ),
              boxShadow: widget.shadow ?? AppColors.cardShadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    setState(() => _isPressed = value);
  }
}
