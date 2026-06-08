import 'package:flutter/material.dart';

class PetFloatingAsset extends StatelessWidget {
  const PetFloatingAsset({
    super.key,
    required this.asset,
    this.size = 42,
    this.padding = 0,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.glow = true,
    this.shadow = true,
  });

  final String asset;
  final double size;
  final double padding;
  final double opacity;
  final BoxFit fit;
  final bool glow;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final image = Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          asset,
          fit: fit,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Icon(
            Icons.pets_rounded,
            size: size * 0.58,
            color: const Color(0xFFD79A78),
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.72),
                      blurRadius: size * 0.28,
                      spreadRadius: size * 0.03,
                    ),
                  ],
                ),
              ),
            ),
          if (shadow)
            Positioned(
              left: size * 0.18,
              right: size * 0.18,
              bottom: -size * 0.02,
              height: size * 0.18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5E45).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5E45).withValues(alpha: 0.10),
                      blurRadius: size * 0.18,
                    ),
                  ],
                ),
              ),
            ),
          image,
        ],
      ),
    );
  }
}
