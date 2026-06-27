import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

class ModulePageSurface extends StatefulWidget {
  const ModulePageSurface({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  State<ModulePageSurface> createState() => _ModulePageSurfaceState();
}

class _ModulePageSurfaceState extends State<ModulePageSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.growthColors.paper,
                widget.color.withValues(alpha: 0.025),
                context.growthColors.paper,
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
        if (!reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) {
                    return CustomPaint(
                      painter: _ModuleAmbientPainter(
                        progress: _controller.value,
                        color: widget.color,
                        paper: context.growthColors.paper,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _ModuleAmbientPainter extends CustomPainter {
  const _ModuleAmbientPainter({
    required this.progress,
    required this.color,
    required this.paper,
  });

  final double progress;
  final Color color;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final particles = const [
      _AmbientDot(0.12, 0.12, 5, 0.0, 18),
      _AmbientDot(0.78, 0.16, 7, 0.18, 24),
      _AmbientDot(0.28, 0.34, 4, 0.36, 15),
      _AmbientDot(0.88, 0.48, 6, 0.58, 22),
      _AmbientDot(0.18, 0.72, 8, 0.74, 26),
      _AmbientDot(0.72, 0.82, 5, 0.9, 18),
    ];

    for (final dot in particles) {
      final phase = (progress + dot.delay) % 1;
      final drift = math.sin(phase * math.pi * 2) * dot.drift;
      final lift = math.cos(phase * math.pi * 2) * dot.drift * 0.55;
      final center = Offset(
        size.width * dot.dx + drift,
        size.height * dot.dy + lift,
      );
      final opacity = 0.055 + 0.035 * math.sin(phase * math.pi * 2).abs();

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(center, dot.radius, paint);

      strokePaint.color = paper.withValues(alpha: 0.5);
      canvas.drawCircle(center, dot.radius + 2.4, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModuleAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.paper != paper;
  }
}

class _AmbientDot {
  const _AmbientDot(this.dx, this.dy, this.radius, this.delay, this.drift);

  final double dx;
  final double dy;
  final double radius;
  final double delay;
  final double drift;
}
