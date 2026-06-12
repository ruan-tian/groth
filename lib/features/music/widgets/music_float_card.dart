part of 'dashboard_music_float.dart';

class _MusicFloatCard extends StatelessWidget {
  const _MusicFloatCard({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    final motionOff = AppMotion.reduceMotion(context);
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.slow),
      curve: AppMotion.standard,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(state.isExpanded ? 14 : 0),
      decoration: BoxDecoration(
        gradient: state.isExpanded
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFCF6), Color(0xFFF3EDFF)],
              )
            : null,
        color: state.isExpanded
            ? null
            : const Color(0xFFFFFCF5).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(state.isExpanded ? 30 : 999),
        border: Border.all(color: const Color(0xFFE8DDF7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A7155B9),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
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
        child: state.isExpanded
            ? _ExpandedMusicCard(
                key: const ValueKey('expanded_music_card'),
                state: state,
              )
            : _CollapsedMusicCapsule(
                key: const ValueKey('collapsed_music_capsule'),
                state: state,
              ),
      ),
    );
  }
}

class _CollapsedMusicCapsule extends StatelessWidget {
  const _CollapsedMusicCapsule({super.key, required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    final track = state.currentTrack;
    final hasTrack = track != null;
    final isPlaying = state.isPlaying && hasTrack;
    final title = hasTrack ? track.title : 'Lofi Cat';
    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: isPlaying ? 0.28 : 0.2,
              child: Image.asset(
                isPlaying
                    ? MusicAssets.capsulePlaying
                    : MusicAssets.capsuleIdle,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isPlaying)
            Positioned(
              bottom: 9,
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(MusicAssets.wavePlaying, width: 30),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StickerImage(
                  asset: hasTrack
                      ? (track.coverAsset ?? MusicAssets.coverDefault)
                      : MusicAssets.catHeadphone,
                  size: 54,
                  rounded: hasTrack ? 17 : 999,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _MusicColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    hasTrack
                        ? _MiniWave(isPlaying: state.isPlaying, centered: true)
                        : Image.asset(
                            MusicAssets.decoNote,
                            width: 18,
                            height: 18,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedMusicCard extends ConsumerWidget {
  const _ExpandedMusicCard({super.key, required this.state});

  final MusicPlayerState state;

  IconData _playModeIcon() {
    return switch (state.playMode) {
      PlayMode.sequential => Icons.arrow_forward_rounded,
      PlayMode.loopAll => Icons.repeat_rounded,
      PlayMode.loopSingle => Icons.repeat_one_rounded,
      PlayMode.shuffle => Icons.shuffle_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(musicPlayerProvider.notifier);
    final track = state.currentTrack;
    final duration = state.effectiveDuration;
    final canSeek = duration > Duration.zero;
    final position = state.position > duration && canSeek
        ? duration
        : state.position;
    final progressValue = canSeek ? position.inMilliseconds.toDouble() : 0.0;
    final maxProgress = canSeek ? duration.inMilliseconds.toDouble() : 1.0;

    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 8),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -32,
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(MusicAssets.decoSparkle, width: 112),
            ),
          ),
          Positioned(
            left: -28,
            top: 86,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(MusicAssets.itemCloud, width: 108),
            ),
          ),
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: cover + title + favorite + collapse ──
                Row(
                  children: [
                    _CoverImage(track: track, size: 70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.title ?? '甜甜音乐',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _MusicColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  track == null
                                      ? '导入本地音乐开始播放'
                                      : state.selectedCollection.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _MusicColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (track != null) ...[
                                const SizedBox(width: 8),
                                _StatusPill(
                                  isPlaying: state.isPlaying,
                                  isLoading: state.isLoading,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _RoundIconButton(
                      tooltip: track?.isFavorite == true ? '取消收藏' : '收藏',
                      icon: track?.isFavorite == true
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onPressed: track == null
                          ? null
                          : () => controller.toggleFavorite(track),
                    ),
                    const SizedBox(width: 6),
                    _RoundIconButton(
                      tooltip: '收起',
                      icon: Icons.keyboard_arrow_down_rounded,
                      onPressed: controller.collapse,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Lyrics ──
                _LyricsPanel(state: state),
                const SizedBox(height: 10),
                // ── Collection switcher ──
                _CollectionSwitcher(state: state),
                const SizedBox(height: 8),
                // ── Progress bar ──
                Row(
                  children: [
                    Text(_formatDuration(position), style: _timeStyle),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: progressValue.clamp(0.0, maxProgress),
                          min: 0,
                          max: maxProgress,
                          activeColor: _MusicColors.primary,
                          inactiveColor: Colors.white.withValues(alpha: 0.86),
                          onChanged: canSeek
                              ? (value) => controller.seek(
                                  Duration(milliseconds: value.round()),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Text(_formatDuration(duration), style: _timeStyle),
                  ],
                ),
                const SizedBox(height: 4),
                // ── Main transport: prev / play / next ──
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
                    const SizedBox(width: 14),
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
                    const SizedBox(width: 14),
                    _RoundIconButton(
                      tooltip: '下一首',
                      icon: Icons.skip_next_rounded,
                      onPressed: state.hasTracks ? controller.playNext : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Secondary controls: mode / timer / volume / list ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundIconButton(
                      tooltip: state.playModeLabel,
                      icon: _playModeIcon(),
                      onPressed: controller.togglePlayMode,
                    ),
                    _TimerChip(state: state),
                    _VolumeControl(
                      volume: state.volume,
                      onChanged: controller.setVolume,
                    ),
                    _RoundIconButton(
                      tooltip: '播放列表',
                      icon: Icons.queue_music_rounded,
                      onPressed: () {
                        controller.selectCollection(MusicCollection.all);
                        _showMusicLibrarySheet(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Action chips ──
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionChipButton(
                      icon: state.isImporting
                          ? Icons.hourglass_empty_rounded
                          : Icons.add_rounded,
                      label: state.isImporting ? '导入中' : '导入',
                      onTap: state.isImporting ? null : controller.importTracks,
                    ),
                    _ActionChipButton(
                      icon: Icons.favorite_rounded,
                      label: '收藏',
                      onTap: () {
                        controller.selectCollection(MusicCollection.favorites);
                        _showMusicLibrarySheet(context);
                      },
                    ),
                    _ActionChipButton(
                      icon: Icons.text_fields_rounded,
                      label: state.lyrics.hasLyrics ? '歌词同步' : '导入歌词',
                      onTap: state.lyrics.hasLyrics
                          ? null
                          : controller.importLrcForCurrentTrack,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsPanel extends StatelessWidget {
  const _LyricsPanel({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    final previous = state.previousLyric?.text;
    final current = state.currentLyric?.text;
    final next = state.nextLyric?.text;
    final hasLyrics = state.lyrics.hasLyrics;

    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9DDF8)),
      ),
      child: hasLyrics
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LyricText(previous ?? '', active: false),
                const SizedBox(height: 4),
                _LyricText(current ?? '', active: true),
                const SizedBox(height: 4),
                _LyricText(next ?? '', active: false),
              ],
            )
          : Row(
              children: [
                Image.asset(MusicAssets.catRelax, width: 52, height: 52),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '把同名 .lrc 放在歌曲旁边，导入时就会显示歌词。',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _MusicColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LyricText extends StatelessWidget {
  const _LyricText(this.text, {required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: AppMotion.duration(context, AppMotion.normal),
      style: TextStyle(
        color: active ? _MusicColors.ink : _MusicColors.muted,
        fontSize: active ? 15 : 11,
        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
      ),
      child: Text(
        text.isEmpty ? ' ' : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPlaying, required this.isLoading});

  final bool isPlaying;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final label = isLoading
        ? '加载中'
        : isPlaying
        ? '播放中'
        : '已暂停';
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: (isPlaying ? _MusicColors.primary : Colors.white).withValues(
          alpha: isPlaying ? 0.14 : 0.82,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9DDF8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLoading
                ? Icons.hourglass_empty_rounded
                : isPlaying
                ? Icons.graphic_eq_rounded
                : Icons.pause_rounded,
            size: 12,
            color: _MusicColors.primary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: _MusicColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionSwitcher extends ConsumerWidget {
  const _CollectionSwitcher({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = state.selectedCollection;
    final tracks = state.tracksForCollection(collection);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 80) return;
        final values = MusicCollection.values;
        final index = values.indexOf(collection);
        final nextIndex = velocity < 0
            ? (index + 1) % values.length
            : (index - 1) % values.length;
        ref
            .read(musicPlayerProvider.notifier)
            .selectCollection(values[nextIndex]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4D8F6)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chevron_left_rounded,
              color: _MusicColors.primary,
              size: 20,
            ),
            Expanded(
              child: Text(
                '${collection.label}歌单 · ${tracks.length} 首',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _MusicColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _MusicColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerChip extends ConsumerWidget {
  const _TimerChip({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GrowthPressable(
      onTap: () => _showSleepTimerSheet(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: state.hasActiveSleepTimer
              ? const Color(0xFF8B75F6)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE9DDF8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_rounded,
              color: state.hasActiveSleepTimer
                  ? Colors.white
                  : _MusicColors.primary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              state.sleepTimerLabel,
              style: TextStyle(
                color: state.hasActiveSleepTimer
                    ? Colors.white
                    : _MusicColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeControl extends StatefulWidget {
  const _VolumeControl({required this.volume, required this.onChanged});

  final double volume;
  final ValueChanged<double> onChanged;

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  bool _expanded = false;

  IconData _volumeIcon() {
    if (widget.volume <= 0) return Icons.volume_off_rounded;
    if (widget.volume < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return _RoundIconButton(
        tooltip: '音量',
        icon: _volumeIcon(),
        onPressed: () => setState(() => _expanded = true),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9DDF8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Icon(_volumeIcon(), color: _MusicColors.primary, size: 20),
          ),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: widget.volume,
                min: 0,
                max: 1,
                activeColor: _MusicColors.primary,
                inactiveColor: Colors.white.withValues(alpha: 0.86),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerImage extends StatelessWidget {
  const _StickerImage({
    required this.asset,
    required this.size,
    this.rounded = 999,
  });

  final String asset;
  final double size;
  final double rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rounded),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E7A5B9B),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0, rounded - 4)),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.track, required this.size});

  final MusicTrack? track;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5E448C),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          track?.coverAsset ?? MusicAssets.coverDefault,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _MiniWave extends StatelessWidget {
  const _MiniWave({required this.isPlaying, this.centered = false});

  final bool isPlaying;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: List.generate(
        4,
        (index) => AnimatedContainer(
          duration: AppMotion.duration(
            context,
            Duration(milliseconds: 220 + index * 40),
          ),
          width: 3,
          height: isPlaying ? (7 + (index % 3) * 4).toDouble() : 5,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: _MusicColors.primary.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(99),
          ),
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
            color: filled ? _MusicColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE9DDF8)),
            boxShadow: filled
                ? const [
                    BoxShadow(
                      color: Color(0x328B75F6),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: onPressed == null
                ? _MusicColors.muted.withValues(alpha: 0.48)
                : filled
                ? Colors.white
                : _MusicColors.primary,
            size: filled ? 25 : 22,
          ),
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GrowthPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEADFF8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _MusicColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _MusicColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x32715AA6),
              blurRadius: 26,
              offset: Offset(0, 12),
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
                    color: const Color(0xFFE7DAF8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '定时关闭',
                style: TextStyle(
                  color: _MusicColors.ink,
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
                      return _ActionChipButton(
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

void _showMusicLibrarySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MusicLibrarySheet(),
  );
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

const _timeStyle = TextStyle(
  color: _MusicColors.muted,
  fontSize: 11,
  fontWeight: FontWeight.w800,
);

class _MusicColors {
  static const ink = Color(0xFF352F4F);
  static const muted = Color(0xFF8B8498);
  static const primary = Color(0xFF8B75F6);
}
