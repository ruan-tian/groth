import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/pet_orchestrator_provider.dart';
import '../../../shared/providers/pet_projection_provider.dart';
import '../../../core/constants/pet_assets.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

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
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
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

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 238),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0E5F4)),
        boxShadow: [
          BoxShadow(
            color: _DashboardHeroColors.primary.withValues(alpha: 0.11),
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
              right: 18,
              top: 18,
              child: Image.asset(
                PetCenterAssets.particleSparkle,
                width: 28,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 20,
              child: Image.asset(
                PetCenterAssets.decoPlant,
                width: 42,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
                          color: _DashboardHeroColors.ink,
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
                        style: const TextStyle(
                          color: _DashboardHeroColors.muted,
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
                      const SizedBox(height: 18),
                      _GrowthSummary(data: data),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetImage(String imagePath) {
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
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF1E8F5)),
                  boxShadow: [
                    BoxShadow(
                      color: _DashboardHeroColors.primary.withValues(
                        alpha: 0.12,
                      ),
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
                      color: const Color(0xFFFFF7FB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets_rounded,
                        color: _DashboardHeroColors.primary,
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
    return GestureDetector(
      onTap: () => _showFullMessage(context, bubbleText),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0E8F5)),
          boxShadow: [
            BoxShadow(
              color: _DashboardHeroColors.primary.withValues(alpha: 0.08),
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
                const Text(
                  '甜甜',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _DashboardHeroColors.ink,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.touch_app_rounded,
                  size: 12,
                  color: _DashboardHeroColors.muted.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                bubbleText,
                key: ValueKey(bubbleText),
                style: const TextStyle(
                  fontSize: 13,
                  color: _DashboardHeroColors.text,
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
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFF4F8),
                  Color(0xFFF2F5E8),
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

class _GrowthSummary extends ConsumerWidget {
  const _GrowthSummary({required this.data});

  final DashboardData? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expService = ref.watch(expServiceProvider);
    final level = data?.currentLevel ?? 1;
    final totalExp = data?.totalExp ?? 0;
    final levelProgress = expService.calculateLevelProgress(totalExp);
    final remaining = levelProgress.expRemaining;
    final progress = levelProgress.progressRatio;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E8F5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _LevelBadge(level: level),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv.$level 成长进行中',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DashboardHeroColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalExp EXP · 下一级还差 $remaining',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DashboardHeroColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _TinyMetric(
                value: '${data?.todayStudyMinutes ?? 0}',
                label: '学习',
              ),
              const SizedBox(width: 8),
              _TinyMetric(
                value: '${data?.todayJournalCount ?? 0} 篇',
                label: '日记',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFEDE7FA),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _DashboardHeroColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA695FF), _DashboardHeroColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _DashboardHeroColors.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD58D31),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _DashboardHeroColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroColors {
  static const primary = Color(0xFF8B75F6);
  static const ink = Color(0xFF37314E);
  static const text = Color(0xFF5C5670);
  static const muted = Color(0xFF8D869A);
}

class _PetMessageSheet extends StatelessWidget {
  const _PetMessageSheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: const Color(0xFFE0E0E0),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB8A9FF), Color(0xFF8B75F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B75F6).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🐱',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '甜甜',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF37314E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '你的成长伙伴',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF8D869A).withValues(alpha: 0.8),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF8D869A),
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
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8F5FF),
                          const Color(0xFFFFF8F0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEDEBFF),
                        width: 1.5,
                      ),
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
                                color: const Color(0xFF8B75F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: Color(0xFF8B75F6),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '甜甜说',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8B75F6),
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
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF37314E),
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
                        color: const Color(0xFF8D869A).withValues(alpha: 0.6),
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
