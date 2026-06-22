import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../providers/music_player_provider.dart';
import '../utils/default_music_seed.dart';
import '../utils/music_assets.dart';
import '../utils/music_scene.dart';

Future<void> showMusicImportDestinationSheet(
  BuildContext context,
  WidgetRef ref, {
  bool scanFolder = false,
  MusicScene? initialScene,
}) async {
  final destination = await showModalBottomSheet<_MusicImportDestination>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MusicImportDestinationSheet(initialScene: initialScene),
  );
  if (destination == null || !context.mounted) return;

  final controller = ref.read(musicPlayerProvider.notifier);
  if (scanFolder) {
    await controller.scanFolder(
      playlistIds: destination.playlistIds,
      sceneOverride: destination.scene,
    );
  } else {
    await controller.importTracks(
      playlistIds: destination.playlistIds,
      sceneOverride: destination.scene,
    );
  }
}

class _MusicImportDestination {
  const _MusicImportDestination({
    required this.playlistIds,
    required this.scene,
  });

  final Set<int> playlistIds;
  final MusicScene? scene;
}

Future<int?> showCreateMusicPlaylistDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _CreatePlaylistDialog(),
  );
}

Future<void> showTrackPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  MusicTrack track,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrackPlaylistSheet(track: track),
  );
}

class _MusicImportDestinationSheet extends ConsumerStatefulWidget {
  const _MusicImportDestinationSheet({this.initialScene});

  final MusicScene? initialScene;

  @override
  ConsumerState<_MusicImportDestinationSheet> createState() =>
      _MusicImportDestinationSheetState();
}

class _MusicImportDestinationSheetState
    extends ConsumerState<_MusicImportDestinationSheet> {
  final Set<int> _selectedIds = {};
  MusicScene? _selectedScene;

  @override
  void initState() {
    super.initState();
    _selectedScene = widget.initialScene;
    final selectedPlaylistId = ref.read(musicPlayerProvider).selectedPlaylistId;
    if (selectedPlaylistId != null) {
      _selectedIds.add(selectedPlaylistId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final state = ref.watch(musicPlayerProvider);
    final playlists = state.playlists;
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(30),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Image.asset(MusicAssets.settingImport, width: 48, height: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u5bfc\u5165\u5230\u6b4c\u5355',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u6b4c\u66f2\u59cb\u7ec8\u4f1a\u8fdb\u5165\u5168\u90e8\u672c\u5730\uff0c\u4e5f\u53ef\u4ee5\u540c\u65f6\u52a0\u5165\u591a\u4e2a\u81ea\u5efa\u6b4c\u5355',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '榛樿鍦烘櫙',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _SceneDestinationRail(
              selectedScene: _selectedScene,
              onSelected: (scene) {
                setState(() {
                  _selectedScene = _selectedScene == scene ? null : scene;
                });
              },
            ),
            const SizedBox(height: 14),
            Text(
              '我的歌单',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: playlists.isEmpty
                  ? _EmptyPlaylistPrompt(onCreate: _createPlaylist)
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: playlists.length + 1,
                      itemBuilder: (context, index) {
                        if (index == playlists.length) {
                          return _CreatePlaylistTile(onTap: _createPlaylist);
                        }
                        final playlist = playlists[index];
                        final selected = _selectedIds.contains(playlist.id);
                        return _PlaylistSelectTile(
                          title: playlist.name,
                          cover:
                              playlist.coverAsset ??
                              MusicAssets.playlistCustom01,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(playlist.id);
                              } else {
                                _selectedIds.add(playlist.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(
                      const _MusicImportDestination(
                        playlistIds: <int>{},
                        scene: null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.border),
                    ),
                    child: const Text('\u53ea\u5bfc\u5165\u672c\u5730'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _MusicImportDestination(
                        playlistIds: Set<int>.from(_selectedIds),
                        scene: _selectedScene,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnAccent,
                    ),
                    child: Text(
                      _selectedIds.isEmpty
                          ? '\u5f00\u59cb\u5bfc\u5165'
                          : '\u52a0\u5165 ${_selectedIds.length} \u4e2a\u6b4c\u5355',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final playlistId = await showCreateMusicPlaylistDialog(context);
    if (!mounted || playlistId == null) return;
    setState(() => _selectedIds.add(playlistId));
  }
}

class _SceneDestinationRail extends StatelessWidget {
  const _SceneDestinationRail({
    required this.selectedScene,
    required this.onSelected,
  });

  final MusicScene? selectedScene;
  final ValueChanged<MusicScene> onSelected;

  static const _scenes = [
    MusicScene.study,
    MusicScene.sleep,
    MusicScene.rain,
    MusicScene.relax,
    MusicScene.fitness,
    MusicScene.morning,
    MusicScene.lofi,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: _scenes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SceneDestinationTile(
              title: '智能识别',
              subtitle: '\u6309\u6b4c\u540d\u5224\u65ad',
              cover: MusicAssets.settingScene,
              selected: selectedScene == null,
              onTap: () {
                if (selectedScene != null) onSelected(selectedScene!);
              },
            );
          }
          final scene = _scenes[index - 1];
          final artwork = MusicArtworkMapper.forScene(scene);
          return _SceneDestinationTile(
            title: artwork.label,
            subtitle: artwork.subtitle,
            cover: artwork.playlistCover,
            selected: selectedScene == scene,
            onTap: () => onSelected(scene),
          );
        },
      ),
    );
  }
}

class _SceneDestinationTile extends StatelessWidget {
  const _SceneDestinationTile({
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String cover;
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
        width: 126,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? colors.softPurple : colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? colors.primary : colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                cover,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
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
                      color: selected ? colors.primary : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
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

class _EmptyPlaylistPrompt extends StatelessWidget {
  const _EmptyPlaylistPrompt({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(MusicAssets.playerEmptyImport, width: 150, height: 150),
          const SizedBox(height: 10),
          Text(
            '\u8fd8\u6ca1\u6709\u81ea\u5efa\u6b4c\u5355',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '先创建一中单，再把这导入的歌曲放进去',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建歌单'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePlaylistTile extends StatelessWidget {
  const _CreatePlaylistTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.softPurple,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              '新建歌单',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistSelectTile extends StatelessWidget {
  const _PlaylistSelectTile({
    required this.title,
    required this.cover,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String cover;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? colors.softPurple : colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                cover,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? colors.primary : colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.primary : colors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePlaylistDialog extends ConsumerStatefulWidget {
  const _CreatePlaylistDialog();

  @override
  ConsumerState<_CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<_CreatePlaylistDialog> {
  late final TextEditingController _controller;
  String _selectedCover = MusicAssets.playlistCustom01;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '新建歌单',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '\u4f8b\u5982\uff1a\u591c\u665a\u966a\u4f34',
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '閫夋嫨灏侀潰',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 132,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: MusicAssets.customPlaylistCovers.length,
                itemBuilder: (context, index) {
                  final cover = MusicAssets.customPlaylistCovers[index];
                  final selected = cover == _selectedCover;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selectedCover = cover),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? colors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(cover, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnAccent,
                    ),
                    child: const Text('创建'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final playlistId = await ref
        .read(musicPlayerProvider.notifier)
        .createPlaylist(name: name, coverAsset: _selectedCover);
    if (!mounted) return;
    Navigator.of(context).pop(playlistId);
  }
}

class _TrackPlaylistSheet extends ConsumerStatefulWidget {
  const _TrackPlaylistSheet({required this.track});

  final MusicTrack track;

  @override
  ConsumerState<_TrackPlaylistSheet> createState() =>
      _TrackPlaylistSheetState();
}

class _TrackPlaylistSheetState extends ConsumerState<_TrackPlaylistSheet> {
  late Set<int> _selectedIds;
  MusicScene? _selectedScene;

  @override
  void initState() {
    super.initState();
    _selectedIds = ref
        .read(musicPlayerProvider)
        .playlistIdsForTrack(widget.track.id)
        .toSet();
    _selectedScene = MusicSceneResolver.parseScene(widget.track.sceneOverride);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final state = ref.watch(musicPlayerProvider);
    final playlists = state.playlists;
    final isSeedTrack = DefaultMusicSeeds.isSeedTrack(widget.track);
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.68,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(30),
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
            const SizedBox(height: 14),
            Text(
              widget.track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isSeedTrack
                  ? '\u5185\u7f6e\u767d\u566a\u97f3\u56fa\u5b9a\u5728\u4e13\u6ce8\u767d\u566a\u97f3\u6b4c\u5355'
                  : '选择它属于哪些自建歌单',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '榛樿鍦烘櫙',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _SceneDestinationRail(
              selectedScene: _selectedScene,
              onSelected: (scene) {
                setState(() {
                  _selectedScene = _selectedScene == scene ? null : scene;
                });
              },
            ),
            const SizedBox(height: 14),
            Text(
              '我的歌单',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: playlists.isEmpty
                  ? _EmptyPlaylistPrompt(onCreate: _createPlaylist)
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: playlists.length + 1,
                      itemBuilder: (context, index) {
                        if (index == playlists.length) {
                          return _CreatePlaylistTile(onTap: _createPlaylist);
                        }
                        final playlist = playlists[index];
                        final selected = _selectedIds.contains(playlist.id);
                        return _PlaylistSelectTile(
                          title: playlist.name,
                          cover:
                              playlist.coverAsset ??
                              MusicAssets.playlistCustom01,
                          selected: selected,
                          onTap: isSeedTrack
                              ? null
                              : () {
                                  setState(() {
                                    if (selected) {
                                      _selectedIds.remove(playlist.id);
                                    } else {
                                      _selectedIds.add(playlist.id);
                                    }
                                  });
                                },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.border),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isSeedTrack
                        ? () => Navigator.of(context).pop()
                        : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnAccent,
                    ),
                    child: Text(isSeedTrack ? '\u77e5\u9053\u4e86' : '保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final playlistId = await showCreateMusicPlaylistDialog(context);
    if (!mounted || playlistId == null) return;
    setState(() => _selectedIds.add(playlistId));
  }

  Future<void> _save() async {
    await ref
        .read(musicPlayerProvider.notifier)
        .setTrackOrganization(
          trackId: widget.track.id,
          playlistIds: _selectedIds,
          sceneOverride: _selectedScene,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
