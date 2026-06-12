import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as audio;

import '../../../core/database/app_database.dart';
import '../../../core/repositories/music_repository.dart';
import '../../../core/repositories/setting_repository.dart';
import '../../../shared/providers/repository_providers.dart';
import '../models/music_player_state.dart';
import '../models/music_lyrics.dart';
import '../services/music_import_service.dart';
import '../services/music_lyrics_service.dart';
import '../services/music_player_service.dart';
import '../utils/music_assets.dart';

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

  MusicRepository get _musicRepo => _ref.read(musicRepositoryProvider);
  SettingRepository get _settings => _ref.read(settingRepositoryProvider);
  MusicImportService get _importService =>
      _ref.read(musicImportServiceProvider);
  MusicPlayerService get _player => _ref.read(musicPlayerServiceProvider);
  MusicLyricsService get _lyrics => _ref.read(musicLyricsServiceProvider);

  Future<void> _bootstrap() async {
    try {
      final tracks = await _resolveDefaultCovers(await _musicRepo.getTracks());
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
      _setState(
        state.copyWith(
          tracks: tracks,
          currentTrackId: initialTrackId,
          selectedCollection: collection,
          volume: volume,
          position: Duration(milliseconds: positionMs),
          floatX: floatX,
          floatY: floatY,
        ),
      );
      await _loadLyricsForCurrentTrack();
    } catch (error) {
      _setState(state.copyWith(errorMessage: '音乐初始化失败：$error'));
    }
  }

  void _listenToPlayer() {
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
    await _settings.setSetting(_floatXKey, '$clampedX');
    await _settings.setSetting(_floatYKey, '$clampedY');
  }

  Future<void> selectCollection(MusicCollection collection) async {
    _setState(state.copyWith(selectedCollection: collection));
    await _settings.setSetting(_collectionKey, collection.name);
  }

  Future<void> importTracks() async {
    _setState(state.copyWith(isImporting: true, errorMessage: null));
    try {
      final imported = await _importService.pickAndCopyTracks();
      var inserted = 0;
      for (final file in imported) {
        final existing = await _musicRepo.getTrackByOriginalPath(
          file.originalPath,
        );
        if (existing != null) continue;

        final now = DateTime.now().millisecondsSinceEpoch;
        final coverAsset = MusicAssets.coverForTitle(
          '${file.title} ${file.originalPath}',
        );
        await _musicRepo.insertTrack(
          MusicTracksCompanion.insert(
            title: file.title,
            filePath: file.filePath,
            originalPath: Value(file.originalPath),
            coverAsset: Value(coverAsset),
            createdAt: now,
            updatedAt: now,
          ),
        );
        inserted++;
      }
      await refreshTracks();
      final current = state.currentTrack;
      if (inserted > 0 && current != null && state.currentTrackId == null) {
        _setState(state.copyWith(currentTrackId: current.id));
      }
    } catch (error) {
      _setState(state.copyWith(errorMessage: '导入音乐失败：$error'));
    } finally {
      _setState(state.copyWith(isImporting: false));
    }
  }

  Future<void> refreshTracks() async {
    final tracks = await _resolveDefaultCovers(await _musicRepo.getTracks());
    final currentId = state.currentTrackId;
    final nextCurrentId = tracks.any((track) => track.id == currentId)
        ? currentId
        : (tracks.isEmpty ? null : tracks.first.id);
    _setState(state.copyWith(tracks: tracks, currentTrackId: nextCurrentId));
    if (nextCurrentId != currentId) {
      await _loadLyricsForCurrentTrack();
    }
  }

  Future<List<MusicTrack>> _resolveDefaultCovers(
    List<MusicTrack> tracks,
  ) async {
    final resolved = <MusicTrack>[];
    for (final track in tracks) {
      final cover = MusicAssets.coverForTitle(
        '${track.title} ${track.filePath}',
      );
      final shouldUpdate =
          (track.coverAsset == null ||
              track.coverAsset == MusicAssets.coverDefault) &&
          cover != (track.coverAsset ?? MusicAssets.coverDefault);
      if (shouldUpdate) {
        await _musicRepo.updateCoverAsset(track.id, cover);
        resolved.add(track.copyWith(coverAsset: Value(cover)));
      } else {
        resolved.add(track);
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
      _setState(state.copyWith(errorMessage: '先导入一首本地音乐'));
      return;
    }
    await playTrack(track);
  }

  void togglePlayMode() {
    final modes = PlayMode.values;
    final nextIndex = (modes.indexOf(state.playMode) + 1) % modes.length;
    _setState(state.copyWith(playMode: modes[nextIndex]));
  }

  Future<void> playTrack(MusicTrack track) async {
    _setState(
      state.copyWith(
        isLoading: true,
        currentTrackId: track.id,
        errorMessage: null,
      ),
    );
    try {
      final file = File(track.filePath);
      if (!await file.exists()) {
        throw FileSystemException('音乐文件不存在', track.filePath);
      }
      final duration = await _player.playFile(
        track.filePath,
        volume: state.volume,
      );
      await _musicRepo.updateLastPlayed(track.id);
      await _settings.setSetting(_currentTrackKey, '${track.id}');
      if (duration != null) {
        await _musicRepo.updateDuration(track.id, duration);
      }
      await refreshTracks();
      _setState(
        state.copyWith(
          currentTrackId: track.id,
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
          errorMessage: '播放失败：$error',
        ),
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
    await _savePosition(state.position);
    _setState(state.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    await _savePosition(position);
    _setState(state.copyWith(position: position));
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(clamped);
    await _settings.setSetting(_volumeKey, '$clamped');
    _setState(state.copyWith(volume: clamped));
  }

  Future<void> toggleFavorite(MusicTrack track) async {
    await _musicRepo.updateFavorite(track.id, !track.isFavorite);
    await refreshTracks();
  }

  Future<void> deleteTrack(int trackId) async {
    try {
      // 找到要删除的歌曲
      final track = state.tracks.firstWhere((t) => t.id == trackId);
      // 从数据库删除记录
      await _musicRepo.deleteTrack(trackId);
      // 删除文件
      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      // 如果删除的是当前播放歌曲，切换到下一首
      if (state.currentTrackId == trackId) {
        final nextTrack = _trackByOffset(1);
        if (nextTrack != null && nextTrack.id != trackId) {
          await playTrack(nextTrack);
        } else {
          // 没有下一首，停止播放
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
      _setState(state.copyWith(errorMessage: '删除歌曲失败：$error'));
    }
  }

  Future<void> removeFromList(int trackId) async {
    try {
      // 只从数据库删除记录，不删除文件
      await _musicRepo.deleteTrack(trackId);
      // 如果删除的是当前播放歌曲，切换到下一首
      if (state.currentTrackId == trackId) {
        final nextTrack = _trackByOffset(1);
        if (nextTrack != null && nextTrack.id != trackId) {
          await playTrack(nextTrack);
        } else {
          // 没有下一首，停止播放
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
      _setState(state.copyWith(errorMessage: '从列表移除失败：$error'));
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
          if (next != null && next.id != state.currentTrackId) {
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
    final tracks = state.selectedTracks.isEmpty
        ? state.tracks
        : state.selectedTracks;
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
    return _settings.setSetting(_positionKey, '${position.inMilliseconds}');
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
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
