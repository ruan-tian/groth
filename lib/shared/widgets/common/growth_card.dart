import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import 'growth_motion.dart';

class GrowthCard extends StatelessWidget {
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
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: GrowthPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.border,
              width: 0.6,
            ),
            boxShadow: shadow ?? AppColors.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
