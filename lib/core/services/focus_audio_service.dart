import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FocusAudioService {
  final AudioPlayer _noisePlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  final Map<String, AudioSource> _noiseSources = {};
  String? _currentNoiseAsset;
  bool _isNoisePlaying = false;
  int _noiseSwitchToken = 0;

  bool get isNoisePlaying => _isNoisePlaying;
  String? get currentNoiseAsset => _currentNoiseAsset;

  static String displayNameForSound(String soundType) {
    switch (soundType) {
      case 'rain':
        return '\u96e8\u58f0';
      case 'ocean':
        return '\u6d77\u6d6a';
      case 'forest':
        return '\u68ee\u6797';
      case 'cafe':
        return '\u5496\u5561\u9986';
      case 'white_noise':
        return '\u767d\u566a\u97f3';
      case 'wind':
        return '\u98ce\u58f0';
      default:
        return soundType;
    }
  }

  static String assetPathForSound(String soundType) {
    return 'assets/audio/noise/$soundType.mp3';
  }

  static const Set<String> supportedNoiseTypes = {
    'rain',
    'ocean',
    'forest',
    'cafe',
    'white_noise',
  };

  static String normalizeSoundType(String soundType) {
    return supportedNoiseTypes.contains(soundType) ? soundType : 'white_noise';
  }

  static String assetPathForBell(String bellType) {
    return 'assets/audio/bell/$bellType.mp3';
  }

  Future<void> playNoise(String soundType, {double volume = 0.6}) async {
    final normalizedSoundType = normalizeSoundType(soundType);
    final assetPath = assetPathForSound(normalizedSoundType);
    final token = ++_noiseSwitchToken;

    try {
      await _noisePlayer.setLoopMode(LoopMode.one);
      await _noisePlayer.setVolume(volume.clamp(0.0, 1.0));

      if (_currentNoiseAsset == assetPath) {
        if (!_isNoisePlaying) {
          await _noisePlayer.play();
          _isNoisePlaying = true;
        }
        return;
      }

      if (_currentNoiseAsset != assetPath) {
        await _noisePlayer.pause();
        await _setNoiseSource(assetPath, normalizedSoundType);
        if (token != _noiseSwitchToken) return;
        _currentNoiseAsset = assetPath;
      }

      await _noisePlayer.seek(Duration.zero);
      if (token != _noiseSwitchToken) return;
      await _noisePlayer.play();
      if (token != _noiseSwitchToken) return;
      _isNoisePlaying = true;
    } catch (_) {
      if (token == _noiseSwitchToken) {
        _currentNoiseAsset = null;
        _isNoisePlaying = false;
      }
      rethrow;
    }
  }

  Future<void> pauseNoise() async {
    _noiseSwitchToken++;
    await _noisePlayer.pause();
    _isNoisePlaying = false;
  }

  Future<void> resumeNoise() async {
    if (_currentNoiseAsset == null) return;
    await _noisePlayer.play();
    _isNoisePlaying = true;
  }

  Future<void> stopNoise() async {
    _noiseSwitchToken++;
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
      debugPrint('Bell playback failed: $e');
    }
  }

  Future<void> dispose() async {
    await _noisePlayer.dispose();
    await _bellPlayer.dispose();
  }

  Future<void> _setNoiseSource(String assetPath, String soundType) async {
    try {
      final source = _noiseSources.putIfAbsent(
        assetPath,
        () => AudioSource.asset(assetPath),
      );
      await _noisePlayer.setAudioSource(source, preload: true);
    } catch (_) {
      final file = await _cachedAssetFile(assetPath);
      final fileKey = 'file:$assetPath';
      final source = _noiseSources.putIfAbsent(
        fileKey,
        () => AudioSource.file(file.path),
      );
      await _noisePlayer.setAudioSource(source, preload: true);
    }
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
