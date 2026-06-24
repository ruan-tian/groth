import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/core/services/focus_audio_service.dart';
import 'package:growth_os/shared/providers/focus_audio_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changeSound keeps all built-in white noise choices active', () async {
    final service = _FakeFocusAudioService();
    final container = ProviderContainer(
      overrides: [focusAudioServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    addTearDown(service.dispose);

    final notifier = container.read(focusAudioStateProvider.notifier);

    for (final soundType in FocusAudioService.supportedNoiseTypes) {
      await notifier.changeSound(soundType);

      final state = container.read(focusAudioStateProvider);
      expect(state.currentSoundType, soundType);
      expect(state.isPlaying, isTrue);
      expect(state.errorMessage, isNull);
    }

    expect(service.playedSoundTypes, [
      'rain',
      'ocean',
      'forest',
      'cafe',
      'white_noise',
    ]);
  });
}

class _FakeFocusAudioService extends FocusAudioService {
  final List<String> playedSoundTypes = [];
  bool _playing = false;

  @override
  bool get isNoisePlaying => _playing;

  @override
  Future<void> playNoise(String soundType, {double volume = 0.6}) async {
    playedSoundTypes.add(FocusAudioService.normalizeSoundType(soundType));
    _playing = true;
  }

  @override
  Future<void> stopNoise() async {
    _playing = false;
  }

  @override
  Future<void> pauseNoise() async {
    _playing = false;
  }

  @override
  Future<void> resumeNoise() async {
    _playing = true;
  }
}
