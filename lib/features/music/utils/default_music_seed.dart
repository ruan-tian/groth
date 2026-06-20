import '../../../core/database/app_database.dart';
import 'music_assets.dart';

class DefaultMusicSeed {
  const DefaultMusicSeed({
    required this.title,
    required this.filePath,
    required this.originalPath,
    required this.coverAsset,
    required this.sceneOverride,
  });

  final String title;
  final String filePath;
  final String originalPath;
  final String coverAsset;
  final String sceneOverride;
}

class DefaultMusicSeeds {
  DefaultMusicSeeds._();

  static const playlistName = '学习歌单';
  static const playlistCover = MusicAssets.playlistCoverStudy;
  static const assetPrefix = 'builtin:focus-noise:';

  static const seeds = <DefaultMusicSeed>[
    DefaultMusicSeed(
      title: '雨声',
      filePath: 'assets/audio/noise/rain.mp3',
      originalPath: '${assetPrefix}rain',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
    DefaultMusicSeed(
      title: '海浪',
      filePath: 'assets/audio/noise/ocean.mp3',
      originalPath: '${assetPrefix}ocean',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
    DefaultMusicSeed(
      title: '森林',
      filePath: 'assets/audio/noise/forest.mp3',
      originalPath: '${assetPrefix}forest',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
    DefaultMusicSeed(
      title: '咖啡馆',
      filePath: 'assets/audio/noise/cafe.mp3',
      originalPath: '${assetPrefix}cafe',
      coverAsset: MusicAssets.coverRelax,
      sceneOverride: 'relax',
    ),
    DefaultMusicSeed(
      title: '白噪音',
      filePath: 'assets/audio/noise/white_noise.mp3',
      originalPath: '${assetPrefix}white_noise',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
  ];

  static bool isSeedTrack(MusicTrack track) {
    final originalPath = track.originalPath;
    if (originalPath == null) return false;
    return originalPath.startsWith(assetPrefix);
  }
}
