part of 'dashboard_music_float.dart';

class _MusicLibrarySheet extends ConsumerStatefulWidget {
  const _MusicLibrarySheet();

  @override
  ConsumerState<_MusicLibrarySheet> createState() => _MusicLibrarySheetState();
}

class _MusicLibrarySheetState extends ConsumerState<_MusicLibrarySheet> {
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

    return GrowthEntrance(
      duration: AppMotion.normal,
      offset: const Offset(0, 14),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.78,
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
        child: SafeArea(
          top: false,
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _CoverImage(track: state.currentTrack, size: 62),
                      Positioned(
                        right: -8,
                        bottom: -5,
                        child: Image.asset(
                          MusicAssets.itemVinyl,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '音乐库',
                          style: TextStyle(
                            color: _MusicColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '左右滑动切换歌单 · ${state.tracks.length} 首本地音乐',
                          style: const TextStyle(
                            color: _MusicColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        MusicAssets.decoSparkle,
                        width: 78,
                        height: 78,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        MusicAssets.catPlaylist,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LibraryTabs(
                selected: state.selectedCollection,
                onSelected: (collection) {
                  controller.selectCollection(collection);
                  _pageController.animateToPage(
                    collection.index,
                    duration: AppMotion.normal,
                    curve: AppMotion.standard,
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    controller.selectCollection(MusicCollection.values[index]);
                  },
                  children: MusicCollection.values
                      .map((collection) {
                        return _MusicTrackList(
                          collection: collection,
                          tracks: state.tracksForCollection(collection),
                          state: state,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: MusicCollection.values
            .map((collection) {
              final active = collection == selected;
              return Expanded(
                child: GrowthPressable(
                  onTap: () => onSelected(collection),
                  semanticLabel: collection.label,
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: AppMotion.duration(context, AppMotion.normal),
                    curve: AppMotion.standard,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                color: Color(0x198B75F6),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      collection.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active
                            ? _MusicColors.primary
                            : _MusicColors.muted,
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

class _MusicTrackList extends ConsumerWidget {
  const _MusicTrackList({
    required this.collection,
    required this.tracks,
    required this.state,
  });

  final MusicCollection collection;
  final List<MusicTrack> tracks;
  final MusicPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(musicPlayerProvider.notifier);
    if (tracks.isEmpty) {
      return _EmptyMusicList(
        collection: collection,
        onImport: collection == MusicCollection.all
            ? controller.importTracks
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
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
    );
  }
}

class _EmptyMusicList extends StatelessWidget {
  const _EmptyMusicList({required this.collection, required this.onImport});

  final MusicCollection collection;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final image = switch (collection) {
      MusicCollection.all => MusicAssets.emptyImport,
      MusicCollection.favorites => MusicAssets.emptyFavorite,
      MusicCollection.recent => MusicAssets.emptyHistory,
    };
    final title = switch (collection) {
      MusicCollection.all => '还没有本地音乐',
      MusicCollection.favorites => '还没有收藏歌曲',
      MusicCollection.recent => '还没有最近播放',
    };
    final subtitle = switch (collection) {
      MusicCollection.all => '导入一首歌，让甜甜陪你听一会儿',
      MusicCollection.favorites => '遇到喜欢的旋律，就点亮小爱心',
      MusicCollection.recent => '播放过的歌曲会出现在这里',
    };

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
          if (onImport != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add_rounded),
              label: const Text('导入音乐'),
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

class _TrackTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = track.durationMs == null
        ? '--:--'
        : _formatDuration(Duration(milliseconds: track.durationMs!));
    return GrowthPressable(
      onTap: onPlay,
      onLongPress: () => _showTrackOptions(context, ref),
      semanticLabel: track.title,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1E9FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFCDBBFF) : const Color(0xFFF0E8F5),
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1A8B75F6),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ]
              : null,
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

  void _showTrackOptions(BuildContext context, WidgetRef ref) {
    final controller = ref.read(musicPlayerProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
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
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    _CoverImage(track: track, size: 62),
                    const SizedBox(width: 12),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            track.artist ?? '未知艺术家',
                            style: const TextStyle(
                              color: _MusicColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildOption(
                  context,
                  icon: track.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: track.isFavorite ? '取消收藏' : '收藏',
                  color: track.isFavorite
                      ? const Color(0xFFFF7BA9)
                      : _MusicColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    controller.toggleFavorite(track);
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.delete_rounded,
                  label: '删除',
                  color: const Color(0xFFFF4757),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, ref);
                  },
                ),
                _buildOption(
                  context,
                  icon: Icons.close_rounded,
                  label: '取消',
                  color: _MusicColors.muted,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GrowthPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E8F5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('确认删除'),
          content: Text('确定要删除 "${track.title}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(musicPlayerProvider.notifier).deleteTrack(track.id);
              },
              child: const Text(
                '删除',
                style: TextStyle(color: Color(0xFFFF4757)),
              ),
            ),
          ],
        );
      },
    );
  }
}
