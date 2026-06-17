import '../../../core/database/app_database.dart';
import 'music_assets.dart';

enum MusicScene { lofi, study, sleep, rain, relax, fitness, morning }

class MusicSceneArtwork {
  const MusicSceneArtwork({
    required this.scene,
    required this.label,
    required this.subtitle,
    required this.cover,
    required this.playlistCover,
    required this.cat,
    required this.decorations,
  });

  final MusicScene scene;
  final String label;
  final String subtitle;
  final String cover;
  final String playlistCover;
  final String cat;
  final List<String> decorations;
}

class MusicSceneResolver {
  MusicSceneResolver._();

  static MusicScene resolveTrack(MusicTrack? track) {
    if (track == null) return MusicScene.lofi;
    final manualScene = parseScene(track.sceneOverride);
    if (manualScene != null) return manualScene;
    return resolveText(
      '${track.title} ${track.artist ?? ''} ${track.filePath}',
    );
  }

  static MusicScene? parseScene(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final scene in MusicScene.values) {
      if (scene.name == value) return scene;
    }
    return null;
  }

  static MusicScene resolveText(String value) {
    final text = value.toLowerCase();
    if (_containsAny(text, _sleepKeywords)) return MusicScene.sleep;
    if (_containsAny(text, _rainKeywords)) return MusicScene.rain;
    if (_containsAny(text, _studyKeywords)) return MusicScene.study;
    if (_containsAny(text, _fitnessKeywords)) return MusicScene.fitness;
    if (_containsAny(text, _morningKeywords)) return MusicScene.morning;
    if (_containsAny(text, _relaxKeywords)) return MusicScene.relax;
    if (_containsAny(text, _lofiKeywords)) return MusicScene.lofi;
    return MusicScene.lofi;
  }

  static bool matchesTrack(MusicTrack track, MusicScene scene) {
    return resolveTrack(track) == scene;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static const _lofiKeywords = [
    'lofi',
    'lo-fi',
    'lo fi',
    'chillhop',
    '轻音',
    '日常',
  ];

  static const _studyKeywords = [
    'study',
    'focus',
    'learn',
    'reading',
    'read',
    'homework',
    '学习',
    '专注',
    '阅读',
    '功课',
    '自习',
  ];

  static const _sleepKeywords = [
    'sleep',
    'night',
    'dream',
    'bedtime',
    '晚安',
    '助眠',
    '睡眠',
    '入睡',
    '小夜曲',
    '夜',
  ];

  static const _rainKeywords = [
    'rain',
    'storm',
    'white noise',
    'noise',
    'ocean',
    'wave',
    'forest',
    '雨',
    '雨声',
    '白噪音',
    '海浪',
    '森林',
  ];

  static const _relaxKeywords = [
    'relax',
    'relaxed',
    'chill',
    'cafe',
    'coffee',
    'slow',
    '放松',
    '咖啡',
    '下午茶',
    '治愈',
  ];

  static const _fitnessKeywords = [
    'fitness',
    'workout',
    'sport',
    'run',
    'gym',
    'training',
    '运动',
    '健身',
    '训练',
    '跑步',
    '燃脂',
  ];

  static const _morningKeywords = [
    'morning',
    'sunrise',
    'wake',
    'daybreak',
    '晨间',
    '清晨',
    '早晨',
    '唤醒',
    '日出',
  ];
}

class MusicArtworkMapper {
  MusicArtworkMapper._();

  static MusicSceneArtwork forTrack(MusicTrack? track) {
    return forScene(MusicSceneResolver.resolveTrack(track));
  }

  static String coverForTrack(MusicTrack? track) {
    if (track == null) return MusicAssets.coverDefault;
    final stored = track.coverAsset;
    if (stored != null && stored.isNotEmpty && !isGeneratedCover(stored)) {
      return stored;
    }
    return forTrack(track).cover;
  }

  static bool isGeneratedCover(String? asset) {
    return asset == null ||
        asset.isEmpty ||
        asset == MusicAssets.coverDefault ||
        asset == MusicAssets.coverLofi ||
        asset == MusicAssets.coverStudy ||
        asset == MusicAssets.coverSleep ||
        asset == MusicAssets.coverRain ||
        asset == MusicAssets.coverRelax ||
        asset == MusicAssets.coverFitness ||
        asset == MusicAssets.coverMorning ||
        (asset.contains('/music_cover_') && asset.endsWith('.webp'));
  }

  static MusicSceneArtwork forScene(MusicScene scene) {
    return switch (scene) {
      MusicScene.lofi => const MusicSceneArtwork(
        scene: MusicScene.lofi,
        label: 'Lofi',
        subtitle: '甜甜的日常',
        cover: MusicAssets.coverLofi,
        playlistCover: MusicAssets.playlistCoverDefault,
        cat: MusicAssets.catHeadphone,
        decorations: [
          MusicAssets.decoMusicNote,
          MusicAssets.itemRecordPlayer,
          MusicAssets.itemVinyl,
        ],
      ),
      MusicScene.study => const MusicSceneArtwork(
        scene: MusicScene.study,
        label: '学习',
        subtitle: '专注阅读',
        cover: MusicAssets.coverStudy,
        playlistCover: MusicAssets.playlistCoverStudy,
        cat: MusicAssets.catStudy,
        decorations: [
          MusicAssets.itemBookMusic,
          MusicAssets.itemBooksSleep,
          MusicAssets.itemCoffeeMusic,
        ],
      ),
      MusicScene.sleep => const MusicSceneArtwork(
        scene: MusicScene.sleep,
        label: '助眠',
        subtitle: '晚安放松',
        cover: MusicAssets.coverSleep,
        playlistCover: MusicAssets.playlistCoverSleep,
        cat: MusicAssets.catSleep,
        decorations: [
          MusicAssets.decoMoon,
          MusicAssets.itemSleepMask,
          MusicAssets.itemPillowSleep,
        ],
      ),
      MusicScene.rain => const MusicSceneArtwork(
        scene: MusicScene.rain,
        label: '雨声',
        subtitle: '白噪陪伴',
        cover: MusicAssets.coverRain,
        playlistCover: MusicAssets.playlistCoverRain,
        cat: MusicAssets.catRain,
        decorations: [
          MusicAssets.itemCloudMusic,
          MusicAssets.decoCloudHanging,
          MusicAssets.decoSoundWave,
        ],
      ),
      MusicScene.relax => const MusicSceneArtwork(
        scene: MusicScene.relax,
        label: '放松',
        subtitle: '咖啡时刻',
        cover: MusicAssets.coverRelax,
        playlistCover: MusicAssets.playlistCoverRelax,
        cat: MusicAssets.catRelax,
        decorations: [
          MusicAssets.itemCoffeeMusic,
          MusicAssets.itemBunnyDoll,
          MusicAssets.itemLemonSlice,
        ],
      ),
      MusicScene.fitness => const MusicSceneArtwork(
        scene: MusicScene.fitness,
        label: '运动',
        subtitle: '训练节拍',
        cover: MusicAssets.coverFitness,
        playlistCover: MusicAssets.playlistCoverFitness,
        cat: MusicAssets.catRain,
        decorations: [
          MusicAssets.itemDumbbell,
          MusicAssets.itemKettlebell,
          MusicAssets.itemSportBottle,
        ],
      ),
      MusicScene.morning => const MusicSceneArtwork(
        scene: MusicScene.morning,
        label: '晨间',
        subtitle: '轻轻唤醒',
        cover: MusicAssets.coverMorning,
        playlistCover: MusicAssets.playlistCoverMorning,
        cat: MusicAssets.catHeadphone,
        decorations: [
          MusicAssets.decoStarMusic,
          MusicAssets.itemWaterCup,
          MusicAssets.itemMintLeaf,
        ],
      ),
    };
  }

  static const playlistScenes = [
    MusicScene.study,
    MusicScene.sleep,
    MusicScene.rain,
    MusicScene.relax,
    MusicScene.fitness,
    MusicScene.morning,
  ];
}
