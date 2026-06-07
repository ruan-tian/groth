import 'dart:math' as math;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Animation duration for the full particle burst lifecycle.
const Duration kBurstDuration = Duration(milliseconds: 1000);

/// Minimum number of particles spawned per burst.
const int kMinParticleCount = 12;

/// Maximum number of particles spawned per burst.
const int kMaxParticleCount = 16;

/// Minimum initial particle size (logical pixels).
const double kMinParticleSize = 8.0;

/// Maximum initial particle size (logical pixels).
const double kMaxParticleSize = 20.0;

/// Downward gravity applied to each particle every frame (px/s²).
const double kGravity = 180.0;

/// Minimum initial speed magnitude (px/s).
const double kMinSpeed = 120.0;

/// Maximum initial speed magnitude (px/s).
const double kMaxSpeed = 320.0;

/// Minimum initial rotation (radians).
const double kMinRotation = -0.6;

/// Maximum initial rotation (radians).
const double kMaxRotation = 0.6;

/// Angular velocity range (radians/s).
const double kAngularSpeedRange = 3.0;

// ---------------------------------------------------------------------------
// Color palettes
// ---------------------------------------------------------------------------

/// Warm pink-red palette for heart particles.
const List<Color> kHeartColors = [
  Color(0xFFFF6B8A),
  Color(0xFFFF8FA3),
  Color(0xFFFFB5C2),
];

/// Golden palette for star particles.
const List<Color> kStarColors = [
  Color(0xFFFFD700),
  Color(0xFFFFA500),
  Color(0xFFFFE4B5),
];

/// Soft lavender palette for sparkle particles.
const List<Color> kSparkleColors = [
  Color(0xFFB5A8E0),
  Color(0xFF9B8FE8),
  Color(0xFFD4C5F9),
];

// ---------------------------------------------------------------------------
// Particle type enum
// ---------------------------------------------------------------------------

/// Controls the visual appearance and color palette of spawned particles.
enum ParticleType {
  /// Heart-shaped particles in warm pink-red tones.
  hearts,

  /// Five-pointed star particles in golden tones.
  stars,

  /// Diamond / sparkle particles in soft lavender tones.
  sparkles,
}

/// Returns the color palette for the given [ParticleType].
List<Color> _paletteFor(ParticleType type) {
  switch (type) {
    case ParticleType.hearts:
      return kHeartColors;
    case ParticleType.stars:
      return kStarColors;
    case ParticleType.sparkles:
      return kSparkleColors;
  }
}

// ---------------------------------------------------------------------------
// Particle data class
// ---------------------------------------------------------------------------

/// A single particle with position, velocity, size, opacity, rotation, and
/// color. Mutated each frame by the painter for performance (avoids per-frame
/// allocation).
class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.angularVelocity,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double rotation;
  double angularVelocity;
  Color color;
}

// ---------------------------------------------------------------------------
// Custom Painter
// ---------------------------------------------------------------------------

/// Paints a burst of [_Particle] objects on a [Canvas].
///
/// Each particle type has a dedicated drawing path:
/// - **hearts** – drawn via [Path] (two cubic Bézier arcs).
/// - **stars**   – drawn via [Path] (five-pointed star outline).
/// - **sparkles** – drawn via [Path] (diamond / rotated square).
class ParticleBurstPainter extends CustomPainter {
  ParticleBurstPainter({
    required this.particles,
    required this.progress,
    required this.type,
  });

  /// The live list of particles (mutated each frame).
  final List<_Particle> particles;

  /// Animation progress from 0.0 to 1.0.
  final double progress;

  /// The particle type that determines drawing style.
  final ParticleType type;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || progress <= 0) return;

    // Apply physics & render each particle.
    for (final p in particles) {
      // Update position from velocity.
      p.x += p.vx / 60; // Assume ~60 fps frame budget.
      p.y += p.vy / 60;

      // Gravity.
      p.vy += kGravity / 60;

      // Angular rotation.
      p.rotation += p.angularVelocity / 60;

      // Fade out based on progress.
      p.opacity = (1.0 - progress).clamp(0.0, 1.0);

      // Slight scale-down over lifetime.
      final effectiveSize = p.size * (1.0 - progress * 0.4);

      if (p.opacity <= 0 || effectiveSize <= 0) continue;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..isAntiAlias = true;

      switch (type) {
        case ParticleType.hearts:
          _drawHeart(canvas, effectiveSize, paint);
          break;
        case ParticleType.stars:
          _drawStar(canvas, effectiveSize, paint);
          break;
        case ParticleType.sparkles:
          _drawSparkle(canvas, effectiveSize, paint);
          break;
      }

      canvas.restore();
    }
  }

  // -- Heart via two cubic Bézier arcs ------------------------------------

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final s = size / 2;
    final path = Path()
      ..moveTo(0, s * 0.4)
      // Left arc.
      ..cubicTo(-s * 0.8, -s * 0.4, -s * 1.4, s * 0.4, 0, s * 1.2)
      // Right arc (mirror).
      ..cubicTo(s * 1.4, s * 0.4, s * 0.8, -s * 0.4, 0, s * 0.4)
      ..close();

    canvas.drawPath(path, paint);
  }

  // -- Five-pointed star via Path ------------------------------------------

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final outer = size / 2;
    final inner = outer * 0.42;
    final path = Path();

    for (var i = 0; i < 5; i++) {
      // Outer point.
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final ox = outer * math.cos(outerAngle);
      final oy = outer * math.sin(outerAngle);

      // Inner point (halfway between outer points).
      final innerAngle = ((i * 72 + 36) - 90) * math.pi / 180;
      final ix = inner * math.cos(innerAngle);
      final iy = inner * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  // -- Diamond sparkle via Path --------------------------------------------

  void _drawSparkle(Canvas canvas, double size, Paint paint) {
    final s = size / 2;
    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.45, 0)
      ..lineTo(0, s)
      ..lineTo(-s * 0.45, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Add a subtle cross highlight for extra sparkle feel.
    final highlight = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawLine(Offset(-s * 0.25, 0), Offset(s * 0.25, 0), highlight);
    canvas.drawLine(Offset(0, -s * 0.5), Offset(0, s * 0.5), highlight);
  }

  @override
  bool shouldRepaint(covariant ParticleBurstPainter oldDelegate) {
    // Always repaint — particle positions change every frame.
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        !identical(oldDelegate.particles, particles);
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A tap-to-react particle burst overlay.
///
/// When [trigger] is toggled (any value change), a burst of particles
/// erupts from [center] and animates over [kBurstDuration].
///
/// ```dart
/// final trigger = ValueNotifier<bool>(false);
///
/// ParticleBurst(
///   trigger: trigger,
///   center: Offset(200, 300),
///   type: ParticleType.hearts,
/// )
///
/// // Later, to fire the burst:
/// trigger.value = !trigger.value;
/// ```
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.trigger,
    required this.center,
    this.type = ParticleType.sparkles,
  });

  /// Toggling this notifier fires a new particle burst.
  final ValueNotifier<bool> trigger;

  /// The origin point (in the parent's coordinate space) for the burst.
  final Offset center;

  /// The visual style of the particles.
  final ParticleType type;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final math.Random _random;

  /// Live list of particles for the current burst.
  List<_Particle> _particles = [];

  /// Snapshot of [widget.type] at the time of burst creation so mid-animation
  /// type changes don't mutate the running burst visuals.
  ParticleType _activeType = ParticleType.sparkles;

  @override
  void initState() {
    super.initState();
    _random = math.Random();
    _controller = AnimationController(
      vsync: this,
      duration: kBurstDuration,
    )..addListener(_onTick);

    widget.trigger.addListener(_onTrigger);
  }

  @override
  void didUpdateWidget(covariant ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_onTrigger);
      widget.trigger.addListener(_onTrigger);
    }
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_onTrigger);
    _controller.dispose();
    super.dispose();
  }

  // -- Trigger logic -------------------------------------------------------

  void _onTrigger() {
    // Only fire when value transitions (any change counts).
    _spawnParticles();
    _controller.forward(from: 0);
  }

  void _spawnParticles() {
    _activeType = widget.type;
    final palette = _paletteFor(_activeType);
    final count = kMinParticleCount +
        _random.nextInt(kMaxParticleCount - kMinParticleCount + 1);

    _particles = List<_Particle>.generate(count, (_) {
      // Random direction in full circle.
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = _lerp(kMinSpeed, kMaxSpeed, _random.nextDouble());

      return _Particle(
        x: widget.center.dx,
        y: widget.center.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: _lerp(kMinParticleSize, kMaxParticleSize, _random.nextDouble()),
        opacity: 1.0,
        rotation: _lerp(kMinRotation, kMaxRotation, _random.nextDouble()),
        angularVelocity:
            (_random.nextDouble() - 0.5) * 2 * kAngularSpeedRange,
        color: palette[_random.nextInt(palette.length)],
      );
    });
  }

  // -- Frame tick ----------------------------------------------------------

  void _onTick() {
    setState(() {
      // Triggers a rebuild so the CustomPaint picks up the new progress.
      // Particle physics are applied inside the painter for co-located mutation.
    });
  }

  // -- Helpers -------------------------------------------------------------

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty || !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: ParticleBurstPainter(
          particles: _particles,
          progress: _controller.value,
          type: _activeType,
        ),
      ),
    );
  }
}
