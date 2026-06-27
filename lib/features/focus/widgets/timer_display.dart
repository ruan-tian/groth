import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../utils/focus_assets.dart';

class TimerDisplay extends StatefulWidget {
  const TimerDisplay({
    super.key,
    required this.remaining,
    required this.total,
    this.isBreak = false,
    this.size = 280,
    this.dark = false,
    this.roundLabel,
    this.title,
    this.subject,
    this.showTitle = false,
    this.catAsset,
    this.showCat = true,
    this.accentColor,
    this.glassOpacityLevel = 2,
  });

  final Duration remaining;
  final Duration total;
  final bool isBreak;
  final double size;
  final bool dark;
  final String? roundLabel;
  final String? title;
  final String? subject;
  final bool showTitle;
  final String? catAsset;
  final bool showCat;
  final Color? accentColor;
  final int glassOpacityLevel;

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breatheAnimation = Tween<double>(begin: 1, end: 1.035).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _breatheController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final totalSeconds = widget.total.inSeconds;
    final progress = totalSeconds > 0
        ? (widget.remaining.inSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();
    final themeAccent = widget.accentColor ?? colors.focus;
    final accent = widget.isBreak
        ? Color.lerp(themeAccent, colors.success, 0.28)!
        : progress > 0.25
        ? themeAccent
        : Color.lerp(themeAccent, colors.warning, 0.44)!;
    final isDarkTheme = themeAccent.computeLuminance() < 0.18;
    final ringAccent = isDarkTheme ? const Color(0xFF111827) : accent;
    final ringBaseColor = isDarkTheme
        ? const Color(0xFF111827)
        : Color.lerp(colors.border, themeAccent, 0.16)!;
    final ringFillColor = widget.dark
        ? Color.lerp(
            colors.card,
            themeAccent,
            isDarkTheme ? 0.08 : 0.04,
          )!.withValues(alpha: isDarkTheme ? 0.30 : 0.25)
        : colors.paper.withValues(alpha: 0.34);
    final glassTint = widget.dark
        ? Color.lerp(
            colors.card,
            themeAccent,
            isDarkTheme ? 0.10 : 0.04,
          )!.withValues(alpha: isDarkTheme ? 0.26 : 0.22)
        : colors.paper.withValues(alpha: 0.28);
    final tickColor = isDarkTheme
        ? const Color(0xFF111827).withValues(alpha: 0.20)
        : colors.textSecondary.withValues(alpha: 0.18);
    final ringGradient = _timerRingGradient(
      themeAccent: themeAccent,
      activeAccent: ringAccent,
      warning: colors.warning,
      isBreak: widget.isBreak,
      isDarkTheme: isDarkTheme,
    );
    final glassAlpha = _timerGlassAlpha(widget.glassOpacityLevel);

    final content = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            widget.isBreak ? FocusAssets.restGlow : FocusAssets.ringGlow,
            width: widget.size * 1.1,
            height: widget.size * 1.1,
            fit: BoxFit.contain,
            opacity: const AlwaysStoppedAnimation(0.62),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                width: widget.size - 54,
                height: widget.size - 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glassTint.withValues(alpha: glassAlpha),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: (glassAlpha + 0.18).clamp(0.0, 0.72),
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: widget.size * 0.08,
                      spreadRadius: widget.size * 0.008,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.14),
                      blurRadius: widget.size * 0.05,
                      spreadRadius: -widget.size * 0.025,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _breatheController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.square(widget.size),
                painter: _LiquidGlassPainter(
                  accent: ringAccent,
                  phase: _breatheController.value,
                  darkTheme: isDarkTheme,
                  glassOpacity: glassAlpha,
                ),
              );
            },
          ),
          CustomPaint(
            size: Size.square(widget.size),
            painter: _TimerRingPainter(
              progress: progress,
              accent: ringAccent,
              dark: widget.dark,
              isBreak: widget.isBreak,
              baseColor: ringBaseColor,
              fillColor: ringFillColor,
              tickColor: tickColor,
              gradientColors: ringGradient,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题 — 仅操作模式
              AnimatedOpacity(
                opacity: widget.showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: widget.showTitle
                      ? Offset.zero
                      : const Offset(0, -0.3),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: widget.showTitle
                      ? Padding(
                          padding: EdgeInsets.only(bottom: widget.size * 0.015),
                          child: Text(
                            widget.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: widget.size * 0.052,
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // 轮次
              Text(
                widget.roundLabel ?? '',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: widget.showTitle
                      ? widget.size * 0.038
                      : widget.size * 0.045,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: widget.showTitle
                    ? widget.size * 0.015
                    : widget.size * 0.02,
              ),
              // 时间
              Text(
                _formatTime(widget.remaining),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: widget.showTitle
                      ? widget.size * 0.16
                      : widget.size * 0.18,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(
                height: widget.showTitle
                    ? widget.size * 0.025
                    : widget.size * 0.03,
              ),
              // 百分比胶囊
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size * 0.046,
                  vertical: widget.size * 0.014,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: widget.dark ? 0.18 : 0.13),
                  borderRadius: BorderRadius.circular(widget.size * 0.07),
                  border: Border.all(color: accent.withValues(alpha: 0.36)),
                ),
                child: Text(
                  widget.isBreak ? '休息中' : '$percent%',
                  style: TextStyle(
                    color: accent,
                    fontSize: widget.showTitle
                        ? widget.size * 0.042
                        : widget.size * 0.045,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // 科目标签 — 仅操作模式
              AnimatedOpacity(
                opacity: widget.showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: widget.showTitle ? Offset.zero : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: widget.showTitle && widget.subject != null
                      ? Padding(
                          padding: EdgeInsets.only(top: widget.size * 0.025),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.size * 0.035,
                              vertical: widget.size * 0.012,
                            ),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(
                                widget.size * 0.07,
                              ),
                              border: Border.all(
                                color: colors.success.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              widget.subject!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.success,
                                fontSize: widget.size * 0.035,
                                height: 1.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // 猫图
              if (widget.showCat && widget.catAsset != null)
                Padding(
                  padding: EdgeInsets.only(
                    top: widget.showTitle
                        ? widget.size * 0.03
                        : widget.size * 0.04,
                  ),
                  child: Image.asset(
                    widget.catAsset!,
                    width: widget.showTitle
                        ? widget.size * 0.14
                        : widget.size * 0.16,
                    height: widget.showTitle
                        ? widget.size * 0.14
                        : widget.size * 0.16,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!widget.isBreak) return content;
    return AnimatedBuilder(
      animation: _breatheAnimation,
      child: content,
      builder: (context, child) {
        return Transform.scale(scale: _breatheAnimation.value, child: child);
      },
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

double _timerGlassAlpha(int level) {
  switch (level.clamp(0, 3)) {
    case 0:
      return 0.14;
    case 1:
      return 0.20;
    case 2:
      return 0.28;
    default:
      return 0.38;
  }
}

List<Color> _timerRingGradient({
  required Color themeAccent,
  required Color activeAccent,
  required Color warning,
  required bool isBreak,
  required bool isDarkTheme,
}) {
  if (isDarkTheme) {
    return const [
      Color(0xFF05070A),
      Color(0xFF111827),
      Color(0xFF2A3441),
      Color(0xFF05070A),
    ];
  }
  if (isBreak) {
    return [
      Color.lerp(themeAccent, Colors.white, 0.18)!,
      Color.lerp(themeAccent, const Color(0xFF71B79A), 0.30)!,
      activeAccent,
      Color.lerp(themeAccent, Colors.black, 0.10)!,
    ];
  }
  return [
    Color.lerp(themeAccent, Colors.black, 0.10)!,
    activeAccent,
    Color.lerp(themeAccent, Colors.white, 0.24)!,
    Color.lerp(activeAccent, warning, 0.10)!,
  ];
}

class _LiquidGlassPainter extends CustomPainter {
  const _LiquidGlassPainter({
    required this.accent,
    required this.phase,
    required this.darkTheme,
    required this.glassOpacity,
  });

  final Color accent;
  final double phase;
  final bool darkTheme;
  final double glassOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 54) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final drift = (phase - 0.5) * 0.18;

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          Colors.white.withValues(alpha: darkTheme ? 0.50 : 0.62),
          accent.withValues(alpha: (glassOpacity * 0.72).clamp(0.08, 0.30)),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: darkTheme ? 0.50 : 0.62),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, edgePaint);

    final topHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, size.width * 0.006)
      ..color = Colors.white.withValues(
        alpha: (glassOpacity + (darkTheme ? 0.10 : 0.18)).clamp(0.18, 0.58),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 9),
      -math.pi * (0.86 + drift),
      math.pi * 0.36,
      false,
      topHighlight,
    );

    final refractPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, size.width * 0.0035)
      ..color = accent.withValues(
        alpha: (glassOpacity * 0.64).clamp(0.10, 0.26),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 24),
      math.pi * (0.02 + drift),
      math.pi * 0.42,
      false,
      refractPaint,
    );

    final dropletPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: darkTheme ? 0.28 : 0.36),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: center + Offset(-radius * 0.36, -radius * 0.38),
              radius: radius * 0.34,
            ),
          );
    canvas.drawCircle(
      center + Offset(-radius * 0.36, -radius * 0.38),
      radius * 0.34,
      dropletPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.phase != phase ||
        oldDelegate.darkTheme != darkTheme ||
        oldDelegate.glassOpacity != glassOpacity;
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.accent,
    required this.dark,
    required this.isBreak,
    required this.baseColor,
    required this.fillColor,
    required this.tickColor,
    required this.gradientColors,
  });

  final double progress;
  final Color accent;
  final bool dark;
  final bool isBreak;
  final Color baseColor;
  final Color fillColor;
  final Color tickColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 38) / 2;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 8, fillPaint);

    final outerHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius + 7, outerHighlight);

    final innerHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 13, innerHighlight);

    final bgPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: isBreak ? 0.24 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      glowPaint,
    );

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: gradientColors,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );

    if (dark) {
      final tickPaint = Paint()
        ..color = tickColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 24; i++) {
        final angle = -math.pi / 2 + i * math.pi * 2 / 24;
        final inner = radius - (i % 3 == 0 ? 17 : 10);
        final outer = radius - 4;
        canvas.drawLine(
          center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.dark != dark ||
        oldDelegate.isBreak != isBreak ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
