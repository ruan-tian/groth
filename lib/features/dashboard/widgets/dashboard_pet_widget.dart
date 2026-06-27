import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/dashboard_deco_assets.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../pet/providers/pet_orchestrator_provider.dart';
import '../../pet/providers/pet_projection_provider.dart';
import '../../../core/constants/pet_assets.dart';
import '../../../features/fitness/utils/fitness_timer_assets.dart';

/// 首页甜甜成长主卡。
///
/// 只消费现有 dashboard/pet 投影数据，不改变宠物状态或首页业务逻辑。
class DashboardPetWidget extends ConsumerStatefulWidget {
  const DashboardPetWidget({super.key, this.data});

  final DashboardData? data;

  @override
  ConsumerState<DashboardPetWidget> createState() => _DashboardPetWidgetState();
}

class _DashboardPetWidgetState extends ConsumerState<DashboardPetWidget>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  // 装饰图标轮换
  int _decoIndex = 0;
  late final AnimationController _rotateController;
  late final Animation<double> _rotateAnimation;

  // 彩蛋弹幕
  int _switchCount = 0;
  OverlayEntry? _barrageEntry;
  static const _barrageThreshold = 5;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _floatAnimation = Tween<double>(begin: -4, end: 0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeOutCubic),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _barrageEntry?.remove();
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _cycleDecoration() {
    if (_rotateController.isAnimating) return;
    _rotateController.forward(from: 0).then((_) {
      if (!mounted) return;
      var shouldTriggerBarrage = false;
      setState(() {
        _decoIndex = ((_decoIndex + 1) % DashboardDecoAssets.all.length)
            .toInt();
        _switchCount++;
        shouldTriggerBarrage = _switchCount >= _barrageThreshold;
        if (shouldTriggerBarrage) _switchCount = 0;
      });
      if (shouldTriggerBarrage) {
        _triggerBarrage();
      }
    });
  }

  void _triggerBarrage() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final allMessages = List<List<String>>.from(
      DashboardDecoAssets.barrageMessages,
    );
    for (var i = allMessages.length - 1; i > 0; i--) {
      final j = (random + i * 7) % (i + 1);
      final temp = allMessages[i];
      allMessages[i] = allMessages[j];
      allMessages[j] = temp;
    }
    final count = 8 + (random % 4);
    final selected = allMessages.take(count).toList();

    final items = <_BarrageItem>[];
    for (var i = 0; i < selected.length; i++) {
      items.add(
        _BarrageItem(
          iconPath: selected[i][0],
          message: selected[i][1],
          startX: 0.05 + ((random + i * 41) % 74) / 100.0,
          delay: Duration(milliseconds: i * 220),
          duration: Duration(milliseconds: 5600 + (random + i * 17) % 900),
        ),
      );
    }

    _barrageEntry?.remove();
    _barrageEntry = OverlayEntry(
      builder: (context) {
        return _DashboardEasterEggOverlay(
          items: items,
          seed: random,
          onFinished: () {
            _barrageEntry?.remove();
            _barrageEntry = null;
          },
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_barrageEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final intentAsync = ref.watch(dashboardPetIntentProvider);
    final projection = ref.watch(dashboardPetViewProvider);

    return intentAsync.when(
      loading: () =>
          _buildContent(imagePath: PetAssets.commonHappy, message: '甜甜在这里陪你～'),
      error: (_, _) =>
          _buildContent(imagePath: PetAssets.commonHappy, message: '甜甜在这里陪你～'),
      data: (intent) => _buildContent(
        imagePath: intent.imagePath,
        message: projection?.bubbleText ?? intent.displayMessage,
      ),
    );
  }

  Widget _buildContent({required String imagePath, required String message}) {
    final data = widget.data;
    final colors = context.growthColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 主卡片
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.11),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(29),
            child: Stack(
              children: [
                const Positioned.fill(child: _HeroBackground()),
                Positioned(
                  right: 16,
                  top: 16,
                  child: GestureDetector(
                    onTap: _cycleDecoration,
                    child: AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value * 2 * 3.14159,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        DashboardDecoAssets.all[_decoIndex],
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 350;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '你的成长，由你掌控',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: compact ? 22 : 24,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _summaryLine(data),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/pet-center'),
                                child: _buildPetImage(imagePath),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: _buildSpeechBubble(message)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetImage(String imagePath) {
    final colors = context.growthColors;
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 2,
              child: Image.asset(
                PetCenterAssets.softShadow,
                width: 86,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Image.asset(
                imagePath,
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.pets_rounded,
                        color: colors.primary,
                        size: 36,
                      ),
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
    final colors = context.growthColors;
    return GestureDetector(
      onTap: () => _showFullMessage(context, bubbleText),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '甜甜',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.touch_app_rounded, size: 12, color: colors.textHint),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                bubbleText,
                key: ValueKey(bubbleText),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
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

  void _showFullMessage(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PetMessageSheet(message: message),
    );
  }

  String _summaryLine(DashboardData? data) {
    if (data == null) return '今天也和甜甜一起慢慢变好';
    final active = <String>[];
    if (data.todayStudyMinutes > 0) {
      active.add('学习 ${data.todayStudyMinutes} 分');
    }
    if (data.todayFitnessMinutes > 0) {
      active.add('健身 ${data.todayFitnessMinutes} 分');
    }
    if (data.todayJournalCount > 0) {
      active.add('日记 ${data.todayJournalCount} 篇');
    }
    if (data.todayFocusMinutes > 0) {
      active.add('专注 ${data.todayFocusMinutes} 分');
    }
    if (active.isEmpty) return '今天也和甜甜一起慢慢变好';
    return active.take(2).join(' · ');
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.card,
                  colors.softPink.withValues(alpha: 0.3),
                  colors.surface,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 56,
          bottom: 24,
          child: Image.asset(
            PetCenterAssets.decoStar,
            width: 34,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _PetMessageSheet extends StatelessWidget {
  const _PetMessageSheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽条
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 内容区域
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像和名称
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            FitnessTimerAssets.catAvatarDefault,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '甜甜',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '你的成长伙伴',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 关闭按钮
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 消息气泡
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.study.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: colors.study,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '甜甜说',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.study,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 底部提示
                  Center(
                    child: Text(
                      '点击空白处关闭',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹幕条目数据
class _BarrageItem {
  const _BarrageItem({
    required this.iconPath,
    required this.message,
    required this.startX,
    required this.delay,
    required this.duration,
  });

  final String iconPath;
  final String message;
  final double startX;
  final Duration delay;
  final Duration duration;
}

class _DashboardEasterEggOverlay extends StatefulWidget {
  const _DashboardEasterEggOverlay({
    required this.items,
    required this.seed,
    required this.onFinished,
  });

  final List<_BarrageItem> items;
  final int seed;
  final VoidCallback onFinished;

  @override
  State<_DashboardEasterEggOverlay> createState() =>
      _DashboardEasterEggOverlayState();
}

class _DashboardEasterEggOverlayState extends State<_DashboardEasterEggOverlay>
    with SingleTickerProviderStateMixin {
  static const _totalDurationMs = 7400;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: _totalDurationMs),
          )
          ..forward()
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onFinished();
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _fade(double value) {
    if (value < 0.12) return value / 0.12;
    if (value > 0.84) return (1 - value) / 0.16;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = reduceMotion ? 1.0 : _controller.value;
            final opacity = reduceMotion
                ? 1.0
                : _fade(progress).clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.45, -0.42),
                        radius: 1.08,
                        colors: [
                          colors.primaryLight.withValues(alpha: 0.18),
                          colors.softPink.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.42, 1],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _EasterEggParticlePainter(
                      progress: progress,
                      seed: widget.seed,
                      primary: colors.primary,
                      gold: colors.softGold,
                    ),
                  ),
                  for (var i = 0; i < widget.items.length; i++)
                    _FullScreenBarrageChip(
                      item: widget.items[i],
                      index: i,
                      progress: progress,
                      totalDurationMs: _totalDurationMs,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FullScreenBarrageChip extends StatelessWidget {
  const _FullScreenBarrageChip({
    required this.item,
    required this.index,
    required this.progress,
    required this.totalDurationMs,
  });

  final _BarrageItem item;
  final int index;
  final double progress;
  final int totalDurationMs;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final local =
        ((progress * totalDurationMs) - item.delay.inMilliseconds) /
        item.duration.inMilliseconds;
    if (local <= 0 || local >= 1) return const SizedBox.shrink();

    final curve = Curves.easeOutCubic.transform(local.clamp(0.0, 1.0));
    final opacity = local < 0.18
        ? local / 0.18
        : local > 0.82
        ? (1 - local) / 0.18
        : 1.0;
    final lane = (index % 8) / 7.0;
    final startY = size.height * (0.88 - lane * 0.76);
    final driftY = -size.height * (0.24 + (index % 3) * 0.045);
    final wave = math.sin((curve + index * 0.23) * math.pi * 2) * 26;
    final maxChipWidth = (size.width * 0.68).clamp(210.0, 360.0).toDouble();
    final x = (item.startX * size.width + wave)
        .clamp(12.0, math.max(12.0, size.width - maxChipWidth - 18))
        .toDouble();
    final y = startY + driftY * curve;
    final scale = 0.98 + 0.05 * math.sin(curve * math.pi);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                item.iconPath,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: context.growthColors.primaryLight.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.growthColors.primary.withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  item.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: context.growthColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EasterEggParticlePainter extends CustomPainter {
  const _EasterEggParticlePainter({
    required this.progress,
    required this.seed,
    required this.primary,
    required this.gold,
  });

  final double progress;
  final int seed;
  final Color primary;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 34; i++) {
      final base = (seed % 997 + i * 53) / 997.0;
      final phase = (progress + base) % 1;
      final x = ((base * 1.73) % 1) * size.width;
      final y = (1.08 - phase * 1.2) * size.height;
      final sway = math.sin((phase + i * 0.13) * math.pi * 2) * 20;
      final radius = 1.8 + (i % 4) * 0.9;
      final fade = phase < 0.12
          ? phase / 0.12
          : phase > 0.82
          ? (1 - phase) / 0.18
          : 1.0;
      paint.color = Color.lerp(
        primary,
        gold,
        (i % 5) / 8,
      )!.withValues(alpha: 0.065 * fade.clamp(0.0, 1.0));

      final center = Offset(x + sway, y);
      if (i.isEven) {
        _drawSpark(canvas, center, radius * 2.2, paint);
      } else {
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  void _drawSpark(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.28, center.dy - size * 0.28)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx + size * 0.28, center.dy + size * 0.28)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.28, center.dy + size * 0.28)
      ..lineTo(center.dx - size, center.dy)
      ..lineTo(center.dx - size * 0.28, center.dy - size * 0.28)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EasterEggParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seed != seed ||
        oldDelegate.primary != primary ||
        oldDelegate.gold != gold;
  }
}
