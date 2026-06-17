import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../shared/widgets/common/growth_card.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.currentExp,
    required this.nextExp,
    this.onTap,
  });

  final int level;
  final String title;
  final int currentExp;
  final int nextExp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = nextExp > 0 ? (currentExp / nextExp).clamp(0.0, 1.0) : 0.0;
    final colors = context.growthColors;

    return GrowthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      backgroundColor: colors.surface,
      borderColor: colors.primary.withValues(alpha: 0.12),
      shadow: AppShadows.lg,
      child: Row(
        children: [
          _buildHexagonLevel(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.$level $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EXP $currentExp / $nextExp',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colors.softPurple,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.softPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.primary,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexagonLevel(BuildContext context) {
    final colors = context.growthColors;
    return ClipPath(
      clipper: _HexagonClipper(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryLight, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            '$level',
            style: TextStyle(
              color: colors.textOnAccent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
