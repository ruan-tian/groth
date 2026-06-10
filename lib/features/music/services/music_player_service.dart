import 'package:just_audio/just_audio.dart';

class MusicPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPath;

  String? get currentPath => _currentPath;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<Duration?> load(String filePath) async {
    if (_currentPath == filePath) return _player.duration;
    final duration = await _player.setFilePath(filePath);
    _currentPath = filePath;
    return duration;
  }

  Future<Duration?> playFile(String filePath, {required double volume}) async {
    final duration = await load(filePath);
    await setVolume(volume);
    await _player.play();
    return duration;
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
