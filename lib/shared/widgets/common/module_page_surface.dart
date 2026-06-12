import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

class ModulePageSurface extends StatelessWidget {
  const ModulePageSurface({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.paper,
            color.withValues(alpha: 0.035),
            AppColors.paper,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: child,
    );
  }
}
