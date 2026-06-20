import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 统一的空状态组件
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
    this.imageAsset,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageAsset == null)
            Icon(icon, size: 48, color: accentColor.withValues(alpha: 0.4))
          else
            Image.asset(
              imageAsset!,
              width: 96,
              height: 96,
              fit: BoxFit.contain,
              cacheWidth: 192,
              errorBuilder: (_, _, _) => Icon(
                icon,
                size: 48,
                color: accentColor.withValues(alpha: 0.4),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: colors.textOnAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
