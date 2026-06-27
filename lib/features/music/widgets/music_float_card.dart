part of 'dashboard_music_float.dart';

class _MusicFloatCard extends StatelessWidget {
  const _MusicFloatCard({
    required this.state,
    required this.side,
    required this.isRevealed,
    required this.onReveal,
    required this.onOpenPlayer,
    required this.onImport,
  });

  final MusicPlayerState state;
  final _MusicDockSide side;
  final bool isRevealed;
  final VoidCallback onReveal;
  final VoidCallback onOpenPlayer;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final motionOff = AppMotion.reduceMotion(context);
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.slow),
      curve: AppMotion.standard,
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.normal),
        switchInCurve: AppMotion.standard,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          if (motionOff) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.standard,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
              child: child,
            ),
          );
        },
        child: isRevealed
            ? _RevealedMusicRemote(
                key: const ValueKey('revealed_music_remote'),
                state: state,
                side: side,
                onOpenPlayer: onOpenPlayer,
                onImport: onImport,
              )
            : _DockedMusicHandle(
                key: const ValueKey('docked_music_handle'),
                state: state,
                side: side,
                onReveal: onReveal,
              ),
      ),
    );
  }
}

class _DockedMusicHandle extends StatelessWidget {
  const _DockedMusicHandle({
    super.key,
    required this.state,
    required this.side,
    required this.onReveal,
  });

  final MusicPlayerState state;
  final _MusicDockSide side;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final hasTrack = state.currentTrack != null;
    final isPlaying = state.isPlaying && hasTrack;
    final radius = side == _MusicDockSide.left
        ? const BorderRadius.horizontal(right: Radius.circular(22))
        : const BorderRadius.horizontal(left: Radius.circular(22));

    return Tooltip(
      message: hasTrack ? '展开音乐控制' : '导入音乐',
      child: GrowthPressable(
        onTap: onReveal,
        semanticLabel: hasTrack ? '展开音乐控制' : '导入音乐',
        borderRadius: radius,
        child: Align(
          alignment: side == _MusicDockSide.left
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 42,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: colors.card.withValues(alpha: 0.82),
              border: Border.all(color: colors.border.withValues(alpha: 0.56)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: isPlaying ? 0.20 : 0.09,
                  ),
                  blurRadius: 18,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card.withValues(alpha: 0.94),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        bottom: 10,
                        left: side == _MusicDockSide.left ? null : 16,
                        right: side == _MusicDockSide.left ? 16 : null,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: colors.border.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Align(
                        alignment: side == _MusicDockSide.left
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: SizedBox(
                          width: 24,
                          child: Center(
                            child: hasTrack
                                ? _MiniWaveBars(
                                    isPlaying: isPlaying,
                                    color: colors.primary,
                                  )
                                : Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealedMusicRemote extends ConsumerWidget {
  const _RevealedMusicRemote({
    super.key,
    required this.state,
    required this.side,
    required this.onOpenPlayer,
    required this.onImport,
  });

  final MusicPlayerState state;
  final _MusicDockSide side;
  final VoidCallback onOpenPlayer;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 180) {
          return _DockedMusicHandle(
            state: state,
            side: side,
            onReveal: state.currentTrack == null ? onImport : onOpenPlayer,
          );
        }

        final colors = context.growthColors;
        final controller = ref.read(musicPlayerProvider.notifier);
        final track = state.currentTrack;
        final hasTrack = track != null;
        final isPlaying = state.isPlaying && hasTrack;
        final progress = state.progress;
        final radius = side == _MusicDockSide.left
            ? const BorderRadius.horizontal(right: Radius.circular(999))
            : const BorderRadius.horizontal(left: Radius.circular(999));

        return Align(
          alignment: side == _MusicDockSide.left
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: GrowthPressable(
            onTap: hasTrack ? onOpenPlayer : onImport,
            semanticLabel: hasTrack ? '打开完整播放器' : '导入音乐',
            borderRadius: radius,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: colors.card.withValues(alpha: 0.88),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.62),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.20),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: colors.primary.withValues(
                      alpha: isPlaying ? 0.20 : 0.08,
                    ),
                    blurRadius: 18,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card.withValues(alpha: 0.94),
                    ),
                    child: Row(
                      textDirection: side == _MusicDockSide.left
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      children: [
                        SizedBox(width: side == _MusicDockSide.left ? 4 : 5),
                        const _MiniGrip(),
                        const SizedBox(width: 5),
                        _MiniCover(track: track, isPlaying: isPlaying),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track?.title ?? '甜甜音乐',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  hasTrack
                                      ? (isPlaying ? '正在播放' : '已暂停')
                                      : '导入音乐',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 2.5,
                                    value: hasTrack
                                        ? progress.clamp(0.0, 1.0)
                                        : 0,
                                    backgroundColor: colors.surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation(
                                      colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MiniCircleButton(
                                tooltip: hasTrack
                                    ? (isPlaying ? '暂停' : '播放')
                                    : '导入音乐',
                                icon: state.isLoading || state.isImporting
                                    ? Icons.hourglass_empty_rounded
                                    : hasTrack
                                    ? (isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded)
                                    : Icons.add_rounded,
                                filled: true,
                                onTap: state.isLoading || state.isImporting
                                    ? null
                                    : hasTrack
                                    ? controller.togglePlayPause
                                    : onImport,
                              ),
                              const SizedBox(width: 4),
                              _MiniCircleButton(
                                tooltip: '下一首',
                                icon: Icons.skip_next_rounded,
                                onTap: hasTrack ? controller.playNext : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: side == _MusicDockSide.left ? 7 : 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniGrip extends StatelessWidget {
  const _MiniGrip();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      width: 5,
      height: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            width: 2.5,
            height: 2.5,
            margin: const EdgeInsets.symmetric(vertical: 2.5),
            decoration: BoxDecoration(
              color: colors.textTertiary.withValues(alpha: 0.46),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.track, required this.isPlaying});

  final MusicTrack? track;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.card,
        border: Border.all(
          color: isPlaying
              ? colors.primary.withValues(alpha: 0.38)
              : colors.border,
        ),
      ),
      child: ClipOval(
        child: track == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.86),
                ),
                child: Icon(Icons.music_note_rounded, color: colors.primary),
              )
            : Image.asset(
                MusicArtworkMapper.coverForTrack(track),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
      ),
    );
  }
}

class _MiniCircleButton extends StatelessWidget {
  const _MiniCircleButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Tooltip(
      message: tooltip,
      child: GrowthPressable(
        onTap: onTap,
        semanticLabel: tooltip,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: filled ? 28 : 26,
          height: filled ? 28 : 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? colors.primary
                : colors.surfaceVariant.withValues(alpha: 0.82),
            border: filled
                ? null
                : Border.all(color: colors.border.withValues(alpha: 0.72)),
          ),
          child: Icon(
            icon,
            size: filled ? 18 : 17,
            color: onTap == null
                ? colors.textHint
                : filled
                ? colors.textOnAccent
                : colors.primary,
          ),
        ),
      ),
    );
  }
}

class _MiniWaveBars extends StatefulWidget {
  const _MiniWaveBars({required this.isPlaying, required this.color});

  final bool isPlaying;
  final Color color;

  @override
  State<_MiniWaveBars> createState() => _MiniWaveBarsState();
}

class _MiniWaveBarsState extends State<_MiniWaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _MiniWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _sync();
  }

  void _sync() {
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CapsuleWavePainter(
              phase: _controller.value,
              isPlaying: widget.isPlaying,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _CapsuleWaveVisualizer extends StatefulWidget {
  const _CapsuleWaveVisualizer({required this.isPlaying, required this.color});

  final bool isPlaying;
  final Color color;

  @override
  State<_CapsuleWaveVisualizer> createState() => _CapsuleWaveVisualizerState();
}

class _CapsuleWaveVisualizerState extends State<_CapsuleWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _CapsuleWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _sync();
    }
  }

  void _sync() {
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CapsuleWavePainter(
              phase: _controller.value,
              isPlaying: widget.isPlaying,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _CapsuleWavePainter extends CustomPainter {
  const _CapsuleWavePainter({
    required this.phase,
    required this.isPlaying,
    required this.color,
  });

  final double phase;
  final bool isPlaying;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isPlaying ? 0.72 : 0.32)
      ..style = PaintingStyle.fill;
    final centerY = size.height / 2;
    final width = size.width;
    final barWidth = math.max(1.4, width / 13);
    final gap = math.max(0.8, width / 30);
    final total = barWidth * 7 + gap * 6;
    final startX = (width - total) / 2;

    for (var i = 0; i < 7; i++) {
      final pulse = isPlaying
          ? (math.sin((phase * math.pi * 2) + i * 0.72) + 1) / 2
          : 0.35;
      final base = i == 3 ? 0.78 : 0.36 + (3 - (i - 3).abs()) * 0.12;
      final height = size.height * (0.28 + base * pulse).clamp(0.24, 0.94);
      final x = startX + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: height,
        ),
        Radius.circular(barWidth),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CapsuleWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.color != color;
  }
}

class _MusicPlayerSheet extends ConsumerWidget {
  const _MusicPlayerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final state = ref.watch(musicPlayerProvider);
    final size = MediaQuery.sizeOf(context);
    final height = math.min(size.height * 0.90, 760.0);

    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 18),
      child: Container(
        height: height,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.78),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _ExpandedMusicCard(
                        key: const ValueKey('expanded_music_card'),
                        state: state,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedMusicCard extends ConsumerWidget {
  const _ExpandedMusicCard({super.key, required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final controller = ref.read(musicPlayerProvider.notifier);
    final track = state.currentTrack;
    final duration = state.effectiveDuration;
    final canSeek = duration > Duration.zero;
    final position = state.position > duration && canSeek
        ? duration
        : state.position;
    final progressValue = canSeek ? position.inMilliseconds.toDouble() : 0.0;
    final maxProgress = canSeek ? duration.inMilliseconds.toDouble() : 1.0;
    final timeStyle = TextStyle(
      color: colors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );

    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Decorations ──
          Positioned(
            left: -15,
            top: 60,
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(MusicAssets.playerDecoWave, width: 96),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 40,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(MusicAssets.playerDecoNote, width: 46),
            ),
          ),
          // ── Main Content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header: "正在播放" + collapse ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(MusicAssets.playerDecoNote, width: 18),
                        const SizedBox(width: 6),
                        Text(
                          '正在播放',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    _RoundIconButton(
                      tooltip: '收起',
                      icon: Icons.keyboard_arrow_down_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Cover ──
                _VinylStage(track: track, isPlaying: state.isPlaying),
                const SizedBox(height: 10),
                // ── Title + Subtitle ──
                Text(
                  track?.title ?? '甜甜音乐',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track?.artist ?? '导入本地音乐开始播放',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // ── Status pill ──
                const SizedBox(height: 12),
                // ── Progress bar ──
                Row(
                  children: [
                    Text(_formatDuration(position), style: timeStyle),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: progressValue.clamp(0.0, maxProgress),
                          min: 0,
                          max: maxProgress,
                          activeColor: colors.primary,
                          inactiveColor: colors.surfaceVariant,
                          onChanged: canSeek
                              ? (value) => controller.seek(
                                  Duration(milliseconds: value.round()),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Text(_formatDuration(duration), style: timeStyle),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Main controls: prev / play / next ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      tooltip: '上一首',
                      icon: Icons.skip_previous_rounded,
                      onPressed: state.hasTracks
                          ? controller.playPrevious
                          : null,
                    ),
                    const SizedBox(width: 16),
                    _RoundIconButton(
                      tooltip: state.isPlaying ? '暂停' : '播放',
                      icon: state.isLoading
                          ? Icons.hourglass_empty_rounded
                          : state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      filled: true,
                      onPressed: state.isLoading
                          ? null
                          : controller.togglePlayPause,
                    ),
                    const SizedBox(width: 16),
                    _RoundIconButton(
                      tooltip: '下一首',
                      icon: Icons.skip_next_rounded,
                      onPressed: state.hasTracks ? controller.playNext : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── 主操作区：收藏 + 播放列表 ──
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryActionChip(
                        label: '收藏',
                        icon: track?.isFavorite == true
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        active: track?.isFavorite == true,
                        onTap: track == null
                            ? null
                            : () => controller.toggleFavorite(track),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PrimaryActionChip(
                        label: '播放列表',
                        icon: Icons.queue_music_rounded,
                        onTap: () {
                          controller.selectCollection(MusicCollection.all);
                          _showMusicLibrarySheet(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── 次操作区：播放模式 + 音量 + 定时 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MusicActionChip(
                      label: state.playModeLabel,
                      icon: _playModeIcon(state.playMode),
                      active:
                          state.playMode == PlayMode.shuffle ||
                          state.playMode == PlayMode.loopSingle,
                      onTap: controller.togglePlayMode,
                    ),
                    const SizedBox(width: 8),
                    _MusicActionChip(
                      label: '音量',
                      icon: state.volume > 0.5
                          ? Icons.volume_up_rounded
                          : state.volume > 0
                          ? Icons.volume_down_rounded
                          : Icons.volume_off_rounded,
                      onTap: () => _showVolumeSheet(context),
                    ),
                    const SizedBox(width: 8),
                    _MusicActionChip(
                      label: '定时',
                      asset: MusicAssets.settingTimer,
                      icon: Icons.timer_outlined,
                      active: state.hasActiveSleepTimer,
                      onTap: () => _showSleepTimerSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MusicLibraryEntryCard(
                  onTap: () => _showMusicLibraryHubSheet(context),
                ),
                const SizedBox(height: 14),
                // ── Song list header ──
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '常听歌曲',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Song list (limited height) ──
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 142),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: state.selectedTracks.length.clamp(0, 3),
                    itemBuilder: (context, index) {
                      final track = state.selectedTracks[index];
                      final isSelected = track.id == state.currentTrackId;
                      return _SongListItem(
                        track: track,
                        isSelected: isSelected,
                        isPlaying: isSelected && state.isPlaying,
                        onTap: () => controller.playTrack(track),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VinylStage extends StatefulWidget {
  const _VinylStage({required this.track, required this.isPlaying});

  final MusicTrack? track;
  final bool isPlaying;

  @override
  State<_VinylStage> createState() => _VinylStageState();
}

class _VinylStageState extends State<_VinylStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _VinylStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _sync();
  }

  void _sync() {
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: 286,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 28,
            child: Opacity(
              opacity: 0.58,
              child: Image.asset(
                MusicAssets.playerFloatingNotes,
                width: 74,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 26,
            child: Opacity(
              opacity: 0.46,
              child: Image.asset(
                MusicAssets.playerFloatingNotes,
                width: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Opacity(
            opacity: widget.isPlaying ? 0.92 : 0.72,
            child: Image.asset(
              MusicAssets.playerVinylGlow,
              width: 310,
              height: 310,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          RotationTransition(
            turns: _controller,
            child: Image.asset(
              MusicAssets.playerVinylDisc,
              width: 232,
              height: 232,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.card,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              MusicArtworkMapper.coverForTrack(widget.track),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Image.asset(
            MusicAssets.playerVinylCenterFrame,
            width: 128,
            height: 128,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          Positioned(
            right: 10,
            top: 72,
            child: Transform.rotate(
              angle: widget.isPlaying ? -0.04 : 0.03,
              child: Image.asset(
                MusicAssets.playerVinylTonearm,
                width: 122,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicLibraryEntryCard extends StatelessWidget {
  const _MusicLibraryEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GrowthPressable(
      onTap: onTap,
      semanticLabel: '音乐库',
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border.withValues(alpha: 0.76)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(Icons.music_note_rounded, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '音乐库',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '导入 / 扫描 / 管理',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  const _SongListItem({
    required this.track,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
  });

  final MusicTrack track;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : colors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _CoverImage(track: track, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist ?? '未知艺术家',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && isPlaying)
              SizedBox(
                width: 26,
                child: _CapsuleWaveVisualizer(
                  isPlaying: true,
                  color: colors.primary,
                ),
              )
            else
              Icon(
                Icons.play_arrow_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _MusicActionChip extends StatelessWidget {
  const _MusicActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.asset,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? asset;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Tooltip(
      message: label,
      child: GrowthPressable(
        onTap: onTap,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: active
                ? colors.softPink
                : colors.card.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? colors.journal : colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.10),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (asset != null)
                Image.asset(
                  asset!,
                  width: 18,
                  height: 18,
                  filterQuality: FilterQuality.high,
                )
              else
                Icon(
                  icon,
                  size: 16,
                  color: active ? colors.journal : colors.primary,
                ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? colors.textHint : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionChip extends StatelessWidget {
  const _PrimaryActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GrowthPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: active ? colors.softPink : colors.card.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? colors.journal : colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.10),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? colors.journal : colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: active ? colors.journal : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _playModeIcon(PlayMode mode) {
  return switch (mode) {
    PlayMode.sequential => Icons.arrow_forward_rounded,
    PlayMode.loopAll => Icons.repeat_rounded,
    PlayMode.loopSingle => Icons.repeat_one_rounded,
    PlayMode.shuffle => Icons.shuffle_rounded,
  };
}

void _showVolumeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VolumeSheet(),
  );
}

class _VolumeSheet extends ConsumerWidget {
  const _VolumeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final state = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '音量',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.volume_down_rounded,
                  color: colors.textSecondary,
                  size: 22,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: state.volume,
                      min: 0,
                      max: 1,
                      activeColor: colors.primary,
                      inactiveColor: colors.surfaceVariant,
                      onChanged: controller.setVolume,
                    ),
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  color: colors.textSecondary,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${(state.volume * 100).toInt()}%',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSleepTimerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SleepTimerSheet(),
  );
}

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final controller = ref.read(musicPlayerProvider.notifier);
    final options = <_TimerOption>[
      _TimerOption('关闭定时', Icons.timer_off_rounded, () {
        controller.clearSleepTimer();
      }),
      _TimerOption('15 分钟', Icons.timer_rounded, () {
        controller.setSleepTimer(const Duration(minutes: 15));
      }),
      _TimerOption('30 分钟', Icons.timer_rounded, () {
        controller.setSleepTimer(const Duration(minutes: 30));
      }),
      _TimerOption('45 分钟', Icons.timer_rounded, () {
        controller.setSleepTimer(const Duration(minutes: 45));
      }),
      _TimerOption('60 分钟', Icons.timer_rounded, () {
        controller.setSleepTimer(const Duration(minutes: 60));
      }),
      _TimerOption(
        '播完当前歌',
        Icons.queue_music_rounded,
        controller.setEndOfTrackTimer,
      ),
    ];

    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 14),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '定时关闭',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options
                    .map((option) {
                      return _MusicActionChip(
                        icon: option.icon,
                        label: option.label,
                        onTap: () {
                          Navigator.of(context).pop();
                          option.onTap();
                        },
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerOption {
  const _TimerOption(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.track, required this.size});

  final MusicTrack? track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          MusicArtworkMapper.coverForTrack(track),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Tooltip(
      message: tooltip,
      child: GrowthPressable(
        onTap: onPressed,
        semanticLabel: tooltip,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: filled ? 44 : 38,
          height: filled ? 44 : 38,
          decoration: BoxDecoration(
            color: filled
                ? colors.primary
                : colors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: filled
                ? null
                : Border.all(color: colors.border.withValues(alpha: 0.70)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: filled ? 0.18 : 0.08),
                blurRadius: filled ? 13 : 10,
                offset: Offset(0, filled ? 6 : 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: onPressed == null
                ? colors.textHint
                : filled
                ? colors.textOnAccent
                : colors.primary,
            size: filled ? 25 : 22,
          ),
        ),
      ),
    );
  }
}

void _showMusicLibrarySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MusicLibrarySheet(),
  );
}

void _showMusicLibraryHubSheet(BuildContext parentContext) {
  showModalBottomSheet<void>(
    context: parentContext,
    backgroundColor: Colors.transparent,
    builder: (_) => _MusicLibraryHubSheet(parentContext: parentContext),
  );
}

class _MusicLibraryHubSheet extends ConsumerWidget {
  const _MusicLibraryHubSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 14),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              _LibraryHubTile(
                asset: MusicAssets.settingImport,
                title: '导入音乐',
                subtitle: '选择音频文件，并可加入默认场景或自建歌单',
                onTap: () {
                  Navigator.of(context).pop();
                  showMusicImportDestinationSheet(parentContext, ref);
                },
              ),
              const SizedBox(height: 10),
              _LibraryHubTile(
                asset: MusicAssets.settingScene,
                title: '扫描文件夹',
                subtitle: '递归导入文件夹中的音频和同名歌词文件',
                onTap: () {
                  Navigator.of(context).pop();
                  showMusicImportDestinationSheet(
                    parentContext,
                    ref,
                    scanFolder: true,
                  );
                },
              ),
              const SizedBox(height: 10),
              _LibraryHubTile(
                asset: MusicAssets.settingCapsule,
                title: '音乐空间',
                subtitle: '管理场景歌单、自建歌单、收藏和最近播放',
                onTap: () {
                  Navigator.of(context).pop();
                  _openMusicSpace(parentContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryHubTile extends StatelessWidget {
  const _LibraryHubTile({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String asset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GrowthPressable(
      onTap: onTap,
      semanticLabel: title,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Image.asset(asset, width: 44, height: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

Future<void> _openMusicSpace(BuildContext context) async {
  final router = GoRouter.of(context);
  await Navigator.of(context).maybePop();
  if (context.mounted) {
    router.push('/dashboard/music/playlist');
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
