import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../shared/constants/scenery_theme_catalog.dart';
import '../health/models/drink_recommendation.dart';
import 'providers/dashboard_provider.dart';
import '../../shared/widgets/common/growth_calendar_sheet.dart';
import '../music/widgets/dashboard_music_float.dart';
import 'widgets/dashboard_pet_widget.dart';
import 'widgets/dashboard_weather_badge.dart';
import 'widgets/dashboard_knowledge_summary.dart';
import 'widgets/quick_action_sheet.dart';
import 'widgets/today_overview.dart';
import 'widgets/today_tasks.dart';

// =============================================================================
// Dashboard Page
// =============================================================================

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final colors = context.growthColors;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.background, colors.paper, colors.background],
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: dashboardAsync.when(
                      loading: () => const _LoadingBody(),
                      error: (error, _) => _ErrorBody(
                        error: error,
                        onRetry: () => ref.invalidate(dashboardProvider),
                      ),
                      data: (data) => RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(dashboardProvider),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardPetWidget(data: data),
                              const SizedBox(height: 22),
                              _buildTodayOverview(ref, data),
                              const SizedBox(height: 14),
                              const TodayTasks(),
                              const SizedBox(height: 16),
                              const DashboardKnowledgeSummaryCard(),
                              const SizedBox(height: 12),
                              const _DashboardDrinkInspirationCard(),
                              const SizedBox(height: 12),
                              const _DashboardInspirationBookmarkCard(),
                              const SizedBox(height: 12),
                              const _DashboardSceneryCard(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DashboardMusicFloat(),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: '打开快速开始菜单',
        child: Tooltip(
          message: '快速开始',
          child: GestureDetector(
            onTap: () => _showQuickActions(context),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.card.withValues(alpha: 0.55),
                          colors.primaryLight.withValues(alpha: 0.18),
                        ],
                      ),
                      border: Border.all(
                        color: colors.textOnAccent.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.textOnAccent.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 顶部：标题、问候、日期和天气入口
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final colors = context.growthColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth OS',
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeaderChip(
                      icon: Icons.waving_hand_rounded,
                      label: _greeting(now.hour),
                    ),
                    _HeaderChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}',
                      tooltip: '打开日历',
                      onTap: () =>
                          showGrowthCalendarSheet(context, initialDate: now),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const DashboardWeatherBadge(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 今日概览（使用新的 TodayOverview 组件）
  // ---------------------------------------------------------------------------

  Widget _buildTodayOverview(WidgetRef ref, DashboardData data) {
    return const TodayOverview();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _greeting(int hour) {
    if (hour < 12) return '早上好，开始生长';
    if (hour < 18) return '下午好，稳稳推进';
    return '晚上好，认真复盘';
  }

  void _showQuickActions(BuildContext context) {
    QuickActionSheet.show(context);
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: colors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return chip;

    return Tooltip(
      message: tooltip!,
      child: Semantics(button: onTap != null, child: chip),
    );
  }
}

class _DashboardDrinkInspirationCard extends StatelessWidget {
  const _DashboardDrinkInspirationCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final drink = DrinkCatalog.todayRecommendation();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/plan/diet/drink-recommendation'),
        child: Container(
          padding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.diet.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: colors.diet.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  drink.imagePath,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 62,
                      height: 62,
                      color: colors.softOrange,
                      child: Icon(
                        Icons.local_drink_outlined,
                        color: colors.diet,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日饮品灵感',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.diet,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${drink.brand} · ${drink.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '选择困难时，让今天替你挑一杯',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.diet.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: colors.diet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSceneryCard extends StatefulWidget {
  const _DashboardSceneryCard();

  @override
  State<_DashboardSceneryCard> createState() => _DashboardSceneryCardState();
}

class _DashboardSceneryCardState extends State<_DashboardSceneryCard> {
  static const Duration _autoInterval = Duration(seconds: 5);
  static const Duration _pageTransition = Duration(milliseconds: 460);

  late final PageController _controller;
  Timer? _timer;
  int _index = DateTime.now().day % SceneryThemeCatalog.themes.length;
  bool _userInteracting = false;
  bool _animatingPage = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _index);
    _scheduleAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoPlay() {
    _timer?.cancel();
    _timer = Timer(_autoInterval, () {
      if (!mounted || !_controller.hasClients) return;
      if (_userInteracting || _animatingPage) {
        _scheduleAutoPlay();
        return;
      }
      _goTo((_index + 1) % SceneryThemeCatalog.themes.length);
    });
  }

  Future<void> _goTo(int index) async {
    if (!_controller.hasClients) return;
    final total = SceneryThemeCatalog.themes.length;
    final normalized = index % total;
    _timer?.cancel();
    _animatingPage = true;
    try {
      if (normalized == _index) return;
      await _controller.animateToPage(
        normalized,
        duration: _pageTransition,
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _animatingPage = false;
      if (mounted) _scheduleAutoPlay();
    }
  }

  void _randomTheme() {
    final total = SceneryThemeCatalog.themes.length;
    if (total < 2) return;
    final random = math.Random();
    var next = random.nextInt(total);
    if (next == _index) next = (next + 1) % total;
    _goTo(next);
  }

  bool _handlePreviewScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      _userInteracting = true;
      _timer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _userInteracting = false;
      _scheduleAutoPlay();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final size = MediaQuery.sizeOf(context);
    final theme = SceneryThemeCatalog.themeAt(_index);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/dashboard/scenery'),
        child: Container(
          padding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.focus.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: colors.focus.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 88,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _handlePreviewScroll,
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: SceneryThemeCatalog.themes.length,
                          allowImplicitScrolling: true,
                          physics: const PageScrollPhysics(),
                          onPageChanged: (value) =>
                              setState(() => _index = value),
                          itemBuilder: (context, index) {
                            final item = SceneryThemeCatalog.themes[index];
                            return Image.asset(
                              item.assetForSize(Size(size.width, 160)),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            );
                          },
                        ),
                      ),
                      const _SceneryMiniParticles(),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 7,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value:
                                (_index + 1) /
                                SceneryThemeCatalog.themes.length,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.22,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              colors.focus.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '风景欣赏',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.focus,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      theme.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '安静看一会儿风景',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SceneryCardIconButton(
                      icon: Icons.shuffle_rounded,
                      tooltip: '随机切换',
                      color: colors.focus,
                      onTap: _randomTheme,
                    ),
                    const SizedBox(height: 7),
                    _SceneryCardIconButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: '进入风景欣赏',
                      color: colors.focus,
                      onTap: () => context.push('/dashboard/scenery'),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_index + 1}/${SceneryThemeCatalog.themes.length}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneryCardIconButton extends StatelessWidget {
  const _SceneryCardIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _SceneryMiniParticles extends StatefulWidget {
  const _SceneryMiniParticles();

  @override
  State<_SceneryMiniParticles> createState() => _SceneryMiniParticlesState();
}

class _SceneryMiniParticlesState extends State<_SceneryMiniParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SceneryMiniParticlePainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _SceneryMiniParticlePainter extends CustomPainter {
  const _SceneryMiniParticlePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final specs = const [
      (0.18, 0.34, 1.0),
      (0.48, 0.18, 0.68),
      (0.76, 0.42, 0.86),
    ];
    for (final spec in specs) {
      final phase = (progress + spec.$3) % 1.0;
      final x = (spec.$1 + math.sin(phase * math.pi * 2) * 0.05) * size.width;
      final y = (spec.$2 + math.cos(phase * math.pi * 2) * 0.10) * size.height;
      paint.color = Colors.white.withValues(alpha: 0.34 + spec.$3 * 0.16);
      canvas.drawCircle(Offset(x, y), 2.2 + spec.$3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SceneryMiniParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DashboardInspirationBookmarkCard extends StatelessWidget {
  const _DashboardInspirationBookmarkCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/plan/journal/inspiration'),
        child: Container(
          padding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.journal.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: colors.journal.withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/inspiration/自我接纳.webp',
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  cacheWidth: 140,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 62,
                      height: 62,
                      color: colors.softPink,
                      child: Icon(
                        Icons.auto_stories_outlined,
                        color: colors.journal,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日一句',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.journal,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '灵感书签',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '写日记前，先给自己留一句话',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.journal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: colors.journal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Loading & Error 状态
// =============================================================================

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text('加载中...', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('加载失败', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
