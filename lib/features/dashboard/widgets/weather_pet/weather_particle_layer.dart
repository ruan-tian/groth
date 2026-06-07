import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'weather_card_data.dart';

class WeatherParticleLayer extends StatefulWidget {
  const WeatherParticleLayer({
    super.key,
    required this.type,
    required this.accentColor,
    this.enabled = true,
  });

  final WeatherParticleType type;
  final Color accentColor;
  final bool enabled;

  @override
  State<WeatherParticleLayer> createState() => _WeatherParticleLayerState();
}

class _WeatherParticleLayerState extends State<WeatherParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WeatherParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _ParticlePainter(
            type: widget.type,
            progress: 0,
            accentColor: widget.accentColor,
          ),
          size: Size.infinite,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return CustomPaint(
            painter: _ParticlePainter(
              type: widget.type,
              progress: _controller.value,
              accentColor: widget.accentColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.type,
    required this.progress,
    required this.accentColor,
  });

  final WeatherParticleType type;
  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case WeatherParticleType.sparkle:
        _paintSparkle(canvas, size);
        break;
      case WeatherParticleType.cloud:
        _paintCloud(canvas, size);
        break;
      case WeatherParticleType.raindrop:
        _paintRain(canvas, size, 28, 0.55);
        break;
      case WeatherParticleType.heavyRain:
        _paintHeavyRain(canvas, size);
        break;
      case WeatherParticleType.snowflake:
        _paintSnow(canvas, size);
        break;
      case WeatherParticleType.wind:
        _paintWind(canvas, size);
        break;
      case WeatherParticleType.heat:
        _paintHeat(canvas, size);
        break;
      case WeatherParticleType.star:
        _paintStars(canvas, size);
        break;
    }
  }

  // ── Sparkle ──

  void _paintSparkle(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 22; i++) {
      final baseX = _unit(i, 42) * size.width;
      final baseY = _unit(i, 43) * size.height * 0.58;
      final x = baseX + math.sin(progress * math.pi * 2 + i * 0.7) * 5;
      final y = baseY + math.cos(progress * math.pi * 1.5 + i) * 4;
      final alpha = 0.2 + 0.5 * math.sin(progress * math.pi * 3 + i).abs();
      paint.color = Colors.white.withValues(alpha: alpha);
      final r = 1.5 + _unit(i, 44) * 2.5;
      _drawDiamondStar(canvas, Offset(x, y), r, paint);
    }
  }

  // ── Cloud ──

  void _paintCloud(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.08 + i * 0.16);
      final offset = (progress + _unit(i, 17) * 0.35) % 1.0;
      final x = offset * size.width * 1.3 - size.width * 0.15;
      _drawCloudBubble(canvas, Offset(x, y), 16 + _unit(i, 18) * 12, paint);
    }
  }

  void _drawCloudBubble(Canvas canvas, Offset center, double r, Paint paint) {
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(
      Offset(center.dx + r * 0.7, center.dy - r * 0.2),
      r * 0.7,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx - r * 0.6, center.dy - r * 0.1),
      r * 0.6,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + r * 0.2, center.dy + r * 0.2),
      r * 0.5,
      paint,
    );
  }

  // ── Rain ──

  void _paintRain(Canvas canvas, Size size, int count, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final x = _unit(i, 73) * size.width;
      final y = ((progress + _unit(i, 74) * 0.14) % 1.0) * size.height * 1.05;
      canvas.drawLine(Offset(x, y), Offset(x - 7, y + 24), paint);
    }
  }

  // ── Heavy Rain + Lightning ──

  void _paintHeavyRain(Canvas canvas, Size size) {
    _paintRain(canvas, size, 38, 0.68);
    // Lightning flash: gradient from top, rapidly fading
    final flashPhase = (progress * 14) % 1.0;
    if (flashPhase < 0.06) {
      final flashPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.7));
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.7),
        flashPaint,
      );
      // Bolt line
      if (flashPhase < 0.02) {
        final boltPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final boltPath = Path()
          ..moveTo(size.width * 0.25, 0)
          ..lineTo(size.width * 0.2, size.height * 0.2)
          ..lineTo(size.width * 0.3, size.height * 0.22)
          ..lineTo(size.width * 0.18, size.height * 0.5)
          ..lineTo(size.width * 0.28, size.height * 0.52)
          ..lineTo(size.width * 0.22, size.height * 0.7);
        canvas.drawPath(boltPath, boltPaint);
      }
    }
  }

  // ── Snow ──

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 23; i++) {
      final baseX = _unit(i, 55) * size.width;
      final y = ((progress + _unit(i, 56) * 0.07) % 1.0) * size.height;
      final x = baseX + math.sin(progress * math.pi * 2 + i * 0.8) * 6;
      final radius = 1.5 + _unit(i, 57) * 2.2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  // ── Wind ──

  void _paintWind(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.4);
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.12 + i * 0.14);
      final off = (progress + _unit(i, 29) * 0.3) % 1.0;
      final sx = size.width * (off - 0.15);
      final path = Path()
        ..moveTo(sx, y)
        ..quadraticBezierTo(
          sx + size.width * 0.25,
          y - 12,
          sx + size.width * 0.4,
          y,
        )
        ..quadraticBezierTo(
          sx + size.width * 0.55,
          y + 9,
          sx + size.width * 0.7,
          y - 3,
        );
      canvas.drawPath(path, linePaint);
    }
    // Leaves
    final leafPaint = Paint()
      ..color = const Color(0xFFA8D8A0).withValues(alpha: 0.45);
    for (var i = 0; i < 5; i++) {
      final off = (progress + i * 0.22) % 1.0;
      final x = off * size.width * 1.1 - size.width * 0.05;
      final y =
          size.height * (0.25 + i * 0.14) + math.sin(progress * 10 + i) * 14;
      leafPaint.color = const Color(
        0xFFA8D8A0,
      ).withValues(alpha: 0.3 + 0.2 * math.sin(progress * 6 + i));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 7, height: 4),
        leafPaint,
      );
    }
  }

  // ── Heat ──

  void _paintHeat(Canvas canvas, Size size) {
    final paint = Paint()..color = accentColor.withValues(alpha: 0.2);
    for (var i = 0; i < 18; i++) {
      final x = _unit(i, 63) * size.width * 0.6 + size.width * 0.2;
      final y = ((1 - progress + _unit(i, 64) * 0.08) % 1.0) * size.height;
      final alpha = (0.08 + 0.14 * math.sin(progress * math.pi * 2 + i)).abs();
      paint.color = accentColor.withValues(alpha: alpha);
      final w = 26 + _unit(i, 65) * 24;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: 6),
        paint,
      );
    }
  }

  // ── Stars ──

  void _paintStars(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 18; i++) {
      final x = (i * 57 + _unit(i, 37) * 22) % size.width;
      final y = (i * 39 + _unit(i, 38) * 16) % (size.height * 0.52);
      final alpha = 0.2 + 0.4 * math.sin(progress * math.pi * 2 + i).abs();
      paint.color = Colors.white.withValues(alpha: alpha);
      _drawDiamondStar(canvas, Offset(x, y), 1.0 + _unit(i, 39) * 1.8, paint);
    }
  }

  // ── Helpers ──

  void _drawDiamondStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 - math.pi / 4;
      final outerX = center.dx + math.cos(a) * radius;
      final outerY = center.dy + math.sin(a) * radius;
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      final innerX = center.dx + math.cos(a + math.pi / 4) * radius * 0.35;
      final innerY = center.dy + math.sin(a + math.pi / 4) * radius * 0.35;
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _unit(int index, int seed) {
    final value = math.sin(index * 12.9898 + seed * 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
