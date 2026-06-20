import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// A reusable record tile for "recent records" sections across modules.
///
/// Displays an icon, title, subtitle, and optional EXP / secondary badges.
class RecentRecordTile extends StatelessWidget {
  const RecentRecordTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    this.primaryBadge,
    this.primaryBadgeColor,
    this.secondaryBadge,
    this.secondaryBadgeColor,
    this.imageAsset,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final String? primaryBadge;
  final Color? primaryBadgeColor;
  final String? secondaryBadge;
  final Color? secondaryBadgeColor;
  final String? imageAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.growthColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.growthColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // ── Leading icon ──
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: iconBackgroundColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: imageAsset == null
                  ? Icon(icon, color: iconColor, size: 20)
                  : Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        imageAsset!,
                        fit: BoxFit.contain,
                        cacheWidth: 96,
                        errorBuilder: (_, _, _) =>
                            Icon(icon, color: iconColor, size: 20),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),

            // ── Title + subtitle ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.growthColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.growthColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Badges ──
            if (primaryBadge != null || secondaryBadge != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (primaryBadge != null)
                    _Badge(
                      label: primaryBadge!,
                      color: primaryBadgeColor ?? context.growthColors.primary,
                    ),
                  if (primaryBadge != null && secondaryBadge != null)
                    const SizedBox(height: 2),
                  if (secondaryBadge != null)
                    _Badge(
                      label: secondaryBadge!,
                      color:
                          secondaryBadgeColor ??
                          context.growthColors.textSecondary,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
