import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/models/music_player_state.dart';
import '../../music/providers/music_player_provider.dart';

/// Facade for focus module to access music player functionality.
///
/// This decouples the focus module from directly importing music module
/// internals. The focus module only needs to:
/// - Play/pause music
/// - Get current playback state
/// - Set volume
class FocusMusicFacade {
  FocusMusicFacade(this._ref);

  final Ref _ref;

  /// Get the current music player state.
  MusicPlayerState get state => _ref.read(musicPlayerProvider);

  /// Watch the music player state for changes.
  MusicPlayerState watchState() => _ref.watch(musicPlayerProvider);

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    await _ref.read(musicPlayerProvider.notifier).togglePlayPause();
  }

  /// Pause the current track.
  Future<void> pause() async {
    await _ref.read(musicPlayerProvider.notifier).pause();
  }

  /// Set the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    await _ref.read(musicPlayerProvider.notifier).setVolume(volume);
  }

  /// Get the current volume.
  double get volume => _ref.read(musicPlayerProvider).volume;

  /// Check if music is currently playing.
  bool get isPlaying => _ref.read(musicPlayerProvider).isPlaying;
}

/// Provider for FocusMusicFacade.
final focusMusicFacadeProvider = Provider<FocusMusicFacade>((ref) {
  return FocusMusicFacade(ref);
});
