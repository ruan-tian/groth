import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../features/music/models/music_player_state.dart';
import '../../../features/music/providers/music_player_provider.dart';
import '../../../features/music/utils/music_assets.dart';
import '../../../shared/providers/focus_audio_provider.dart';
import '../utils/focus_options.dart';

class FocusSoundPanel extends ConsumerWidget {
  const FocusSoundPanel({
    super.key,
    required this.initialSoundType,
    this.compact = false,
    this.dark = false,
    this.onSoundChanged,
  });

  final String initialSoundType;
  final bool compact;
  final bool dark;
  final ValueChanged<String?>? onSoundChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(focusAudioStateProvider);
    final current = audioState.currentSoundType ?? initialSoundType;
    final musicMode = current == 'music';
    final titleColor = dark ? const Color(0xFFF9E8C8) : const Color(0xFF2D3636);
    final bodyColor = dark ? const Color(0xFFC6EDE7) : const Color(0xFF64716F);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xCC092A35)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0x66F5D9AC) : const Color(0xFFE8DDD1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: titleColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '专注声音',
                style: TextStyle(
                  color: titleColor,
                  fontSize: compact ? 15 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                musicMode
                    ? '本地音乐'
                    : audioState.isPlaying && current != 'none'
                    ? '白噪音播放中'
                    : '安静模式',
                style: TextStyle(
                  color: bodyColor,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AudioModeSwitch(
            musicMode: musicMode,
            dark: dark,
            onNoise: () {
              ref.read(musicPlayerProvider.notifier).pause();
              onSoundChanged?.call(null);
            },
            onMusic: () {
              ref.read(focusAudioStateProvider.notifier).stopNoise();
              onSoundChanged?.call('music');
            },
          ),
          const SizedBox(height: 14),
          if (musicMode)
            _FocusMusicPanel(
              compact: compact,
              dark: dark,
              onSoundChanged: onSoundChanged,
            )
          else
            _NoisePanel(
              current: current,
              compact: compact,
              dark: dark,
              titleColor: titleColor,
              bodyColor: bodyColor,
              onSoundChanged: onSoundChanged,
            ),
        ],
      ),
    );
  }
}

class _AudioModeSwitch extends StatelessWidget {
  const _AudioModeSwitch({
    required this.musicMode,
    required this.dark,
    required this.onNoise,
    required this.onMusic,
  });

  final bool musicMode;
  final bool dark;
  final VoidCallback onNoise;
  final VoidCallback onMusic;

  @override
  Widget build(BuildContext context) {
    final activeColor = dark ? const Color(0xFFBDF5E5) : const Color(0xFF3EB3A7);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF0F6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: '白噪音',
            selected: !musicMode,
            activeColor: activeColor,
            dark: dark,
            onTap: onNoise,
          ),
          _ModeButton(
            label: '本地音乐',
            selected: musicMode,
            activeColor: activeColor,
            dark: dark,
            onTap: onMusic,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? activeColor
                  : (dark ? const Color(0xFFEBDCC2) : const Color(0xFF5D6765)),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoisePanel extends ConsumerWidget {
  const _NoisePanel({
    required this.current,
    required this.compact,
    required this.dark,
    required this.titleColor,
    required this.bodyColor,
    required this.onSoundChanged,
  });

  final String current;
  final bool compact;
  final bool dark;
  final Color titleColor;
  final Color bodyColor;
  final ValueChanged<String?>? onSoundChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: compact ? 8 : 10,
          runSpacing: compact ? 8 : 10,
          children: focusSoundOptions
              .map((sound) {
                final selected = current == sound.value;
                return _SessionSoundTile(
                  label: sound.label,
                  asset: sound.asset,
                  selected: selected,
                  compact: compact,
                  dark: dark,
                  onTap: () {
                    ref.read(musicPlayerProvider.notifier).pause();
                    if (sound.value == 'none') {
                      ref.read(focusAudioStateProvider.notifier).stopNoise();
                      onSoundChanged?.call(null);
                    } else {
                      ref
                          .read(focusAudioStateProvider.notifier)
                          .changeSound(sound.value);
                      onSoundChanged?.call(sound.value);
                    }
                  },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              '音量',
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.volume_down_rounded, size: 18, color: bodyColor),
            Expanded(
              child: Slider(
                value: ref.watch(focusAudioStateProvider).volume,
                min: 0,
                max: 1,
                divisions: 20,
                activeColor: const Color(0xFF9DEBD8),
                inactiveColor: dark
                    ? const Color(0x335BE0C8)
                    : const Color(0xFFE1ECE9),
                onChanged: (value) {
                  ref.read(focusAudioStateProvider.notifier).setVolume(value);
                },
              ),
            ),
            Text(
              '${(ref.watch(focusAudioStateProvider).volume * 100).round()}%',
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusMusicPanel extends ConsumerWidget {
  const _FocusMusicPanel({
    required this.compact,
    required this.dark,
    required this.onSoundChanged,
  });

  final bool compact;
  final bool dark;
  final ValueChanged<String?>? onSoundChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final track = state.currentTrack;
    final textColor = dark ? const Color(0xFFF9E8C8) : const Color(0xFF2D3636);
    final muted = dark ? const Color(0xFFC6EDE7) : const Color(0xFF64716F);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? const Color(0x337F9FA4) : const Color(0xFFE5DDD5),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  track?.coverAsset ?? MusicAssets.coverDefault,
                  width: compact ? 44 : 52,
                  height: compact ? 44 : 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track?.title ?? '导入本地音乐',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.selectedCollection.label} · ${state.selectedTracks.length} 首',
                      style: TextStyle(
                        color: muted,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _FocusMusicButton(
                icon: state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                dark: dark,
                onTap: () {
                  onSoundChanged?.call('music');
                  ref.read(focusAudioStateProvider.notifier).stopNoise();
                  controller.togglePlayPause();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _FocusMusicButton(
              icon: Icons.skip_previous_rounded,
              dark: dark,
              onTap: state.hasTracks ? controller.playPrevious : null,
            ),
            const SizedBox(width: 8),
            _FocusMusicButton(
              icon: Icons.skip_next_rounded,
              dark: dark,
              onTap: state.hasTracks ? controller.playNext : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FocusCollectionButton(state: state, dark: dark),
            ),
            const SizedBox(width: 8),
            _FocusMusicButton(
              icon: state.isImporting
                  ? Icons.hourglass_empty_rounded
                  : Icons.add_rounded,
              dark: dark,
              onTap: state.isImporting ? null : controller.importTracks,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.volume_down_rounded, size: 18, color: muted),
            Expanded(
              child: Slider(
                value: state.volume,
                min: 0,
                max: 1,
                divisions: 20,
                activeColor: const Color(0xFF9DEBD8),
                inactiveColor: dark
                    ? const Color(0x335BE0C8)
                    : const Color(0xFFE1ECE9),
                onChanged: controller.setVolume,
              ),
            ),
            Text(
              '${(state.volume * 100).round()}%',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusCollectionButton extends ConsumerWidget {
  const _FocusCollectionButton({required this.state, required this.dark});

  final MusicPlayerState state;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showFocusMusicList(context, ref),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark ? const Color(0x337F9FA4) : const Color(0xFFE5DDD5),
          ),
        ),
        child: Text(
          '${state.selectedCollection.label} · ${state.selectedTracks.length}',
          style: TextStyle(
            color: dark ? const Color(0xFFF9E8C8) : const Color(0xFF2D3636),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FocusMusicButton extends StatelessWidget {
  const _FocusMusicButton({
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark ? const Color(0x337F9FA4) : const Color(0xFFE5DDD5),
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? const Color(0x777F9FA4)
              : dark
              ? const Color(0xFFBDF5E5)
              : const Color(0xFF3EB3A7),
        ),
      ),
    );
  }
}

class _SessionSoundTile extends StatelessWidget {
  const _SessionSoundTile({
    required this.label,
    required this.asset,
    required this.selected,
    required this.compact,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final bool compact;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = dark
        ? const Color(0xFFBDF5E5)
        : const Color(0xFF3EB3A7);
    final textColor = selected
        ? selectedColor
        : dark
        ? const Color(0xFFEBDCC2)
        : const Color(0xFF5D6765);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: compact ? 74 : 84,
        padding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 10,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: dark ? 0.16 : 0.12)
              : (dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? selectedColor
                : (dark ? const Color(0x337F9FA4) : const Color(0xFFE5DDD5)),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: compact ? 32 : 38,
              height: compact ? 32 : 38,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: compact ? 11 : 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 歌曲列表 BottomSheet
// ---------------------------------------------------------------------------

void _showFocusMusicList(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FocusMusicListSheet(),
  );
}

class _FocusMusicListSheet extends ConsumerStatefulWidget {
  const _FocusMusicListSheet();

  @override
  ConsumerState<_FocusMusicListSheet> createState() =>
      _FocusMusicListSheetState();
}

class _FocusMusicListSheetState extends ConsumerState<_FocusMusicListSheet> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final collection = ref.read(musicPlayerProvider).selectedCollection;
    _pageController = PageController(initialPage: collection.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final tracks = state.selectedTracks;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0D2B36),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 拖拽条
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF7F9FA4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  '选择音乐',
                  style: TextStyle(
                    color: Color(0xFFF9E8C8),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tracks.length} 首',
                  style: const TextStyle(
                    color: Color(0xFFC6EDE7),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 歌单标签切换
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCollectionTabs(state, controller),
          ),
          const SizedBox(height: 12),
          // 歌曲列表
          Expanded(
            child: tracks.isEmpty
                ? _buildEmptyState()
                : _buildTrackList(tracks, state, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTabs(
    MusicPlayerState state,
    MusicPlayerController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A44),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: MusicCollection.values.map((collection) {
          final active = collection == state.selectedCollection;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                controller.selectCollection(collection);
                _pageController.animateToPage(
                  collection.index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF2A5A64)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  collection.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFFF9E8C8)
                        : const Color(0xFF7F9FA4),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 48,
            color: const Color(0xFF7F9FA4).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            '还没有音乐',
            style: TextStyle(
              color: Color(0xFFF9E8C8),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '点击下方按钮导入本地音乐',
            style: TextStyle(
              color: Color(0xFF7F9FA4),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(
    List<MusicTrack> tracks,
    MusicPlayerState state,
    MusicPlayerController controller,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final selected = track.id == state.currentTrackId;
        return _buildTrackTile(track, selected, controller);
      },
    );
  }

  Widget _buildTrackTile(
    MusicTrack track,
    bool selected,
    MusicPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        controller.playTrack(track);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2A5A64)
              : const Color(0xFF1A3A44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF9DEBD8).withValues(alpha: 0.5)
                : const Color(0x337F9FA4),
          ),
        ),
        child: Row(
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                track.coverAsset ?? MusicAssets.coverDefault,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFF9E8C8)
                          : const Color(0xFFC6EDE7),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.durationMs != null
                        ? _formatDuration(
                            Duration(milliseconds: track.durationMs!),
                          )
                        : '--:--',
                    style: const TextStyle(
                      color: Color(0xFF7F9FA4),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // 播放图标
            if (selected)
              const Icon(
                Icons.equalizer_rounded,
                color: Color(0xFF9DEBD8),
                size: 20,
              )
            else
              const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF7F9FA4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
