import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../models/music_player_state.dart';
import '../providers/music_player_provider.dart';
import '../utils/music_assets.dart';

class DashboardMusicFloat extends ConsumerStatefulWidget {
  const DashboardMusicFloat({super.key});

  @override
  ConsumerState<DashboardMusicFloat> createState() =>
      _DashboardMusicFloatState();
}

class _DashboardMusicFloatState extends ConsumerState<DashboardMusicFloat> {
  @override
  Widget build(BuildContext context) {
    ref.listen<MusicPlayerState>(musicPlayerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      ref.read(musicPlayerProvider.notifier).clearError();
    });

    final state = ref.watch(musicPlayerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final expandedWidth = math.min(width - 24, 348.0);
    final collapsedWidth = state.isPlaying && state.currentTrack != null
        ? math.min(width - 28, 188.0)
        : 102.0;

    return Positioned(
      left: 12,
      bottom: 88,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: state.isExpanded ? expandedWidth : collapsedWidth,
        height: state.isExpanded ? 278 : 58,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
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
        ),
      ),
    );
  }
}

class _CollapsedMusicCapsule extends ConsumerWidget {
  const _CollapsedMusicCapsule({super.key, required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.currentTrack;
    final isPlaying = state.isPlaying && track != null;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => ref.read(musicPlayerProvider.notifier).toggleExpanded(),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF5).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF2E6FF), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x248B75F6),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isPlaying)
              Positioned(
                right: -18,
                top: -8,
                bottom: -8,
                child: Opacity(
                  opacity: 0.28,
                  child: Image.asset(MusicAssets.wavePlaying, width: 92),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StickerImage(
                    asset: isPlaying
                        ? (track.coverAsset ?? MusicAssets.coverDefault)
                        : MusicAssets.catHeadphone,
                    size: 42,
                    rounded: isPlaying ? 14 : 999,
                  ),
                  if (isPlaying) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 104,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _MusicColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: List.generate(
                              4,
                              (index) => AnimatedContainer(
                                duration: Duration(
                                  milliseconds: 220 + index * 40,
                                ),
                                width: 3,
                                height: state.isPlaying
                                    ? (7 + (index % 3) * 4).toDouble()
                                    : 5,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: _MusicColors.primary.withValues(
                                    alpha: 0.72,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 7),
                    Image.asset(MusicAssets.decoNote, width: 22, height: 22),
                  ],
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
    final controller = ref.read(musicPlayerProvider.notifier);
    final track = state.currentTrack;
    final duration = state.effectiveDuration;
    final canSeek = duration > Duration.zero;
    final position = state.position > duration && canSeek
        ? duration
        : state.position;
    final progressValue = canSeek ? position.inMilliseconds.toDouble() : 0.0;
    final maxProgress = canSeek ? duration.inMilliseconds.toDouble() : 1.0;

    return Container(
      key: const ValueKey('music_float_expanded_frame'),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF6), Color(0xFFF7F1FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9DDF8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A7155B9),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -32,
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(MusicAssets.decoStar, width: 104),
            ),
          ),
          Positioned(
            right: 10,
            bottom: -18,
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(MusicAssets.catRelax, width: 126),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CoverImage(track: track, size: 74),
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
                        Text(
                          track == null ? '导入本地音乐开始播放' : '默认歌单',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _MusicColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 5,
                          color: _MusicColors.primary,
                          backgroundColor: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '收起',
                    onPressed: controller.collapse,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    color: _MusicColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      color: _MusicColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: _MusicColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
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
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    tooltip: '下一首',
                    icon: Icons.skip_next_rounded,
                    onPressed: state.hasTracks ? controller.playNext : null,
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    tooltip: track?.isFavorite == true ? '取消收藏' : '收藏',
                    icon: track?.isFavorite == true
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    onPressed: track == null
                        ? null
                        : () => controller.toggleFavorite(track),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.volume_down_rounded,
                    color: _MusicColors.muted,
                    size: 18,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: state.volume,
                        min: 0,
                        max: 1,
                        activeColor: _MusicColors.primary,
                        inactiveColor: Colors.white.withValues(alpha: 0.86),
                        onChanged: controller.setVolume,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                    icon: Icons.queue_music_rounded,
                    label: '播放列表',
                    onTap: () => _showPlaylistSheet(context),
                  ),
                  _ActionChipButton(
                    icon: Icons.favorite_rounded,
                    label: '收藏',
                    onTap: () => _showFavoritesSheet(context),
                  ),
                ],
              ),
            ],
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
      child: InkWell(
        onTap: onPressed,
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
    return InkWell(
      onTap: onTap,
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

void _showPlaylistSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MusicTrackSheet(type: _MusicSheetType.playlist),
  );
}

void _showFavoritesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MusicTrackSheet(type: _MusicSheetType.favorites),
  );
}

enum _MusicSheetType { playlist, favorites }

class _MusicTrackSheet extends ConsumerWidget {
  const _MusicTrackSheet({required this.type});

  final _MusicSheetType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final tracks = type == _MusicSheetType.playlist
        ? state.tracks
        : state.favoriteTracks;
    final isFavorites = type == _MusicSheetType.favorites;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.76,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x32715AA6),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE7DAF8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CoverImage(track: state.currentTrack, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFavorites ? '收藏歌曲' : '默认歌单',
                      style: const TextStyle(
                        color: _MusicColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isFavorites
                          ? '${tracks.length} 首喜欢的歌'
                          : '${state.tracks.length} 首本地音乐',
                      style: const TextStyle(
                        color: _MusicColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                isFavorites ? MusicAssets.catFavorite : MusicAssets.catPlaylist,
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: tracks.isEmpty
                ? _EmptyMusicList(
                    image: isFavorites
                        ? MusicAssets.emptyFavorite
                        : MusicAssets.emptyPlaylist,
                    title: isFavorites ? '还没有收藏歌曲' : '还没有本地音乐',
                    subtitle: isFavorites
                        ? '遇到喜欢的旋律，就点亮小爱心'
                        : '导入一首歌，让甜甜陪你听一会儿',
                    buttonLabel: isFavorites ? null : '导入音乐',
                    onButtonTap: isFavorites ? null : controller.importTracks,
                  )
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final selected = track.id == state.currentTrackId;
                      return _TrackTile(
                        track: track,
                        selected: selected,
                        onPlay: () => controller.playTrack(track),
                        onFavorite: () => controller.toggleFavorite(track),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMusicList extends StatelessWidget {
  const _EmptyMusicList({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onButtonTap,
  });

  final String image;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(image, width: 150, height: 150, fit: BoxFit.contain),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _MusicColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _MusicColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onButtonTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: _MusicColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.selected,
    required this.onPlay,
    required this.onFavorite,
  });

  final MusicTrack track;
  final bool selected;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final duration = track.durationMs == null
        ? '--:--'
        : _formatDuration(Duration(milliseconds: track.durationMs!));
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1E9FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFCDBBFF) : const Color(0xFFF0E8F5),
          ),
        ),
        child: Row(
          children: [
            _CoverImage(track: track, size: 48),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _MusicColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    duration,
                    style: const TextStyle(
                      color: _MusicColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: track.isFavorite ? '取消收藏' : '收藏',
              onPressed: onFavorite,
              icon: Icon(
                track.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              color: track.isFavorite
                  ? const Color(0xFFFF7BA9)
                  : _MusicColors.muted,
            ),
            Icon(
              selected ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
              color: _MusicColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _MusicColors {
  static const ink = Color(0xFF352F4F);
  static const muted = Color(0xFF8B8498);
  static const primary = Color(0xFF8B75F6);
}
