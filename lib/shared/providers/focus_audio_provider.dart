import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/focus_audio_service.dart';

final focusAudioServiceProvider = Provider<FocusAudioService>((ref) {
  final service = FocusAudioService();
  FocusAudioService.initBackground();
  ref.onDispose(() => service.dispose());
  return service;
});

class FocusAudioState {
  final String? currentSoundType;
  final double volume;
  final bool isPlaying;
  final String? errorMessage;

  const FocusAudioState({
    this.currentSoundType,
    this.volume = 0.6,
    this.isPlaying = false,
    this.errorMessage,
  });

  FocusAudioState copyWith({
    Object? currentSoundType = _sentinel,
    double? volume,
    bool? isPlaying,
    Object? errorMessage = _sentinel,
  }) {
    return FocusAudioState(
      currentSoundType: currentSoundType == _sentinel
          ? this.currentSoundType
          : currentSoundType as String?,
      volume: volume ?? this.volume,
      isPlaying: isPlaying ?? this.isPlaying,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

final focusAudioStateProvider =
    StateNotifierProvider<FocusAudioStateNotifier, FocusAudioState>((ref) {
      return FocusAudioStateNotifier(ref);
    });

class FocusAudioStateNotifier extends StateNotifier<FocusAudioState> {
  final Ref _ref;

  FocusAudioStateNotifier(this._ref) : super(const FocusAudioState());

  Future<void> startNoise(String soundType) async {
    final service = _ref.read(focusAudioServiceProvider);
    try {
      await service.playNoise(soundType, volume: state.volume);
      state = state.copyWith(
        currentSoundType: soundType,
        isPlaying: true,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        currentSoundType: null,
        isPlaying: false,
        errorMessage: '白噪音播放失败，请重试',
      );
    }
  }

  Future<void> pauseNoise() async {
    final service = _ref.read(focusAudioServiceProvider);
    await service.pauseNoise();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resumeNoise() async {
    final service = _ref.read(focusAudioServiceProvider);
    await service.resumeNoise();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> stopNoise() async {
    final service = _ref.read(focusAudioServiceProvider);
    await service.stopNoise();
    state = state.copyWith(
      currentSoundType: null,
      isPlaying: false,
      errorMessage: null,
    );
  }

  Future<void> setVolume(double volume) async {
    final service = _ref.read(focusAudioServiceProvider);
    await service.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  /// Re-sync UI state with actual player state.
  /// Call when app resumes from background to avoid UI/audio mismatch.
  Future<void> resyncState() async {
    try {
      final service = _ref.read(focusAudioServiceProvider);
      if (state.isPlaying != service.isNoisePlaying) {
        state = state.copyWith(isPlaying: service.isNoisePlaying);
      }
    } catch (_) {}
  }

  Future<void> playBell(String bellType) async {
    final service = _ref.read(focusAudioServiceProvider);
    await service.playBell(bellType);
  }

  Future<void> changeSound(String soundType) async {
    final service = _ref.read(focusAudioServiceProvider);
    await service.stopNoise();
    try {
      await service.playNoise(soundType, volume: state.volume);
      state = state.copyWith(
        currentSoundType: soundType,
        isPlaying: true,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        currentSoundType: null,
        isPlaying: false,
        errorMessage: '白噪音播放失败，请重试',
      );
    }
  }
}
