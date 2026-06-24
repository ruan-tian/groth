import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as audio;
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../repositories/music_repository.dart';
import '../../../core/repositories/setting_repository.dart';
import '../../../shared/providers/repository_providers.dart';
import '../models/music_player_state.dart';
import '../models/music_lyrics.dart';
import '../services/music_import_service.dart';
import '../services/music_lyrics_service.dart';
import '../services/music_player_service.dart';
import '../services/music_settings_write_queue.dart';
import '../utils/default_music_seed.dart';
import '../utils/music_assets.dart';
import '../utils/music_scene.dart';

final musicImportServiceProvider = Provider<MusicImportService>((ref) {
  return MusicImportService();
});

final musicPlayerServiceProvider = Provider<MusicPlayerService>((ref) {
  final service = MusicPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

final musicLyricsServiceProvider = Provider<MusicLyricsService>((ref) {
  return MusicLyricsService();
});

final musicPlayerProvider =
    StateNotifierProvider<MusicPlayerController, MusicPlayerState>((ref) {
      return MusicPlayerController(ref);
    });

class MusicPlayerController extends StateNotifier<MusicPlayerState> {
  MusicPlayerController(this._ref) : super(const MusicPlayerState()) {
    _listenToPlayer();
    unawaited(_bootstrap());
  }

  static const _volumeKey = 'music_volume';
  static const _currentTrackKey = 'music_current_track_id';
  static const _positionKey = 'music_position_ms';
  static const _collectionKey = 'music_collection';
  static const _floatXKey = 'music_float_x';
  static const _floatYKey = 'music_float_y';

  final Ref _ref;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _sleepTimer;
  bool _disposed = false;
  bool _handlingCompletion = false;
  int _bootstrapRetryCount = 0;
  Future<void>? _bootstrapFuture;
  late final MusicSettingsWriteQueue _settingsWriter = MusicSettingsWriteQueue(
    write: _settings.setSetting,
  );

  MusicRepository get _musicRepo => _ref.read(musicRepositoryProvider);
  SettingRepository get _settings => _ref.read(settingRepositoryProvider);
  MusicImportService get _importService =>
      _ref.read(musicImportServiceProvider);
  MusicPlayerService get _player => _ref.read(musicPlayerServiceProvider);
  MusicLyricsService get _lyrics => _ref.read(musicLyricsServiceProvider);

  Future<void> _bootstrap() {
    final running = _bootstrapFuture;
    if (running != null) return running;
    final future = _runBootstrap();
    _bootstrapFuture = future;
    future.whenComplete(() {
      if (identical(_bootstrapFuture, future)) {
        _bootstrapFuture = null;
      }
    });
    return future;
  }

  Future<void> _runBootstrap() async {
    try {
      await _musicRepo.ensureDefaultFocusNoisePlaylist();
      final tracks = await _resolveDefaultCovers(await _musicRepo.getTracks());
      final playlists = await _resolveLegacyPlaylistCovers(
        await _musicRepo.getPlaylists(),
      );
      final playlistTracks = await _musicRepo.getPlaylistTracks();
      final volumeText = await _settings.getSetting(_volumeKey);
      final currentTrackText = await _settings.getSetting(_currentTrackKey);
      final positionText = await _settings.getSetting(_positionKey);
      final collectionText = await _settings.getSetting(_collectionKey);
      final floatXText = await _settings.getSetting(_floatXKey);
      final floatYText = await _settings.getSetting(_floatYKey);
      final volume = (double.tryParse(volumeText ?? '') ?? 0.65)
          .clamp(0.0, 1.0)
          .toDouble();
      final floatX = (double.tryParse(floatXText ?? '') ?? 0)
          .clamp(0.0, 1.0)
          .toDouble();
      final floatY = (double.tryParse(floatYText ?? '') ?? 0.72)
          .clamp(0.0, 1.0)
          .toDouble();
      final collection = MusicCollection.values.firstWhere(
        (value) => value.name == collectionText,
        orElse: () => MusicCollection.all,
      );
      final currentTrackId = int.tryParse(currentTrackText ?? '');
      final initialTrackId = tracks.any((track) => track.id == currentTrackId)
          ? currentTrackId
          : (tracks.isEmpty ? null : tracks.first.id);
      final positionMs = int.tryParse(positionText ?? '') ?? 0;
      await _player.setVolume(volume);
      final queueIds = _trackIdsForSelection(
        tracks: tracks,
        playlistTracks: playlistTracks,
        collection: collection,
        playlistId: null,
      );
      _setState(
        state.copyWith(
          tracks: tracks,
          playlists: playlists,
          playlistTracks: playlistTracks,
          currentTrackId: initialTrackId,
          playQueueIds: queueIds,
          selectedCollection: collection,
          volume: volume,
          position: Duration(milliseconds: positionMs),
          floatX: floatX,
          floatY: floatY,
        ),
      );
      await _loadLyricsForCurrentTrack();
      _bootstrapRetryCount = 0;
    } catch (error) {
      debugPrint('Music bootstrap failed: $error');
      if (_shouldRetryBootstrap(error) && _bootstrapRetryCount < 3) {
        _bootstrapRetryCount++;
        final delay = Duration(milliseconds: 220 * _bootstrapRetryCount);
        Timer(delay, () {
          if (!_disposed) unawaited(_bootstrap());
        });
        return;
      }
      _setState(
        state.copyWith(
          errorMessage:
              '\u97f3\u4e50\u521d\u59cb\u5316\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5',
        ),
      );
    }
  }

  bool _shouldRetryBootstrap(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('database is locked') ||
        message.contains('sqliteexception(5') ||
        message.contains('code 5');
  }

  void _listenToPlayer() {
    _player.onPlaybackError = (error, stackTrace) {
      if (_disposed) return;
      debugPrint('Music playback failed: $error');
      _setState(
        state.copyWith(
          isPlaying: false,
          isLoading: false,
          errorMessage: '播放失败，请重试',
        ),
      );
    };
    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (_disposed) return;
        _setState(state.copyWith(position: position));
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (_disposed || duration == null) return;
        _setState(state.copyWith(duration: duration));
        final track = state.currentTrack;
        if (track != null && track.durationMs == null) {
          unawaited(_musicRepo.updateDuration(track.id, duration));
        }
      }),
    );
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        if (_disposed) return;
        final completed =
            playerState.processingState == audio.ProcessingState.completed;
        _setState(state.copyWith(isPlaying: playerState.playing));
        if (completed) {
          unawaited(_handleCompleted());
        }
      }),
    );
  }

  void toggleExpanded() {
    _setState(state.copyWith(isExpanded: !state.isExpanded));
  }

  void collapse() {
    _setState(state.copyWith(isExpanded: false));
  }

  Future<void> setFloatPosition({required double x, required double y}) async {
    final clampedX = x.clamp(0.0, 1.0).toDouble();
    final clampedY = y.clamp(0.0, 1.0).toDouble();
    _setState(state.copyWith(floatX: clampedX, floatY: clampedY));
    _settingsWriter.schedule(_floatXKey, '$clampedX');
    _settingsWriter.schedule(_floatYKey, '$clampedY');
  }

  Future<void> selectCollection(MusicCollection collection) async {
    final queueIds = _trackIdsForSelection(
      tracks: state.tracks,
      playlistTracks: state.playlistTracks,
      collection: collection,
      playlistId: null,
    );
    _setState(
      state.copyWith(
        selectedCollection: collection,
        selectedPlaylistId: null,
        playQueueIds: queueIds,
      ),
    );
    _settingsWriter.schedule(_collectionKey, collection.name);
  }

  void selectPlaylist(int playlistId) {
    final queueIds = _trackIdsForSelection(
      tracks: state.tracks,
      playlistTracks: state.playlistTracks,
      collection: state.selectedCollection,
      playlistId: playlistId,
    );
    _setState(
      state.copyWith(selectedPlaylistId: playlistId, playQueueIds: queueIds),
    );
  }

  Future<int> createPlaylist({
    required String name,
    required String coverAsset,
  }) async {
    final playlistId = await _musicRepo.createPlaylist(
      name: name,
      coverAsset: coverAsset,
    );
    await refreshTracks();
    _setState(state.copyWith(selectedPlaylistId: playlistId));
    return playlistId;
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _musicRepo.deletePlaylist(playlistId);
    await refreshTracks();
    if (state.selectedPlaylistId == playlistId) {
      _setState(state.copyWith(selectedPlaylistId: null));
    }
  }

  Future<void> setTrackPlaylists({
    required int trackId,
    required Iterable<int> playlistIds,
  }) async {
    await _musicRepo.setTrackPlaylists(
      trackId: trackId,
      playlistIds: playlistIds,
    );
    await refreshTracks();
  }

  Future<void> setTrackOrganization({
    required int trackId,
    required Iterable<int> playlistIds,
    required MusicScene? sceneOverride,
  }) async {
    await _musicRepo.setTrackPlaylists(
      trackId: trackId,
      playlistIds: playlistIds,
    );
    await _musicRepo.updateSceneOverride(trackId, sceneOverride?.name);
    await refreshTracks();
  }

  Future<void> setTrackSceneOverride({
    required int trackId,
    required MusicScene? sceneOverride,
  }) async {
    await _musicRepo.updateSceneOverride(trackId, sceneOverride?.name);
    await refreshTracks();
  }

  Future<void> importTracks({
    Iterable<int> playlistIds = const [],
    MusicScene? sceneOverride,
  }) async {
    await _importFiles(
      loader: _importService.pickAndCopyTracks,
      playlistIds: playlistIds,
      sceneOverride: sceneOverride,
      failureMessage: '导入音乐失败，重试',
    );
  }

  Future<void> scanFolder({
    Iterable<int> playlistIds = const [],
    MusicScene? sceneOverride,
  }) async {
    await _importFiles(
      loader: _importService.pickAndCopyDirectory,
      playlistIds: playlistIds,
      sceneOverride: sceneOverride,
      failureMessage:
          '\u626b\u63cf\u6587\u4ef6\u5939\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5',
    );
  }

  Future<void> _importFiles({
    required Future<List<ImportedMusicFile>> Function() loader,
    required String failureMessage,
    required Iterable<int> playlistIds,
    required MusicScene? sceneOverride,
  }) async {
    _setState(state.copyWith(isImporting: true, errorMessage: null));
    try {
      final imported = await loader();
      var inserted = 0;
      final targetPlaylistIds = playlistIds.toSet();
      for (final file in imported) {
        final existing = await _musicRepo.getTrackByOriginalPath(
          file.originalPath,
        );
        if (existing != null) {
          await _deleteCopiedDuplicate(file.filePath);
          if (sceneOverride != null) {
            await _musicRepo.updateSceneOverride(
              existing.id,
              sceneOverride.name,
            );
          }
          for (final playlistId in targetPlaylistIds) {
            await _musicRepo.addTrackToPlaylist(
              playlistId: playlistId,
              trackId: existing.id,
            );
          }
          continue;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final coverAsset = sceneOverride == null
            ? MusicAssets.coverForTitle('${file.title} ${file.originalPath}')
            : MusicArtworkMapper.forScene(sceneOverride).cover;
        final trackId = await _musicRepo.insertTrack(
          MusicTracksCompanion.insert(
            title: file.title,
            filePath: file.filePath,
            originalPath: Value(file.originalPath),
            coverAsset: Value(coverAsset),
            sceneOverride: Value(sceneOverride?.name),
            createdAt: now,
            updatedAt: now,
          ),
        );
        for (final playlistId in targetPlaylistIds) {
          await _musicRepo.addTrackToPlaylist(
            playlistId: playlistId,
            trackId: trackId,
          );
        }
        inserted++;
      }
      await refreshTracks();
      final current = state.currentTrack;
      if (inserted > 0 && current != null && state.currentTrackId == null) {
        _setState(state.copyWith(currentTrackId: current.id));
      }
    } catch (error) {
      _setState(state.copyWith(errorMessage: failureMessage));
    } finally {
      _setState(state.copyWith(isImporting: false));
    }
  }

  Future<void> _deleteCopiedDuplicate(String copiedPath) async {
    final copiedFile = File(copiedPath);
    if (await copiedFile.exists()) {
      await copiedFile.delete();
    }
    final lrcFile = File(
      p.join(
        p.dirname(copiedPath),
        '${p.basenameWithoutExtension(copiedPath)}.lrc',
      ),
    );
    if (await lrcFile.exists()) {
      await lrcFile.delete();
    }
  }

  Future<void> refreshTracks() async {
    final tracks = await _resolveDefaultCovers(await _musicRepo.getTracks());
    final playlists = await _resolveLegacyPlaylistCovers(
      await _musicRepo.getPlaylists(),
    );
    final playlistTracks = await _musicRepo.getPlaylistTracks();
    final currentId = state.currentTrackId;
    final nextCurrentId = tracks.any((track) => track.id == currentId)
        ? currentId
        : (tracks.isEmpty ? null : tracks.first.id);
    final currentPlaylistId = state.selectedPlaylistId;
    final nextPlaylistId =
        currentPlaylistId != null &&
            playlists.any((playlist) => playlist.id == currentPlaylistId)
        ? currentPlaylistId
        : null;
    final previousQueueIds = state.playQueueIds
        .where((id) => tracks.any((track) => track.id == id))
        .toList(growable: false);
    final nextQueueIds = previousQueueIds.isNotEmpty
        ? previousQueueIds
        : _trackIdsForSelection(
            tracks: tracks,
            playlistTracks: playlistTracks,
            collection: state.selectedCollection,
            playlistId: nextPlaylistId,
          );
    _setState(
      state.copyWith(
        tracks: tracks,
        playlists: playlists,
        playlistTracks: playlistTracks,
        currentTrackId: nextCurrentId,
        selectedPlaylistId: nextPlaylistId,
        playQueueIds: nextQueueIds,
      ),
    );
    if (nextCurrentId != currentId) {
      await _loadLyricsForCurrentTrack();
    }
  }

  Future<List<MusicTrack>> _resolveDefaultCovers(
    List<MusicTrack> tracks,
  ) async {
    final resolved = <MusicTrack>[];
    for (final track in tracks) {
      final cover = MusicArtworkMapper.coverForTrack(track);
      final normalizedCover = _normalizeAssetPath(track.coverAsset);
      final shouldUpdate =
          normalizedCover != track.coverAsset ||
          (MusicArtworkMapper.isGeneratedCover(track.coverAsset) &&
              cover != (track.coverAsset ?? MusicAssets.coverDefault));
      if (shouldUpdate) {
        await _musicRepo.updateCoverAsset(track.id, cover);
        resolved.add(track.copyWith(coverAsset: Value(cover)));
      } else {
        resolved.add(track);
      }
    }
    return resolved;
  }

  Future<List<MusicPlaylist>> _resolveLegacyPlaylistCovers(
    List<MusicPlaylist> playlists,
  ) async {
    final resolved = <MusicPlaylist>[];
    for (final playlist in playlists) {
      final cover = _normalizeAssetPath(playlist.coverAsset);
      if (cover != null && cover != playlist.coverAsset) {
        await _musicRepo.updatePlaylistCoverAsset(playlist.id, cover);
        resolved.add(playlist.copyWith(coverAsset: Value(cover)));
      } else {
        resolved.add(playlist);
      }
    }
    return resolved;
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
      return;
    }
    final track = state.currentTrack;
    if (track == null) {
      _setState(
        state.copyWith(
          errorMessage:
              '\u5148\u5bfc\u5165\u4e00\u9996\u672c\u5730\u97f3\u4e50',
        ),
      );
      return;
    }
    await playTrack(track);
  }

  void togglePlayMode() {
    final modes = PlayMode.values;
    final nextIndex = (modes.indexOf(state.playMode) + 1) % modes.length;
    _setState(state.copyWith(playMode: modes[nextIndex]));
  }

  void setPlayMode(PlayMode playMode) {
    _setState(state.copyWith(playMode: playMode));
  }

  Future<void> playTrack(MusicTrack track) async {
    final queueIds = _queueForTrack(track.id);
    await _playTrackWithQueue(track, queueIds);
  }

  Future<void> playTrackFromQueue(
    MusicTrack track,
    List<MusicTrack> queue,
  ) async {
    final queueIds = queue.map((track) => track.id).toList(growable: false);
    await _playTrackWithQueue(
      track,
      queueIds.contains(track.id) ? queueIds : [track.id, ...queueIds],
    );
  }

  Future<void> _playTrackWithQueue(MusicTrack track, List<int> queueIds) async {
    _setState(
      state.copyWith(
        isLoading: true,
        currentTrackId: track.id,
        playQueueIds: queueIds,
        position: Duration.zero,
        duration: Duration.zero,
        errorMessage: null,
      ),
    );
    try {
      if (!MusicPlayerService.isAssetPath(track.filePath)) {
        final file = File(track.filePath);
        if (!await file.exists()) {
          throw FileSystemException(
            '\u97f3\u4e50\u6587\u4ef6\u4e0d\u5b58\u5728',
            track.filePath,
          );
        }
      }
      final duration = await _player.playFile(
        track.filePath,
        volume: state.volume,
      );
      await _musicRepo.updateLastPlayed(track.id);
      _settingsWriter.schedule(_currentTrackKey, '${track.id}');
      if (duration != null) {
        await _musicRepo.updateDuration(track.id, duration);
      }
      await refreshTracks();
      _setState(
        state.copyWith(
          currentTrackId: track.id,
          playQueueIds: queueIds,
          isPlaying: true,
          isLoading: false,
          duration: duration ?? state.effectiveDuration,
        ),
      );
      await _loadLyricsForCurrentTrack();
    } catch (error) {
      _setState(
        state.copyWith(
          isPlaying: false,
          isLoading: false,
          errorMessage: '撔失败，重试',
        ),
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
    await _savePosition(state.position);
    await _settingsWriter.flush();
    _setState(state.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    await _savePosition(position);
    await _settingsWriter.flush();
    _setState(state.copyWith(position: position));
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(clamped);
    _setState(state.copyWith(volume: clamped));
    _settingsWriter.schedule(_volumeKey, '$clamped');
  }

  Future<void> toggleFavorite(MusicTrack track) async {
    await _musicRepo.updateFavorite(track.id, !track.isFavorite);
    await refreshTracks();
  }

  Future<void> deleteTrack(int trackId) async {
    try {
      // 找到要删除的歌曲
      final track = state.tracks.firstWhere((t) => t.id == trackId);
      if (DefaultMusicSeeds.isSeedTrack(track)) {
        _setState(
          state.copyWith(
            errorMessage:
                '\u5185\u7f6e\u767d\u566a\u97f3\u4e0d\u80fd\u5220\u9664',
          ),
        );
        return;
      }
      // 从数捺删除记录
      await _musicRepo.deleteTrack(trackId);
      // 删除文件（内罵源不删除，只移除数据库录）
      if (!MusicPlayerService.isAssetPath(track.filePath)) {
        final file = File(track.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      // 如果删除的是当前撔歌曲，切换到下一?
      if (state.currentTrackId == trackId) {
        final nextTrack = _trackByOffset(1);
        if (nextTrack != null && nextTrack.id != trackId) {
          await playTrack(nextTrack);
        } else {
          // 娌℃湁涓嬩竴棣栵紝鍋滄鎾斁
          await _player.stop();
          _setState(
            state.copyWith(
              isPlaying: false,
              currentTrackId: null,
              position: Duration.zero,
            ),
          );
        }
      }
      // 刷新列表
      await refreshTracks();
    } catch (error) {
      _setState(state.copyWith(errorMessage: '删除歌曲失败，重试'));
    }
  }

  Future<void> removeFromList(int trackId) async {
    try {
      final track = state.tracks.firstWhere((t) => t.id == trackId);
      if (DefaultMusicSeeds.isSeedTrack(track)) {
        _setState(
          state.copyWith(
            errorMessage:
                '\u5185\u7f6e\u767d\u566a\u97f3\u4e0d\u80fd\u79fb\u9664',
          ),
        );
        return;
      }
      // Only remove the database record; keep the source file.
      await _musicRepo.deleteTrack(trackId);
      // 如果删除的是当前撔歌曲，切换到下一?
      if (state.currentTrackId == trackId) {
        final nextTrack = _trackByOffset(1);
        if (nextTrack != null && nextTrack.id != trackId) {
          await playTrack(nextTrack);
        } else {
          // 娌℃湁涓嬩竴棣栵紝鍋滄鎾斁
          await _player.stop();
          _setState(
            state.copyWith(
              isPlaying: false,
              currentTrackId: null,
              position: Duration.zero,
            ),
          );
        }
      }
      // 刷新列表
      await refreshTracks();
    } catch (error) {
      _setState(
        state.copyWith(
          errorMessage:
              '\u4ece\u5217\u8868\u79fb\u9664\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5',
        ),
      );
    }
  }

  Future<void> playNext() async {
    final next = _trackByOffset(1);
    if (next == null) return;
    await playTrack(next);
  }

  Future<void> playPrevious() async {
    final previous = _trackByOffset(-1);
    if (previous == null) return;
    await playTrack(previous);
  }

  Future<void> _handleCompleted() async {
    if (_handlingCompletion) return;
    _handlingCompletion = true;
    try {
      await _savePosition(Duration.zero);
      if (state.sleepTimerEndOfTrack) {
        await _player.seek(Duration.zero);
        await clearSleepTimer();
        _setState(state.copyWith(isPlaying: false, position: Duration.zero));
        return;
      }

      switch (state.playMode) {
        case PlayMode.loopSingle:
          await _player.seek(Duration.zero);
          await _player.play();
          _setState(state.copyWith(isPlaying: true, position: Duration.zero));
          break;
        case PlayMode.loopAll:
          final next = _trackByOffset(1);
          if (next != null) {
            await playTrack(next);
          } else {
            await _player.seek(Duration.zero);
            _setState(
              state.copyWith(isPlaying: false, position: Duration.zero),
            );
          }
          break;
        case PlayMode.sequential:
          final next = _trackByOffset(1);
          if (next != null && next.id != state.currentTrackId) {
            await playTrack(next);
          } else {
            await _player.seek(Duration.zero);
            _setState(
              state.copyWith(isPlaying: false, position: Duration.zero),
            );
          }
          break;
        case PlayMode.shuffle:
          final tracks = state.selectedTracks.isEmpty
              ? state.tracks
              : state.selectedTracks;
          if (tracks.length <= 1) {
            await _player.seek(Duration.zero);
            _setState(
              state.copyWith(isPlaying: false, position: Duration.zero),
            );
          } else {
            final random = Random();
            MusicTrack next;
            do {
              next = tracks[random.nextInt(tracks.length)];
            } while (next.id == state.currentTrackId && tracks.length > 1);
            await playTrack(next);
          }
          break;
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  MusicTrack? _trackByOffset(int offset) {
    final tracks = _playQueueTracks();
    if (tracks.isEmpty) return null;
    if (state.playMode == PlayMode.shuffle) {
      if (tracks.length <= 1) return tracks.first;
      final random = Random();
      MusicTrack next;
      do {
        next = tracks[random.nextInt(tracks.length)];
      } while (next.id == state.currentTrackId);
      return next;
    }
    final currentId = state.currentTrackId;
    final index = tracks.indexWhere((track) => track.id == currentId);
    if (index < 0) return tracks.first;
    if (tracks.length == 1) return tracks.first;
    return tracks[(index + offset) % tracks.length];
  }

  List<MusicTrack> _playQueueTracks() {
    final queueIds = state.playQueueIds;
    if (queueIds.isEmpty) {
      return state.selectedTracks.isEmpty ? state.tracks : state.selectedTracks;
    }
    final byId = {for (final track in state.tracks) track.id: track};
    return queueIds
        .map((id) => byId[id])
        .whereType<MusicTrack>()
        .toList(growable: false);
  }

  List<int> _queueForTrack(int trackId) {
    final selectedIds = state.selectedTracks
        .map((track) => track.id)
        .toList(growable: false);
    if (selectedIds.contains(trackId)) return selectedIds;

    final allIds = state.tracks
        .map((track) => track.id)
        .toList(growable: false);
    if (allIds.contains(trackId)) return allIds;
    return [trackId];
  }

  List<int> _trackIdsForSelection({
    required List<MusicTrack> tracks,
    required List<MusicPlaylistTrack> playlistTracks,
    required MusicCollection collection,
    required int? playlistId,
  }) {
    if (playlistId != null) {
      final ids = playlistTracks
          .where((item) => item.playlistId == playlistId)
          .map((item) => item.trackId)
          .toSet();
      return tracks
          .where((track) => ids.contains(track.id))
          .map((track) => track.id)
          .toList(growable: false);
    }
    final selectedTracks = switch (collection) {
      MusicCollection.all => tracks,
      MusicCollection.favorites =>
        tracks.where((track) => track.isFavorite).toList(growable: false),
      MusicCollection.recent => _recentTracksFrom(tracks),
    };
    return selectedTracks.map((track) => track.id).toList(growable: false);
  }

  List<MusicTrack> _recentTracksFrom(List<MusicTrack> tracks) {
    final recent = tracks.where((track) => track.lastPlayedAt != null).toList();
    if (recent.isEmpty) return tracks;
    recent.sort((a, b) => (b.lastPlayedAt ?? 0).compareTo(a.lastPlayedAt ?? 0));
    return recent;
  }

  String? _normalizeAssetPath(String? asset) {
    return MusicArtworkMapper.normalizeAssetPath(asset);
  }

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    final endAt = DateTime.now().add(duration).millisecondsSinceEpoch;
    _setState(
      state.copyWith(
        sleepTimerEndAtMs: endAt,
        sleepTimerEndOfTrack: false,
        sleepTimerRemainingSeconds: duration.inSeconds,
      ),
    );
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickSleepTimer();
    });
  }

  void setEndOfTrackTimer() {
    _sleepTimer?.cancel();
    _setState(
      state.copyWith(
        sleepTimerEndAtMs: null,
        sleepTimerEndOfTrack: true,
        sleepTimerRemainingSeconds: 0,
      ),
    );
  }

  Future<void> clearSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _setState(
      state.copyWith(
        sleepTimerEndAtMs: null,
        sleepTimerEndOfTrack: false,
        sleepTimerRemainingSeconds: 0,
      ),
    );
  }

  Future<void> _tickSleepTimer() async {
    final endAt = state.sleepTimerEndAtMs;
    if (endAt == null) {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      return;
    }
    final remaining = ((endAt - DateTime.now().millisecondsSinceEpoch) / 1000)
        .ceil();
    if (remaining <= 0) {
      await pause();
      await clearSleepTimer();
      return;
    }
    _setState(state.copyWith(sleepTimerRemainingSeconds: remaining));
  }

  Future<void> _loadLyricsForCurrentTrack() async {
    final track = state.currentTrack;
    if (track == null) {
      _setState(state.copyWith(lyrics: const MusicLyricsView()));
      return;
    }
    final lyrics = await _lyrics.loadForTrack(track.filePath);
    if (_disposed || state.currentTrackId != track.id) return;
    _setState(state.copyWith(lyrics: lyrics));
  }

  Future<void> importLrcForCurrentTrack() async {
    final track = state.currentTrack;
    if (track == null) return;

    final lrcPath = await _importService.pickAndCopyLrcForTrack(track.filePath);
    if (lrcPath == null) return;

    // 重新加载歌词
    await _loadLyricsForCurrentTrack();
  }

  Future<void> _savePosition(Duration position) {
    _settingsWriter.schedule(_positionKey, '${position.inMilliseconds}');
    return _settingsWriter.flush();
  }

  void clearError() {
    _setState(state.copyWith(errorMessage: null));
  }

  void _setState(MusicPlayerState next) {
    if (_disposed) return;
    state = next;
  }

  @override
  void dispose() {
    _disposed = true;
    _sleepTimer?.cancel();
    // Use try-catch to handle ProviderContainer already disposed
    try {
      unawaited(_settingsWriter.dispose());
    } catch (_) {
      // Ignore errors during dispose (container may already be disposed)
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
