import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/constants/scenery_theme_catalog.dart';

class SceneryGalleryPage extends StatefulWidget {
  const SceneryGalleryPage({super.key});

  @override
  State<SceneryGalleryPage> createState() => _SceneryGalleryPageState();
}

class _SceneryGalleryPageState extends State<SceneryGalleryPage> {
  static const Duration _autoInterval = Duration(seconds: 6);
  static const Duration _pageTransition = Duration(milliseconds: 620);

  late final PageController _controller;
  Timer? _timer;
  Timer? _chromeTimer;
  String? _lastPrecacheKey;
  int _index = DateTime.now().day % SceneryThemeCatalog.themes.length;
  bool _playing = true;
  bool _chromeVisible = false;
  bool _randomMode = false;
  bool _userInteracting = false;
  bool _animatingPage = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _index);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chromeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _scheduleAutoPlay();
  }

  void _scheduleAutoPlay() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer(_autoInterval, () {
      if (!mounted || !_playing) return;
      if (_userInteracting || _animatingPage || !_controller.hasClients) {
        _scheduleAutoPlay();
        return;
      }
      _goTo(_nextIndex(SceneryThemeCatalog.themes.length));
    });
  }

  int _nextIndex(int total) {
    if (total < 2) return 0;
    if (!_randomMode) return (_index + 1) % total;
    return _pickRandomIndex(total);
  }

  int _pickRandomIndex(int total) {
    if (total < 2) return 0;
    final random = math.Random();
    var next = random.nextInt(total);
    if (next == _index) next = (next + 1) % total;
    return next;
  }

  Future<void> _goTo(int next) async {
    if (!_controller.hasClients) return;
    final total = SceneryThemeCatalog.themes.length;
    final normalized = next % total;
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

  void _wakeChrome() {
    _chromeTimer?.cancel();
    if (!_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
    _chromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  void _hideChrome() {
    _chromeTimer?.cancel();
    if (_chromeVisible) setState(() => _chromeVisible = false);
  }

  void _handleCanvasTap() {
    if (_chromeVisible) {
      _hideChrome();
    } else {
      _wakeChrome();
    }
  }

  void _togglePlaying() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _scheduleAutoPlay();
    } else {
      _timer?.cancel();
    }
    _wakeChrome();
  }

  void _goPrevious(int total) {
    _wakeChrome();
    _goTo((_index - 1 + total) % total);
  }

  void _goNext(int total) {
    _wakeChrome();
    _goTo((_index + 1) % total);
  }

  void _toggleRandomMode(int total) {
    if (total < 2) return;
    _wakeChrome();
    if (_randomMode) {
      setState(() => _randomMode = false);
      _scheduleAutoPlay();
      return;
    }
    setState(() => _randomMode = true);
    _goTo(_pickRandomIndex(total));
  }

  bool _handlePageScroll(ScrollNotification notification) {
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

  void _precacheAround(
    BuildContext context,
    Size size,
    List<SceneryTheme> themes,
  ) {
    final orientation = size.width >= size.height ? 'landscape' : 'portrait';
    final key = '$orientation:$_index';
    if (_lastPrecacheKey == key || themes.isEmpty) return;
    _lastPrecacheKey = key;
    for (final offset in const [-1, 0, 1]) {
      final item = themes[(_index + offset + themes.length) % themes.length];
      precacheImage(AssetImage(item.assetForSize(size)), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final size = MediaQuery.sizeOf(context);
    final themes = SceneryThemeCatalog.themes;
    final theme = themes[_index % themes.length];
    _precacheAround(context, size, themes);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleCanvasTap,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handlePageScroll,
              child: PageView.builder(
                controller: _controller,
                itemCount: themes.length,
                allowImplicitScrolling: true,
                physics: const PageScrollPhysics(),
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final item = themes[index];
                  return _SceneryImagePage(
                    controller: _controller,
                    index: index,
                    assetPath: item.assetForSize(size),
                  );
                },
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: AppMotion.normal,
              curve: AppMotion.standard,
              child: const _SceneryShade(),
            ),
          ),
          IgnorePointer(
            ignoring: !_chromeVisible,
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: AppMotion.normal,
              curve: AppMotion.standard,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: '返回',
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _GlassIconButton(
                        icon: _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        tooltip: _playing ? '暂停轮播' : '继续轮播',
                        onTap: _togglePlaying,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: MediaQuery.paddingOf(context).bottom + 18,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: AnimatedOpacity(
                opacity: _chromeVisible ? 1 : 0,
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                child: AnimatedSlide(
                  offset: _chromeVisible ? Offset.zero : const Offset(0, 0.16),
                  duration: AppMotion.normal,
                  curve: AppMotion.standard,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _hideChrome,
                    child: _SceneryControlPanel(
                      theme: theme,
                      index: _index,
                      total: themes.length,
                      playing: _playing,
                      randomMode: _randomMode,
                      onPrevious: () => _goPrevious(themes.length),
                      onNext: () => _goNext(themes.length),
                      onRandom: () => _toggleRandomMode(themes.length),
                      color: colors.focus,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneryImagePage extends StatelessWidget {
  const _SceneryImagePage({
    required this.controller,
    required this.index,
    required this.assetPath,
  });

  final PageController controller;
  final int index;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var page = controller.initialPage.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? page;
        }
        final delta = (page - index).clamp(-1.0, 1.0);
        return Transform.scale(
          scale: 1.035,
          child: Transform.translate(
            offset: Offset(delta * -18, 0),
            child: child,
          ),
        );
      },
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _SceneryShade extends StatelessWidget {
  const _SceneryShade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.34),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.58),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _SceneryControlPanel extends StatelessWidget {
  const _SceneryControlPanel({
    required this.theme,
    required this.index,
    required this.total,
    required this.playing,
    required this.randomMode,
    required this.onPrevious,
    required this.onNext,
    required this.onRandom,
    required this.color,
  });

  final SceneryTheme theme;
  final int index;
  final int total;
  final bool playing;
  final bool randomMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRandom;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '风景欣赏',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      theme.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}/$total',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: (index + 1) / total,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.86),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SceneryFlowBand(color: color),
              const SizedBox(height: 14),
              Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: '上一张',
                    onTap: onPrevious,
                  ),
                  const SizedBox(width: 10),
                  _GlassIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: '下一张',
                    onTap: onNext,
                  ),
                  const SizedBox(width: 10),
                  _GlassIconButton(
                    icon: randomMode
                        ? Icons.repeat_rounded
                        : Icons.shuffle_rounded,
                    tooltip: randomMode ? '切回顺序轮播' : '随机轮播',
                    onTap: onRandom,
                  ),
                  const Spacer(),
                  Icon(
                    !playing
                        ? Icons.pause_rounded
                        : randomMode
                        ? Icons.shuffle_rounded
                        : Icons.autorenew_rounded,
                    color: Colors.white.withValues(alpha: 0.78),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    !playing
                        ? '已暂停'
                        : randomMode
                        ? '随机轮播中'
                        : '顺序轮播中',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneryFlowBand extends StatefulWidget {
  const _SceneryFlowBand({required this.color});

  final Color color;

  @override
  State<_SceneryFlowBand> createState() => _SceneryFlowBandState();
}

class _SceneryFlowBandState extends State<_SceneryFlowBand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SceneryFlowBandPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SceneryFlowBandPainter extends CustomPainter {
  const _SceneryFlowBandPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.70),
          Colors.white.withValues(alpha: 0.62),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final start = (progress * size.width * 1.35) - size.width * 0.35;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(start, y - 1.5, size.width * 0.35, 3),
        const Radius.circular(999),
      ),
      glowPaint,
    );

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final phase = (progress + i * 0.19) % 1.0;
      dotPaint.color = Colors.white.withValues(alpha: 0.30 + i * 0.05);
      canvas.drawCircle(
        Offset(phase * size.width, y),
        1.4 + i * 0.16,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SceneryFlowBandPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
