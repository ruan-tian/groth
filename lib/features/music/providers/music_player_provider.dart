import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as audio;

import '../../../core/database/app_database.dart';
import '../../../core/repositories/music_repository.dart';
import '../../../core/repositories/setting_repository.dart';
import '../../../shared/providers/repository_providers.dart';
import '../models/music_player_state.dart';
import '../services/music_import_service.dart';
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

  final Ref _ref;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;
  bool _handlingCompletion = false;

  MusicRepository get _musicRepo => _ref.read(musicRepositoryProvider);
  SettingRepository get _settings => _ref.read(settingRepositoryProvider);
  MusicImportService get _importService =>
      _ref.read(musicImportServiceProvider);
  MusicPlayerService get _player => _ref.read(musicPlayerServiceProvider);

  Future<void> _bootstrap() async {
    try {
      final tracks = await _musicRepo.getTracks();
      final volumeText = await _settings.getSetting(_volumeKey);
      final currentTrackText = await _settings.getSetting(_currentTrackKey);
      final positionText = await _settings.getSetting(_positionKey);
      final volume = (double.tryParse(volumeText ?? '') ?? 0.65)
          .clamp(0.0, 1.0)
          .toDouble();
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
          volume: volume,
          position: Duration(milliseconds: positionMs),
        ),
      );
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
        await _musicRepo.insertTrack(
          MusicTracksCompanion.insert(
            title: file.title,
            filePath: file.filePath,
            originalPath: Value(file.originalPath),
            coverAsset: const Value(MusicAssets.coverDefault),
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
    final tracks = await _musicRepo.getTracks();
    final currentId = state.currentTrackId;
    final nextCurrentId = tracks.any((track) => track.id == currentId)
        ? currentId
        : (tracks.isEmpty ? null : tracks.first.id);
    _setState(state.copyWith(tracks: tracks, currentTrackId: nextCurrentId));
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

  Future<void> playNext() async {
    final next = _nextTrack();
    if (next == null) return;
    await playTrack(next);
  }

  Future<void> _handleCompleted() async {
    if (_handlingCompletion) return;
    _handlingCompletion = true;
    try {
      await _savePosition(Duration.zero);
      final next = _nextTrack();
      if (next != null && next.id != state.currentTrackId) {
        await playTrack(next);
      } else {
        await _player.seek(Duration.zero);
        _setState(state.copyWith(isPlaying: false, position: Duration.zero));
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  MusicTrack? _nextTrack() {
    final tracks = state.tracks;
    if (tracks.isEmpty) return null;
    final currentId = state.currentTrackId;
    final index = tracks.indexWhere((track) => track.id == currentId);
    if (index < 0) return tracks.first;
    if (tracks.length == 1) return tracks.first;
    return tracks[(index + 1) % tracks.length];
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
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
