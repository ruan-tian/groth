import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../features/music/models/music_player_state.dart';
import '../../../features/music/utils/music_assets.dart';
import '../../../shared/providers/focus_audio_provider.dart';
import '../providers/focus_music_facade.dart';
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
    final colors = context.growthColors;
    final audioState = ref.watch(focusAudioStateProvider);
    final current = audioState.currentSoundType ?? initialSoundType;
    final musicMode = current == 'music';

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: (dark ? colors.card : colors.paper).withValues(
          alpha: dark ? 0.88 : 0.82,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.76)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: dark ? 0.55 : 0.32),
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
              Icon(
                Icons.music_note_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '专注声音',
                style: TextStyle(
                  color: colors.textPrimary,
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
                  color: colors.textSecondary,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AudioModeSwitch(
            musicMode: musicMode,
            onNoise: () => onSoundChanged?.call(null),
            onMusic: () => onSoundChanged?.call('music'),
          ),
          const SizedBox(height: 14),
          if (musicMode)
            _FocusMusicPanel(compact: compact, onSoundChanged: onSoundChanged)
          else
            _NoisePanel(
              current: current,
              compact: compact,
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
    required this.onNoise,
    required this.onMusic,
  });

  final bool musicMode;
  final VoidCallback onNoise;
  final VoidCallback onMusic;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: '白噪音',
            selected: !musicMode,
            activeColor: colors.focus,
            onTap: onNoise,
          ),
          _ModeButton(
            label: '本地音乐',
            selected: musicMode,
            activeColor: colors.focus,
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
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? activeColor : colors.textSecondary,
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
    required this.onSoundChanged,
  });

  final String current;
  final bool compact;
  final ValueChanged<String?>? onSoundChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
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
                  onTap: () {
                    onSoundChanged?.call(sound.value == 'none' ? null : sound.value);
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
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.volume_down_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
            Expanded(
              child: Slider(
                value: ref.watch(focusAudioStateProvider).volume,
                min: 0,
                max: 1,
                divisions: 20,
                activeColor: colors.focus,
                inactiveColor: colors.border.withValues(alpha: 0.55),
                onChanged: (value) {
                  ref.read(focusAudioStateProvider.notifier).setVolume(value);
                },
              ),
            ),
            Text(
              '${(ref.watch(focusAudioStateProvider).volume * 100).round()}%',
              style: TextStyle(
                color: colors.textPrimary,
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
  const _FocusMusicPanel({required this.compact, required this.onSoundChanged});

  final bool compact;
  final ValueChanged<String?>? onSoundChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final facade = ref.watch(focusMusicFacadeProvider);
    final state = facade.watchState();
    final track = state.currentTrack;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
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
                        color: colors.textPrimary,
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.selectedCollection.label} · ${state.selectedTracks.length} 首',
                      style: TextStyle(
                        color: colors.textSecondary,
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
                onTap: () {
                  onSoundChanged?.call('music');
                  ref.read(focusAudioStateProvider.notifier).stopNoise();
                  facade.togglePlayPause();
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
              onTap: state.hasTracks ? facade.playPrevious : null,
            ),
            const SizedBox(width: 8),
            _FocusMusicButton(
              icon: Icons.skip_next_rounded,
              onTap: state.hasTracks ? facade.playNext : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: _FocusCollectionButton(state: state)),
            const SizedBox(width: 8),
            _FocusMusicButton(
              icon: state.isImporting
                  ? Icons.hourglass_empty_rounded
                  : Icons.add_rounded,
              onTap: state.isImporting ? null : () => facade.controller.importTracks(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.volume_down_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
            Expanded(
              child: Slider(
                value: state.volume,
                min: 0,
                max: 1,
                divisions: 20,
                activeColor: colors.focus,
                inactiveColor: colors.border.withValues(alpha: 0.55),
                onChanged: facade.setVolume,
              ),
            ),
            Text(
              '${(state.volume * 100).round()}%',
              style: TextStyle(
                color: colors.textPrimary,
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
  const _FocusCollectionButton({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: () => _showFocusMusicList(context, ref),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
        child: Text(
          '${state.selectedCollection.label} · ${state.selectedTracks.length}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FocusMusicButton extends StatelessWidget {
  const _FocusMusicButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
        child: Icon(
          icon,
          color: onTap == null ? colors.textHint : colors.focus,
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
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final selectedColor = colors.focus;

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
              ? selectedColor.withValues(alpha: 0.14)
              : colors.surface.withValues(alpha: 0.64),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? selectedColor
                : colors.border.withValues(alpha: 0.7),
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
                color: selected ? selectedColor : colors.textSecondary,
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
    final facade = ref.read(focusMusicFacadeProvider);
    final collection = facade.selectedCollection;
    _pageController = PageController(initialPage: collection.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final facade = ref.watch(focusMusicFacadeProvider);
    final state = facade.watchState();
    final tracks = state.selectedTracks;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '选择音乐',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tracks.length} 首',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCollectionTabs(state, facade),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tracks.isEmpty
                ? _buildEmptyState()
                : _buildTrackList(tracks, state, facade),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTabs(
    MusicPlayerState state,
    FocusMusicFacade facade,
  ) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: MusicCollection.values
            .map((collection) {
              final active = collection == state.selectedCollection;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    facade.controller.selectCollection(collection);
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
                          ? colors.focus.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      collection.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? colors.focus : colors.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.growthColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 48,
            color: colors.textHint.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            '还没有音乐',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点击面板上的加号导入本地音乐',
            style: TextStyle(
              color: colors.textTertiary,
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
    FocusMusicFacade facade,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final selected = track.id == state.currentTrackId;
        return _buildTrackTile(track, selected, facade);
      },
    );
  }

  Widget _buildTrackTile(
    MusicTrack track,
    bool selected,
    FocusMusicFacade facade,
  ) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: () {
        facade.controller.playTrack(track);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? colors.focus.withValues(alpha: 0.14)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colors.focus.withValues(alpha: 0.5)
                : colors.border.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.focus : colors.textPrimary,
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
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
              color: selected ? colors.focus : colors.textTertiary,
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
