import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// 庆祝动效覆盖层
///
/// 用于等级提升、达成目标等关键时刻的庆祝动画。
///
/// 用法：
/// ```dart
/// CelebrationOverlay(
///   message: '等级提升！',
///   subMessage: 'Lv.5 成长实践家',
///   onComplete: () {
///     // 动画完成后的回调
///   },
/// )
/// ```
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.message,
    this.subMessage,
    this.onComplete,
  });

  final String message;
  final String? subMessage;
  final VoidCallback? onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    // 启动动画
    _confettiController.play();
    _textController.forward();

    // 自动关闭
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // 彩纸效果
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF5D68F2),
                Color(0xFF35C976),
                Color(0xFFFF8A3D),
                Color(0xFFFF7EAA),
                Color(0xFFFFD700),
              ],
              numberOfParticles: 50,
              gravity: 0.3,
            ),
          ),
          // 文字动画
          Center(
            child: AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _textAnimation.value,
                  child: Opacity(
                    opacity: _textAnimation.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: context.growthColors.textOnAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.subMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subMessage!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.growthColors.textOnAccent
                                  .withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
