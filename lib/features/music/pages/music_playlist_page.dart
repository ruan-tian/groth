import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../models/music_player_state.dart';
import '../providers/music_player_provider.dart';
import '../utils/music_assets.dart';
import '../utils/music_scene.dart';
import '../widgets/music_import_destination_sheet.dart';

class MusicPlaylistPage extends ConsumerStatefulWidget {
  const MusicPlaylistPage({super.key});

  @override
  ConsumerState<MusicPlaylistPage> createState() => _MusicPlaylistPageState();
}

class _MusicPlaylistPageState extends ConsumerState<MusicPlaylistPage> {
  MusicScene? _selectedScene;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final state = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final baseTracks = state.selectedTracks;
    final selectedTracks = _selectedScene == null
        ? baseTracks
        : baseTracks
              .where(
                (track) =>
                    MusicSceneResolver.matchesTrack(track, _selectedScene!),
              )
              .toList(growable: false);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              colors.softPink.withValues(alpha: 0.46),
              colors.paper,
            ],
            stops: const [0.0, 0.54, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _MusicSpaceNav(
                onBack: () => Navigator.of(context).maybePop(),
                onImport: () {
                  showMusicImportDestinationSheet(
                    context,
                    ref,
                    initialScene: _selectedScene,
                  );
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MusicHero(state: state, selectedScene: _selectedScene),
                      const SizedBox(height: 14),
                      const _ImportActions(),
                      const SizedBox(height: 14),
                      _MusicStats(state: state),
                      const SizedBox(height: 14),
                      _ContinuePlayingCard(
                        state: state,
                        controller: controller,
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle(title: '情绪歌单'),
                      const SizedBox(height: 10),
                      _ScenePlaylistRail(
                        tracks: baseTracks,
                        selectedScene: _selectedScene,
                        onSelected: (scene) {
                          setState(() {
                            _selectedScene = _selectedScene == scene
                                ? null
                                : scene;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _CustomPlaylistRail(
                        playlists: state.playlists,
                        selectedPlaylistId: state.selectedPlaylistId,
                        onCreate: () async {
                          final playlistId =
                              await showCreateMusicPlaylistDialog(context);
                          if (playlistId != null) {
                            ref
                                .read(musicPlayerProvider.notifier)
                                .selectPlaylist(playlistId);
                          }
                        },
                        onSelected: (playlistId) {
                          setState(() => _selectedScene = null);
                          ref
                              .read(musicPlayerProvider.notifier)
                              .selectPlaylist(playlistId);
                        },
                      ),
                      const SizedBox(height: 20),
                      _LibraryTabs(
                        selected: state.selectedCollection,
                        onSelected: controller.selectCollection,
                      ),
                      const SizedBox(height: 12),
                      if (state.selectedPlaylist != null) ...[
                        _PlaylistFilterPill(
                          playlist: state.selectedPlaylist!,
                          count: selectedTracks.length,
                          onClear: () {
                            ref
                                .read(musicPlayerProvider.notifier)
                                .selectCollection(MusicCollection.all);
                          },
                        ),
                        const SizedBox(height: 12),
                      ] else if (_selectedScene != null) ...[
                        _SceneFilterPill(
                          artwork: MusicArtworkMapper.forScene(_selectedScene!),
                          count: selectedTracks.length,
                          onClear: () => setState(() {
                            _selectedScene = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (selectedTracks.isEmpty)
                        _MusicEmptyState(
                          collection: state.selectedCollection,
                          scene: _selectedScene,
                          onImport: () {
                            showMusicImportDestinationSheet(
                              context,
                              ref,
                              initialScene: _selectedScene,
                            );
                          },
                        )
                      else
                        _TrackList(
                          tracks: selectedTracks,
                          state: state,
                          controller: controller,
                        ),
                    ],
                  ),
                ),
              ),
              if (state.hasTracks)
                _MiniPlayerBar(state: state, controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicSpaceNav extends StatelessWidget {
  const _MusicSpaceNav({required this.onBack, required this.onImport});

  final VoidCallback onBack;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19,
              color: colors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              '音乐空间',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: '导入音乐',
            onPressed: onImport,
            icon: Icon(
              Icons.library_music_rounded,
              size: 22,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicHero extends StatelessWidget {
  const _MusicHero({required this.state, required this.selectedScene});

  final MusicPlayerState state;
  final MusicScene? selectedScene;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final track = state.currentTrack;
    final artwork = selectedScene == null
        ? MusicArtworkMapper.forTrack(track)
        : MusicArtworkMapper.forScene(selectedScene!);
    final title = selectedScene == null ? '音乐空间' : '${artwork.label}空间';
    final subtitle = selectedScene == null ? '本地音乐，陪你进入状态' : artwork.subtitle;

    return Container(
      height: 156,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.card,
            colors.softPink.withValues(alpha: 0.64),
            colors.softPurple.withValues(alpha: 0.52),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -18,
            child: Opacity(
              opacity: 0.42,
              child: Image.asset(artwork.decorations.last, width: 74),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -4,
            child: Image.asset(artwork.cat, width: 118, height: 118),
          ),
          Positioned(
            left: 0,
            right: 116,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset(MusicAssets.decoStarMusic, width: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _NowStatusPill(
                  isPlaying: state.isPlaying,
                  text: state.isPlaying
                      ? '正在播放'
                      : track == null
                      ? '等待导入'
                      : '准备播放',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportActions extends ConsumerWidget {
  const _ImportActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.folder_copy_rounded,
            asset: MusicAssets.settingImport,
            title: '导入音乐',
            subtitle: '选择歌曲文件',
            color: colors.success,
            onTap: () {
              showMusicImportDestinationSheet(context, ref);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.drive_folder_upload_rounded,
            asset: MusicAssets.settingScene,
            title: '扫描文件夹',
            subtitle: '批量加入本地音频',
            color: colors.primary,
            onTap: () {
              showMusicImportDestinationSheet(context, ref, scanFolder: true);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String asset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 76,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(asset, width: 42, height: 42),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
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
          ],
        ),
      ),
    );
  }
}

class _MusicStats extends StatelessWidget {
  const _MusicStats({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _StatItem(value: '${state.tracks.length}', label: '全部歌曲'),
          _StatItem(value: '${state.favoriteTracks.length}', label: '收藏歌曲'),
          _StatItem(value: '${state.recentTracks.length}', label: '最近播放'),
          _StatItem(value: state.playModeLabel, label: '播放模式'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
    );
  }
}

class _ContinuePlayingCard extends StatelessWidget {
  const _ContinuePlayingCard({required this.state, required this.controller});

  final MusicPlayerState state;
  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final track = state.currentTrack;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CoverArt(track: track, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '继续播放',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  track?.title ?? '导入一首本地音乐',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: state.isPlaying ? '暂停' : '播放',
            onPressed: controller.togglePlayPause,
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnAccent,
            ),
            icon: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePlaylistRail extends StatelessWidget {
  const _ScenePlaylistRail({
    required this.tracks,
    required this.selectedScene,
    required this.onSelected,
  });

  final List<MusicTrack> tracks;
  final MusicScene? selectedScene;
  final ValueChanged<MusicScene> onSelected;

  @override
  Widget build(BuildContext context) {
    final scenes = MusicArtworkMapper.playlistScenes
        .map(MusicArtworkMapper.forScene)
        .toList(growable: false);

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: scenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final artwork = scenes[index];
          final count = tracks
              .where(
                (track) =>
                    MusicSceneResolver.matchesTrack(track, artwork.scene),
              )
              .length;
          return _ScenePlaylistCard(
            artwork: artwork,
            count: count,
            selected: selectedScene == artwork.scene,
            onTap: () => onSelected(artwork.scene),
          );
        },
      ),
    );
  }
}

class _ScenePlaylistCard extends StatelessWidget {
  const _ScenePlaylistCard({
    required this.artwork,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final MusicSceneArtwork artwork;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 136,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(artwork.playlistCover),
            fit: BoxFit.cover,
            opacity: selected ? 0.34 : 0.24,
          ),
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -7,
              child: Opacity(
                opacity: selected ? 1 : 0.85,
                child: Image.asset(artwork.cat, width: 64, height: 64),
              ),
            ),
            Positioned(
              right: 6,
              top: 2,
              child: Opacity(
                opacity: 0.58,
                child: Image.asset(
                  artwork.decorations.first,
                  width: 26,
                  height: 26,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artwork.subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary
                        : colors.card.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_rounded
                            : Icons.playlist_play_rounded,
                        color: selected ? colors.textOnAccent : colors.primary,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: selected
                              ? colors.textOnAccent
                              : colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneFilterPill extends StatelessWidget {
  const _SceneFilterPill({
    required this.artwork,
    required this.count,
    required this.onClear,
  });

  final MusicSceneArtwork artwork;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: colors.softPurple.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Image.asset(artwork.decorations.first, width: 22, height: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${artwork.label}场景 · $count 首',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '清除筛选',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _CustomPlaylistRail extends StatelessWidget {
  const _CustomPlaylistRail({
    required this.playlists,
    required this.selectedPlaylistId,
    required this.onCreate,
    required this.onSelected,
  });

  final List<MusicPlaylist> playlists;
  final int? selectedPlaylistId;
  final VoidCallback onCreate;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '我的歌单'),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: playlists.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == playlists.length) {
                return _CreateCustomPlaylistCard(onTap: onCreate);
              }
              final playlist = playlists[index];
              return _CustomPlaylistCard(
                playlist: playlist,
                selected: selectedPlaylistId == playlist.id,
                onTap: () => onSelected(playlist.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CreateCustomPlaylistCard extends StatelessWidget {
  const _CreateCustomPlaylistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.softPurple.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: colors.primary, size: 34),
            SizedBox(height: 8),
            Text(
              '新建歌单',
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomPlaylistCard extends StatelessWidget {
  const _CustomPlaylistCard({
    required this.playlist,
    required this.selected,
    required this.onTap,
  });

  final MusicPlaylist playlist;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final cover = playlist.coverAsset ?? MusicAssets.playlistCustom01;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 156,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? colors.softPurple.withValues(alpha: 0.62)
              : colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                cover,
                width: 72,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.primary : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.playlist_play_rounded,
                    color: selected ? colors.primary : colors.textSecondary,
                    size: 20,
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

class _PlaylistFilterPill extends StatelessWidget {
  const _PlaylistFilterPill({
    required this.playlist,
    required this.count,
    required this.onClear,
  });

  final MusicPlaylist playlist;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final cover = playlist.coverAsset ?? MusicAssets.playlistCustom01;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: colors.softPurple.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(cover, width: 30, height: 30, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${playlist.name} · $count 首',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '清除歌单',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs({required this.selected, required this.onSelected});

  final MusicCollection selected;
  final ValueChanged<MusicCollection> onSelected;

  @override
  Widget build(BuildContext context) {
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
              final active = collection == selected;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelected(collection),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? colors.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      collection.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? colors.primary : colors.textSecondary,
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
}

class _TrackList extends ConsumerWidget {
  const _TrackList({
    required this.tracks,
    required this.state,
    required this.controller,
  });

  final List<MusicTrack> tracks;
  final MusicPlayerState state;
  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final selected = track.id == state.currentTrackId;
        return _SpaceTrackTile(
          track: track,
          selected: selected,
          isPlaying: selected && state.isPlaying,
          onPlay: () => controller.playTrackFromQueue(track, tracks),
          onFavorite: () => controller.toggleFavorite(track),
          onManagePlaylists: () => showTrackPlaylistSheet(context, ref, track),
        );
      },
    );
  }
}

class _SpaceTrackTile extends StatelessWidget {
  const _SpaceTrackTile({
    required this.track,
    required this.selected,
    required this.isPlaying,
    required this.onPlay,
    required this.onFavorite,
    required this.onManagePlaylists,
  });

  final MusicTrack track;
  final bool selected;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;
  final VoidCallback onManagePlaylists;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final duration = track.durationMs == null
        ? '--:--'
        : _formatDuration(Duration(milliseconds: track.durationMs!));

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? colors.softPurple.withValues(alpha: 0.58)
              : colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Row(
          children: [
            _CoverArt(track: track, size: 48),
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
                      color: selected ? colors.primary : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    duration,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '管理歌单',
              onPressed: onManagePlaylists,
              icon: const Icon(Icons.playlist_add_check_rounded),
              color: colors.primary,
            ),
            IconButton(
              tooltip: track.isFavorite ? '取消收藏' : '收藏',
              onPressed: onFavorite,
              icon: Icon(
                track.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              color: track.isFavorite ? colors.danger : colors.textSecondary,
            ),
            Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicEmptyState extends StatelessWidget {
  const _MusicEmptyState({
    required this.collection,
    required this.scene,
    required this.onImport,
  });

  final MusicCollection collection;
  final MusicScene? scene;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final sceneArtwork = scene == null
        ? null
        : MusicArtworkMapper.forScene(scene!);
    final image = switch (collection) {
      MusicCollection.all => MusicAssets.emptyImport,
      MusicCollection.favorites => MusicAssets.emptyFavorite,
      MusicCollection.recent => MusicAssets.emptyHistory,
    };
    final title = sceneArtwork == null
        ? switch (collection) {
            MusicCollection.all => '还没有本地音乐',
            MusicCollection.favorites => '还没有收藏歌曲',
            MusicCollection.recent => '还没有最近播放',
          }
        : '${sceneArtwork.label}场景还没有歌曲';
    final subtitle = sceneArtwork == null
        ? switch (collection) {
            MusicCollection.all => '导入音乐后，它会在这里陪你进入状态',
            MusicCollection.favorites => '喜欢的旋律点亮爱心，就会住进这里',
            MusicCollection.recent => '播放过的歌曲会自动整理到这里',
          }
        : '把歌名或文件夹命名成 ${sceneArtwork.label} / ${sceneArtwork.subtitle} 一类词，就会自动归到这里';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Image.asset(sceneArtwork?.cat ?? image, width: 150, height: 150),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (collection == MusicCollection.all) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.library_music_rounded),
              label: const Text('导入音乐'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  const _MiniPlayerBar({required this.state, required this.controller});

  final MusicPlayerState state;
  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final track = state.currentTrack;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _CoverArt(track: track, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.title ?? '甜甜音乐',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  track?.artist ?? '本地音乐',
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
          // 播放模式
          IconButton(
            tooltip: state.playModeLabel,
            onPressed: controller.togglePlayMode,
            icon: Icon(
              _playModeIcon(state.playMode),
              color: colors.textSecondary,
              size: 20,
            ),
          ),
          // 上一首
          IconButton(
            tooltip: '上一首',
            onPressed: controller.playPrevious,
            icon: Icon(Icons.skip_previous_rounded, color: colors.textPrimary),
          ),
          // 播放/暂停
          IconButton(
            tooltip: state.isPlaying ? '暂停' : '播放',
            onPressed: controller.togglePlayPause,
            icon: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: colors.primary,
            ),
          ),
          // 下一首
          IconButton(
            tooltip: '下一首',
            onPressed: controller.playNext,
            icon: Icon(Icons.skip_next_rounded, color: colors.textPrimary),
          ),
          // 音量
          IconButton(
            tooltip: '音量',
            onPressed: () => _showVolumeSheet(context),
            icon: Icon(
              state.volume > 0.5
                  ? Icons.volume_up_rounded
                  : state.volume > 0
                  ? Icons.volume_down_rounded
                  : Icons.volume_off_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt({required this.track, required this.size});

  final MusicTrack? track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          MusicArtworkMapper.coverForTrack(track),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _NowStatusPill extends StatelessWidget {
  const _NowStatusPill({required this.isPlaying, required this.text});

  final bool isPlaying;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
            size: 15,
            color: colors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Container(
          width: 4,
          height: 15,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
