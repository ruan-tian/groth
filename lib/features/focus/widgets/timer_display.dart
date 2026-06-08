import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

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
    this.catAsset,
    this.showCat = true,
  });

  final Duration remaining;
  final Duration total;
  final bool isBreak;
  final double size;
  final bool dark;
  final String? roundLabel;
  final String? catAsset;
  final bool showCat;

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
    if (widget.isBreak) _breatheController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBreak && !_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    } else if (!widget.isBreak && _breatheController.isAnimating) {
      _breatheController.stop();
      _breatheController.reset();
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.total.inSeconds;
    final progress = totalSeconds > 0
        ? (widget.remaining.inSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();
    final accent = widget.isBreak
        ? const Color(0xFF9DEECF)
        : progress > 0.25
            ? const Color(0xFF9DEBD8)
            : const Color(0xFFFF8D76);
    final textColor = widget.dark ? const Color(0xFFF8E8C8) : const Color(0xFF2C3938);

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
            opacity: const AlwaysStoppedAnimation(0.72),
          ),
          CustomPaint(
            size: Size.square(widget.size),
            painter: _TimerRingPainter(
              progress: progress,
              accent: accent,
              dark: widget.dark,
              isBreak: widget.isBreak,
            ),
          ),
          if (widget.showCat)
            Positioned(
              top: widget.size * 0.22,
              child: Image.asset(
                widget.catAsset ?? FocusAssets.catReading,
                width: widget.size * 0.24,
                height: widget.size * 0.24,
                fit: BoxFit.contain,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: widget.showCat ? widget.size * 0.12 : 0),
              Text(
                widget.roundLabel ?? '',
                style: TextStyle(
                  color: widget.dark
                      ? const Color(0xFFE8DFC6)
                      : const Color(0xFF6D7B78),
                  fontSize: widget.size * 0.052,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: widget.size * 0.02),
              Text(
                _formatTime(widget.remaining),
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.size * 0.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: widget.size * 0.04),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size * 0.055,
                  vertical: widget.size * 0.018,
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
                    fontSize: widget.size * 0.052,
                    fontWeight: FontWeight.w800,
                  ),
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

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.accent,
    required this.dark,
    required this.isBreak,
  });

  final double progress;
  final Color accent;
  final bool dark;
  final bool isBreak;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 34) / 2;
    final baseColor = dark ? const Color(0xFF38545A) : const Color(0xFFE8EFEA);

    final fillPaint = Paint()
      ..color = dark
          ? const Color(0xAA082B35)
          : Colors.white.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 8, fillPaint);

    final bgPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: isBreak ? 0.28 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
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
        colors: const [
          Color(0xFF9DEBD8),
          Color(0xFF78DCC8),
          Color(0xFFFF8D76),
          Color(0xFF9DEBD8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.tau * progress,
      false,
      progressPaint,
    );

    if (dark) {
      final tickPaint = Paint()
        ..color = const Color(0x66E9DDC7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 48; i++) {
        final angle = -math.pi / 2 + i * math.pi * 2 / 48;
        final inner = radius - (i % 4 == 0 ? 20 : 12);
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
        oldDelegate.isBreak != isBreak;
  }
}
