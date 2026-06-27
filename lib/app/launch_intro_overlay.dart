import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// AAA级启动动画 - 对标 Linear / Raycast / Arc
/// 
/// 核心特性：
/// - 动态 Mesh 渐变背景
/// - Logo 从粒子聚合而成
/// - 光线扫过效果
/// - 呼吸光晕
/// - 弹性物理动效
/// - 动态模糊
/// - 粒子轨迹
class LaunchIntroOverlay extends StatefulWidget {
  const LaunchIntroOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LaunchIntroOverlay> createState() => _LaunchIntroOverlayState();
}

class _LaunchIntroOverlayState extends State<LaunchIntroOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _breathe;
  late final AnimationController _particles;
  late final AnimationController _shimmer;
  Timer? _shimmerTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    
    // 主动画 2.8s
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });

    // 呼吸光晕 2s循环
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 粒子 4s循环
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 光线扫过 1.5s
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _main.value = 0.85;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _visible = false);
        });
        return;
      }
      _main.forward();
      _breathe.repeat(reverse: true);
      _particles.repeat();
      _shimmerTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) _shimmer.forward();
      });
    });
  }

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    _main.dispose();
    _breathe.dispose();
    _particles.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          AnimatedBuilder(
            animation: Listenable.merge([_main, _breathe, _particles, _shimmer]),
            builder: (_, _) => _Scene(
              main: _main.value,
              breathe: _breathe.value,
              particles: _particles.value,
              shimmer: _shimmer.value,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scene
// ─────────────────────────────────────────────────────────────────────────────

class _Scene extends StatelessWidget {
  const _Scene({
    required this.main,
    required this.breathe,
    required this.particles,
    required this.shimmer,
  });

  static const _primary = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _accent = Color(0xFFFBBF24);
  static const _ink = Color(0xFF0F172A);
  static const _bg = Color(0xFFFAFBFF);

  final double main;
  final double breathe;
  final double particles;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final shortest = size.shortestSide;
    final logoSize = shortest < 400 ? 76.0 : 88.0;
    final ringSize = logoSize + 56;

    // 各阶段时间
    final bgIn = _ease(main, 0, 0.12);
    final logoIn = _spring(main, 0.08, 0.4);
    final ringIn = _ease(main, 0.12, 0.52);
    final glowIn = _ease(main, 0.18, 0.48);
    final titleIn = _ease(main, 0.32, 0.58);
    final subtitleIn = _ease(main, 0.42, 0.65);
    final progressIn = _ease(main, 0.5, 0.75);
    final exitScale = 1.0 + _ease(main, 0.88, 1.0) * 0.22;
    final exitOpacity = 1.0 - _ease(main, 0.92, 1.0);

    return IgnorePointer(
      child: Transform.scale(
        scale: exitScale,
        child: Opacity(
          opacity: exitOpacity,
          child: Container(
            color: _bg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. 动态 Mesh 渐变
                CustomPaint(
                  painter: _MeshGradientPainter(
                    progress: bgIn,
                    breathe: breathe,
                    primary: _primary,
                    accent: _accent,
                  ),
                ),

                // 2. 粒子场
                CustomPaint(
                  painter: _ParticleFieldPainter(
                    progress: particles,
                    fade: bgIn,
                    primary: _primary,
                    accent: _accent,
                  ),
                ),

                // 3. 主内容
                Center(
                  child: Transform.translate(
                    offset: Offset(0, -16 * (1 - titleIn)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo + 环 + 光晕
                        _buildLogo(logoSize, ringSize, logoIn, ringIn, glowIn, breathe),
                        const SizedBox(height: 36),
                        // 标题
                        _buildTitle(titleIn),
                        const SizedBox(height: 14),
                        // 副标题
                        _buildSubtitle(subtitleIn),
                      ],
                    ),
                  ),
                ),

                // 4. 光线扫过
                if (shimmer > 0 && shimmer < 1)
                  CustomPaint(
                    painter: _ShimmerPainter(
                      progress: shimmer,
                      primary: _primary,
                    ),
                  ),

                // 5. 底部进度
                _buildProgress(progressIn, padding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ────────────────────────────────────────────────────────────────────

  Widget _buildLogo(double size, double ring, double logoIn, double ringIn, double glowIn, double breathe) {
    final breatheScale = 1.0 + breathe * 0.03;
    
    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外层呼吸光晕
          Transform.scale(
            scale: breatheScale * (0.7 + glowIn * 0.5),
            child: Opacity(
              opacity: glowIn * 0.25 * (0.7 + breathe * 0.3),
              child: Container(
                width: ring + 32,
                height: ring + 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withValues(alpha: 0.3),
                      _primaryLight.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 渐变环
          CustomPaint(
            size: Size.square(ring),
            painter: _GradientRingPainter(
              progress: ringIn,
              breathe: breathe,
              primary: _primary,
              accent: _accent,
            ),
          ),

          // Logo 聚合动画
          Transform.scale(
            scale: 0.4 + logoIn * 0.6,
            child: Opacity(
              opacity: logoIn.clamp(0.0, 1.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.22),
                child: Image.asset(
                  'assets/images/app/app_icon.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 标题（逐字 + 弹性） ─────────────────────────────────────────────────────

  Widget _buildTitle(double reveal) {
    const text = 'Growth OS';
    final count = (reveal * text.length).ceil();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(text.length, (i) {
        final show = i < count;
        final charSpring = _spring(
          (reveal * text.length - i).clamp(0.0, 1.0),
          0,
          1,
        );
        return Transform.translate(
          offset: Offset(0, show ? 0 : 12 * (1 - charSpring)),
          child: Opacity(
            opacity: (show ? charSpring : 0).clamp(0.0, 1.0).toDouble(),
            child: Text(
              text[i],
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── 副标题 ──────────────────────────────────────────────────────────────────

  Widget _buildSubtitle(double reveal) {
    return Opacity(
      opacity: reveal,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - reveal)),
        child: Text(
          '每天进步，成为更好的自己',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _ink.withValues(alpha: 0.4),
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  // ── 进度条 ──────────────────────────────────────────────────────────────────

  Widget _buildProgress(double reveal, EdgeInsets padding) {
    return Positioned(
      left: 48,
      right: 48,
      bottom: 44 + padding.bottom,
      child: Opacity(
        opacity: reveal,
        child: Column(
          children: [
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: reveal,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primaryLight, _accent],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(reveal * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primary.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

/// 动态 Mesh 渐变背景
class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.progress,
    required this.breathe,
    required this.primary,
    required this.accent,
  });

  final double progress;
  final double breathe;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide * 0.8;

    // 主光晕
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.06 * progress),
          primary.withValues(alpha: 0.02 * progress),
          Colors.transparent,
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx + math.sin(breathe * math.pi) * 20, cy - maxR * 0.3),
        radius: maxR,
      ));
    canvas.drawCircle(
      Offset(cx + math.sin(breathe * math.pi) * 20, cy - maxR * 0.3),
      maxR,
      p1,
    );

    // 强调光晕
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.04 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx - 60, cy + maxR * 0.4),
        radius: maxR * 0.6,
      ));
    canvas.drawCircle(
      Offset(cx - 60, cy + maxR * 0.4),
      maxR * 0.6,
      p2,
    );
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter old) =>
      old.progress != progress || old.breathe != breathe;
}

/// 粒子场
class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({
    required this.progress,
    required this.fade,
    required this.primary,
    required this.accent,
  });

  final double progress;
  final double fade;
  final Color primary;
  final Color accent;

  static final _seeds = List.generate(30, (i) => _ParticleSeed(i));

  @override
  void paint(Canvas canvas, Size size) {
    if (fade <= 0) return;

    for (final seed in _seeds) {
      final x = seed.x * size.width;
      final baseY = seed.y * size.height;
      final speed = seed.speed;
      final r = seed.radius;
      final isAccent = seed.isAccent;

      // 浮动轨迹
      final y = (baseY - progress * speed * 150 + size.height) % size.height;
      final wobble = math.sin(progress * math.pi * 2 * seed.wobbleFreq + seed.phase) * 8;
      
      // 透明度衰减
      final normalizedY = y / size.height;
      final fadeEdge = (1.0 - ((normalizedY - 0.5).abs() * 2).clamp(0.0, 1.0));
      final alpha = fade * fadeEdge * seed.alpha;

      final paint = Paint()
        ..color = (isAccent ? accent : primary).withValues(alpha: alpha);

      canvas.drawCircle(Offset(x + wobble, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter old) =>
      old.progress != progress || old.fade != fade;
}

class _ParticleSeed {
  _ParticleSeed(int i)
      : x = _hash(i, 0) * 1.0,
        y = _hash(i, 1) * 1.0,
        speed = 0.4 + _hash(i, 2) * 0.8,
        radius = 1.2 + _hash(i, 3) * 2.8,
        alpha = 0.08 + _hash(i, 4) * 0.18,
        wobbleFreq = 0.5 + _hash(i, 5) * 1.5,
        phase = _hash(i, 6) * math.pi * 2,
        isAccent = _hash(i, 7) > 0.7;

  final double x, y, speed, radius, alpha, wobbleFreq, phase;
  final bool isAccent;

  static double _hash(int i, int salt) {
    final v = (i * 2654435761 + salt * 2246822519) & 0xFFFFFFFF;
    return (v % 10000) / 10000.0;
  }
}

/// 渐变环
class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter({
    required this.progress,
    required this.breathe,
    required this.primary,
    required this.accent,
  });

  final double progress;
  final double breathe;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - 4;

    // 基础环
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = primary.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, bgPaint);

    // 渐变弧
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          primary.withValues(alpha: 0.05),
          primary,
          accent,
          primary.withValues(alpha: 0.05),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );

    // 发光尾迹
    if (progress > 0.02) {
      final angle = -math.pi / 2 + math.pi * 2 * progress;
      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;

      // 光晕
      final glowPaint = Paint()
        ..color = primary.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dx, dy), 4, glowPaint);

      // 实点
      final dotPaint = Paint()..color = primary;
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter old) =>
      old.progress != progress || old.breathe != breathe;
}

/// 光线扫过
class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress, required this.primary});

  final double progress;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final x = size.width * (progress * 1.6 - 0.3);
    final gradientWidth = size.width * 0.15;

    final rect = Rect.fromLTWH(x - gradientWidth, 0, gradientWidth * 2, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          primary.withValues(alpha: 0.04),
          primary.withValues(alpha: 0.08),
          primary.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Easing helpers
// ─────────────────────────────────────────────────────────────────────────────

double _ease(double v, double s, double e) {
  if (v <= s) return 0;
  if (v >= e) return 1;
  return Curves.easeOutCubic.transform(((v - s) / (e - s)).clamp(0.0, 1.0));
}

double _spring(double v, double s, double e) {
  if (v <= s) return 0;
  if (v >= e) return 1;
  final t = ((v - s) / (e - s)).clamp(0.0, 1.0);
  // Spring with slight overshoot
  const spring = SpringDescription(mass: 1.0, stiffness: 180.0, damping: 12.0);
  final sim = SpringSimulation(spring, 0, 1, 0);
  return sim.x(t) / sim.x(1.0);
}
