import 'dart:async';

import 'package:just_audio/just_audio.dart';

class MusicPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPath;
  void Function(Object error, StackTrace stackTrace)? onPlaybackError;

  String? get currentPath => _currentPath;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  static bool isAssetPath(String path) => path.startsWith('assets/');

  Future<Duration?> load(String filePath) async {
    if (_currentPath == filePath) return _player.duration;
    final duration = isAssetPath(filePath)
        ? await _player.setAsset(filePath)
        : await _player.setFilePath(filePath);
    _currentPath = filePath;
    return duration;
  }

  Future<Duration?> playFile(String filePath, {required double volume}) async {
    final duration = await load(filePath);
    await setVolume(volume);
    _startPlayback();
    return duration;
  }

  Future<void> play() async => _startPlayback();

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
  }

  void _startPlayback() {
    unawaited(
      _player.play().catchError((Object error, StackTrace stackTrace) {
        onPlaybackError?.call(error, stackTrace);
      }),
    );
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
