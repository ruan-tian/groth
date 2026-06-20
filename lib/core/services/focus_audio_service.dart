import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FocusAudioService {
  static bool _initialized = false;

  final AudioPlayer _noisePlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  String? _currentNoiseAsset;
  bool _isNoisePlaying = false;

  bool get isNoisePlaying => _isNoisePlaying;
  String? get currentNoiseAsset => _currentNoiseAsset;

  static Future<void> initBackground() async {
    if (_initialized) return;
    _initialized = true;
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.growthos.focus.audio',
      androidNotificationChannelName: '专注白噪音',
      androidNotificationOngoing: true,
      preloadArtwork: false,
    );
  }

  static String displayNameForSound(String soundType) {
    switch (soundType) {
      case 'rain':
        return '雨声';
      case 'ocean':
        return '海浪';
      case 'forest':
        return '森林';
      case 'cafe':
        return '咖啡馆';
      case 'white_noise':
        return '白噪音';
      case 'wind':
        return '风声';
      default:
        return soundType;
    }
  }

  static String assetPathForSound(String soundType) {
    return 'assets/audio/noise/$soundType.mp3';
  }

  static String assetPathForBell(String bellType) {
    return 'assets/audio/bell/$bellType.mp3';
  }

  Future<void> playNoise(String soundType, {double volume = 0.6}) async {
    final assetPath = assetPathForSound(soundType);
    if (_currentNoiseAsset == assetPath && _isNoisePlaying) return;

    await _noisePlayer.stop();
    try {
      await _setNoiseSource(assetPath, soundType);
      await _noisePlayer.setLoopMode(LoopMode.one);
      await _noisePlayer.setVolume(volume);
      await _noisePlayer.play();
      _currentNoiseAsset = assetPath;
      _isNoisePlaying = true;
    } catch (_) {
      _currentNoiseAsset = null;
      _isNoisePlaying = false;
      rethrow;
    }
  }

  Future<void> pauseNoise() async {
    await _noisePlayer.pause();
    _isNoisePlaying = false;
  }

  Future<void> resumeNoise() async {
    if (_currentNoiseAsset == null) return;
    await _noisePlayer.play();
    _isNoisePlaying = true;
  }

  Future<void> stopNoise() async {
    await _noisePlayer.stop();
    _isNoisePlaying = false;
    _currentNoiseAsset = null;
  }

  Future<void> setVolume(double volume) async {
    await _noisePlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> playBell(String bellType) async {
    try {
      final path = assetPathForBell(bellType);
      await _bellPlayer.stop();
      await _bellPlayer.setAsset(path);
      await _bellPlayer.setVolume(1.0);
      await _bellPlayer.play();
    } catch (e) {
      // Bell asset not available, skip silently
      debugPrint('Bell playback failed: $e');
    }
  }

  Future<void> dispose() async {
    await _noisePlayer.dispose();
    await _bellPlayer.dispose();
  }

  Future<void> _setNoiseSource(String assetPath, String soundType) async {
    try {
      await _noisePlayer.setAudioSource(
        AudioSource.asset(assetPath, tag: _mediaItemForSound(soundType)),
      );
    } catch (_) {
      final file = await _cachedAssetFile(assetPath);
      await _noisePlayer.setAudioSource(
        AudioSource.file(file.path, tag: _mediaItemForSound(soundType)),
      );
    }
  }

  MediaItem _mediaItemForSound(String soundType) {
    return MediaItem(
      id: 'focus_noise_$soundType',
      title: displayNameForSound(soundType),
      artist: 'Growth OS 专注白噪音',
    );
  }

  Future<File> _cachedAssetFile(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final cacheDir = await getTemporaryDirectory();
    final targetDir = Directory(p.join(cacheDir.path, 'growth_os_audio_cache'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final file = File(p.join(targetDir.path, p.basename(assetPath)));
    if (!await file.exists() || await file.length() != bytes.lengthInBytes) {
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    return file;
  }
}
