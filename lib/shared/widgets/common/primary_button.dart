import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import 'growth_motion.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.onTap,
    this.icon,
    this.height = 52,
    this.borderRadius = 14,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || isLoading;

    return Opacity(
      opacity: disabled ? 0.56 : 1,
      child: GrowthPressable(
        onTap: disabled ? null : onTap,
        semanticLabel: text,
        borderRadius: BorderRadius.circular(borderRadius),
        scale: 0.98,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.growthColors.primary,
                context.growthColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: context.growthColors.primary.withValues(
                        alpha: 0.24,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: context.growthColors.textOnAccent,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: context.growthColors.textOnAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.growthColors.textOnAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
