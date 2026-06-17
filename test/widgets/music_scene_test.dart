import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/music/utils/music_assets.dart';
import 'package:growth_os/features/music/utils/music_scene.dart';

void main() {
  test('MusicSceneResolver maps common song and folder names to scenes', () {
    expect(
      MusicSceneResolver.resolveText('专注学习曲 / focus beats.mp3'),
      MusicScene.study,
    );
    expect(
      MusicSceneResolver.resolveText('晚安小夜曲 / sleep.mp3'),
      MusicScene.sleep,
    );
    expect(MusicSceneResolver.resolveText('rain white noise'), MusicScene.rain);
    expect(
      MusicSceneResolver.resolveText('Morning Workout'),
      MusicScene.fitness,
    );
    expect(MusicSceneResolver.resolveText('cafe relax lofi'), MusicScene.relax);
  });

  test('MusicSceneResolver prefers manual scene override', () {
    final track = _track(
      title: 'focus study beats',
      filePath: r'F:\music\study\track.mp3',
      sceneOverride: MusicScene.sleep.name,
    );

    expect(MusicSceneResolver.resolveTrack(track), MusicScene.sleep);
  });

  test(
    'MusicArtworkMapper keeps stored custom covers and replaces defaults',
    () {
      final defaultCovered = _track(
        title: '晨间唤醒',
        filePath: r'F:\music\morning\wake.mp3',
        coverAsset: MusicAssets.coverDefault,
      );
      final customCovered = _track(
        title: 'anything',
        filePath: r'F:\music\custom.mp3',
        coverAsset: MusicAssets.coverLofi,
      );

      expect(
        MusicArtworkMapper.coverForTrack(defaultCovered),
        MusicAssets.coverMorning,
      );
      expect(
        MusicArtworkMapper.coverForTrack(customCovered),
        MusicAssets.coverLofi,
      );
    },
  );

  test('MusicArtworkMapper exposes playlist scenes with concrete artwork', () {
    expect(MusicArtworkMapper.playlistScenes, isNotEmpty);

    for (final scene in MusicArtworkMapper.playlistScenes) {
      final artwork = MusicArtworkMapper.forScene(scene);
      expect(artwork.label, isNotEmpty);
      expect(artwork.cover, startsWith('assets/images/music/'));
      expect(artwork.playlistCover, startsWith('assets/images/music/'));
      expect(artwork.cat, startsWith('assets/images/music/'));
      expect(artwork.decorations, isNotEmpty);
    }
  });
}

MusicTrack _track({
  required String title,
  required String filePath,
  String? coverAsset,
  String? sceneOverride,
}) {
  return MusicTrack(
    id: 1,
    title: title,
    filePath: filePath,
    coverAsset: coverAsset,
    sceneOverride: sceneOverride,
    isFavorite: false,
    createdAt: 0,
    updatedAt: 0,
  );
}
