import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/music/services/music_player_service.dart';

void main() {
  test('detects asset audio paths', () {
    expect(
      MusicPlayerService.isAssetPath('assets/audio/noise/rain.mp3'),
      isTrue,
    );
    expect(MusicPlayerService.isAssetPath(r'C:\music\rain.mp3'), isFalse);
  });
}
