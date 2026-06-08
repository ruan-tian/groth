import 'package:flutter/material.dart';

/// 番茄钟计时器显示（CustomPainter 版本）
///
/// 支持专注/休息双状态：
/// - 专注：蓝绿色 → 橙色 → 红色渐变
/// - 休息：绿色呼吸动画
class TimerDisplay extends StatefulWidget {
  final Duration remaining;
  final Duration total;
  final bool isBreak;

  const TimerDisplay({
    super.key,
    required this.remaining,
    required this.total,
    this.isBreak = false,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breatheAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));

    if (widget.isBreak) {
      _breatheController.repeat(reverse: true);
    }
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

  String _formatTime(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _progressColor(double progress) {
    if (widget.isBreak) return const Color(0xFF059669);
    if (progress > 0.5) return const Color(0xFF00897B);
    if (progress > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.total.inSeconds;
    final progress = totalSeconds > 0
        ? (widget.remaining.inSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final color = _progressColor(progress);
    final percent = (progress * 100).toInt();

    Widget ring = SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _TimerRingPainter(
          progress: progress,
          color: color,
          isBreak: widget.isBreak,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(widget.remaining),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isBreak ? '休息一下' : '$percent%',
                style: TextStyle(
                  fontSize: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isBreak) {
      return AnimatedBuilder(
        animation: _breatheAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _breatheAnimation.value,
            child: child,
          );
        },
        child: ring,
      );
    }

    return ring;
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isBreak;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.isBreak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159265 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect for break
    if (isBreak && progress > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265 / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isBreak != isBreak;
  }
}
