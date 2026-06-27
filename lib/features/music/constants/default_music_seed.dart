import '../../../core/database/app_database.dart';
import '../utils/music_assets.dart';

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

  static const playlistName = '\u4e13\u6ce8\u767d\u566a\u97f3';
  static const legacyPlaylistName = '\u5b66\u4e60\u6b4c\u5355';
  static const playlistCover = MusicAssets.playlistCoverStudy;
  static const assetPrefix = 'builtin:focus-noise:';

  static const seeds = <DefaultMusicSeed>[
    DefaultMusicSeed(
      title: '\u96e8\u58f0',
      filePath: 'assets/audio/noise/rain.mp3',
      originalPath: '${assetPrefix}rain',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
    DefaultMusicSeed(
      title: '\u6d77\u6d6a',
      filePath: 'assets/audio/noise/ocean.mp3',
      originalPath: '${assetPrefix}ocean',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
    DefaultMusicSeed(
      title: '\u68ee\u6797',
      filePath: 'assets/audio/noise/forest.mp3',
      originalPath: '${assetPrefix}forest',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
    DefaultMusicSeed(
      title: '\u5496\u5561\u9986',
      filePath: 'assets/audio/noise/cafe.mp3',
      originalPath: '${assetPrefix}cafe',
      coverAsset: MusicAssets.coverRelax,
      sceneOverride: 'relax',
    ),
    DefaultMusicSeed(
      title: '\u767d\u566a\u97f3',
      filePath: 'assets/audio/noise/white_noise.mp3',
      originalPath: '${assetPrefix}white_noise',
      coverAsset: MusicAssets.coverRain,
      sceneOverride: 'rain',
    ),
  ];

  static bool isSeedTrack(MusicTrack track) {
    return isSeedOriginalPath(track.originalPath);
  }

  static bool isSeedOriginalPath(String? originalPath) {
    return originalPath?.startsWith(assetPrefix) ?? false;
  }
}
