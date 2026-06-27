import 'package:flutter/material.dart';

import '../../../../app/design/design.dart';
import 'weather_pet_card.dart';

class WeatherPetSheet extends StatelessWidget {
  const WeatherPetSheet({super.key});

  static void show(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭天气卡片',
      barrierColor: context.growthColors.shadow.withValues(alpha: 0.22),
      transitionDuration: reduceMotion
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => const WeatherPetSheet(),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        if (reduceMotion) {
          return FadeTransition(opacity: curved, child: child);
        }

        final offset = Tween<Offset>(
          begin: const Offset(0.08, -0.12),
          end: Offset.zero,
        ).animate(curved);
        final scale = Tween<double>(begin: 0.86, end: 1).animate(curved);

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: offset,
            child: ScaleTransition(
              scale: scale,
              alignment: Alignment.topRight,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width >= 720 ? 620.0 : size.width - 32;

    return SafeArea(
      child: Align(
        alignment: size.width >= 720 ? Alignment.topRight : Alignment.center,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, size.width >= 720 ? 18 : 16, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: size.height * 0.72,
            ),
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: context.growthColors.shadow.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: const WeatherPetCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
