import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../music/models/music_player_state.dart';
import '../../music/providers/music_player_provider.dart';
import '../../music/utils/music_assets.dart';

/// Facade for focus module to access music player functionality.
///
/// This decouples the focus module from directly importing music module
/// internals. The focus module only needs to:
/// - Play/pause music
/// - Get current playback state
/// - Set volume
/// - Get current track info
class FocusMusicFacade {
  FocusMusicFacade(this._ref);

  final Ref _ref;

  /// Get the current music player state.
  MusicPlayerState get state => _ref.read(musicPlayerProvider);

  /// Watch the music player state for changes.
  MusicPlayerState watchState() => _ref.watch(musicPlayerProvider);

  /// Get the music player controller.
  MusicPlayerController get controller => _ref.read(musicPlayerProvider.notifier);

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

  /// Get the current track.
  MusicTrack? get currentTrack => _ref.read(musicPlayerProvider).currentTrack;

  /// Get the default cover asset.
  String get defaultCoverAsset => MusicAssets.coverDefault;

  /// Get the selected collection.
  MusicCollection get selectedCollection => _ref.read(musicPlayerProvider).selectedCollection;
}

/// Provider for FocusMusicFacade.
final focusMusicFacadeProvider = Provider<FocusMusicFacade>((ref) {
  return FocusMusicFacade(ref);
});
