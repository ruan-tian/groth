import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../shared/providers/pet_orchestrator_v2_provider.dart';

/// Dashboard 顶部宠物组件
///
/// 正方形宠物图片 + 气泡说话框 + 渐变线。
/// 点击进入宠物中心 (/pet-center)。
class DashboardPetWidget extends ConsumerStatefulWidget {
  const DashboardPetWidget({super.key});

  @override
  ConsumerState<DashboardPetWidget> createState() =>
      _DashboardPetWidgetState();
}

class _DashboardPetWidgetState extends ConsumerState<DashboardPetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  Timer? _messageRotationTimer;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _messageRotationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _messageRotationTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intentAsync = ref.watch(dashboardPetIntentProvider);

    return GestureDetector(
      onTap: () => context.push('/pet-center'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: intentAsync.when(
          loading: () => _buildContent(
            imagePath: 'assets/pet/common/common_happy.png',
            message: '甜甜在这里陪你～',
          ),
          error: (_, __) => _buildContent(
            imagePath: 'assets/pet/common/common_happy.png',
            message: '甜甜在这里陪你～',
          ),
          data: (intent) => _buildContent(
            imagePath: intent.imagePath,
            message: intent.displayMessage,
            fallbackEmoji: '🐱',
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required String imagePath,
    required String message,
    String fallbackEmoji = '🐱',
  }) {
    return Column(
      children: [
        Row(
          children: [
            _buildPetImage(imagePath, fallbackEmoji),
            const SizedBox(width: 14),
            Expanded(child: _buildSpeechBubble(message)),
          ],
        ),
        const SizedBox(height: 16),
        _buildGradientLine(),
      ],
    );
  }

  Widget _buildPetImage(String imagePath, String fallbackEmoji) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外层柔光
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4A574).withValues(alpha: 0.2),
                    const Color(0xFFD4A574).withValues(alpha: 0.05),
                    const Color(0xFFD4A574).withValues(alpha: 0.0),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
            // 白色底衬（正方形圆角）
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4A574).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            // 宠物图片
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6D0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🐱', style: TextStyle(fontSize: 40)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(String bubbleText) {
    return CustomPaint(
      painter: _BubbleTailPainter(),
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A574).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '甜甜',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C3D2E),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                bubbleText,
                key: ValueKey(bubbleText),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B6F5E),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientLine() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD4A574),
            Color(0xFFE8C9A0),
            Color(0xFFF5E6D0),
          ],
        ),
      ),
    );
  }
}

/// 气泡尾巴画笔
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..lineTo(-8, size.height * 0.5)
      ..lineTo(0, size.height * 0.6)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
