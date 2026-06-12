class MusicAssets {
  MusicAssets._();

  static const _root = 'assets/images/music';

  static const catFavorite = '$_root/cat_music_favorite.webp';
  static const catHeadphone = '$_root/cat_music_headphone.webp';
  static const catPlaylist = '$_root/cat_music_playlist.webp';
  static const catRain = '$_root/cat_music_rain.webp';
  static const catRelax = '$_root/cat_music_relax.webp';
  static const catSleep = '$_root/cat_music_sleep.webp';
  static const catStudy = '$_root/cat_music_study.webp';

  static const decoHeart = '$_root/deco_heart_music.webp';
  static const decoNote = '$_root/deco_music_note.png';
  static const decoNotePair = '$_root/deco_music_note_pair.png';
  static const decoSoundWave = '$_root/deco_sound_wave.png';
  static const decoSparkle = '$_root/deco_sparkle_music.png';
  static const decoStar = '$_root/deco_star_music.webp';

  static const emptyFavorite = '$_root/empty_favorite.webp';
  static const emptyHistory = '$_root/empty_history.webp';
  static const emptyImport = '$_root/empty_import_music.webp';
  static const emptyPlaylist = '$_root/empty_playlist.webp';

  static const itemBook = '$_root/item_book_music.webp';
  static const itemCloud = '$_root/item_cloud_music.webp';
  static const itemCoffee = '$_root/item_coffee_music.webp';
  static const itemHeadphone = '$_root/item_headphone.webp';
  static const itemRecordPlayer = '$_root/item_record_player.webp';
  static const itemVinyl = '$_root/item_vinyl.webp';

  static const capsuleIdle = '$_root/music_capsule_idle.png';
  static const capsulePlaying = '$_root/music_capsule_playing.png';
  static const floatPlaceholder = '$_root/music_float_placeholder.webp';
  static const wavePlaying = '$_root/music_wave_playing.png';

  static const coverDefault = '$_root/music_cover_default.webp';
  static const coverFitness = '$_root/music_cover_fitness.webp';
  static const coverLofi = '$_root/music_cover_lofi.webp';
  static const coverMorning = '$_root/music_cover_morning.webp';
  static const coverRain = '$_root/music_cover_rain.webp';
  static const coverSleep = '$_root/music_cover_sleep.webp';
  static const coverStudy = '$_root/music_cover_study.webp';

  static const playlistCoverDefault = '$_root/playlist_cover_default.webp';
  static const playlistCoverFitness = '$_root/playlist_cover_fitness.webp';
  static const playlistCoverMorning = '$_root/playlist_cover_morning.webp';
  static const playlistCoverRain = '$_root/playlist_cover_rain.webp';
  static const playlistCoverRelax = '$_root/playlist_cover_relax.webp';
  static const playlistCoverSleep = '$_root/playlist_cover_sleep.webp';
  static const playlistCoverStudy = '$_root/playlist_cover_study.webp';

  static const settingBackgroundPlay =
      '$_root/music_setting_background_play.webp';
  static const settingCapsule = '$_root/music_setting_capsule.webp';
  static const settingImport = '$_root/music_setting_import.webp';
  static const settingScene = '$_root/music_setting_scene.webp';
  static const settingTimer = '$_root/music_setting_timer.webp';

  static String coverForTitle(String title) {
    final text = title.toLowerCase();
    if (_containsAny(text, const ['lofi', 'lo-fi', '日常', '轻音', 'chill'])) {
      return coverLofi;
    }
    if (_containsAny(text, const ['sleep', 'night', '晚安', '助眠', '睡眠', '入睡'])) {
      return coverSleep;
    }
    if (_containsAny(text, const [
      'study',
      'focus',
      'learn',
      '学习',
      '专注',
      '阅读',
      '功课',
    ])) {
      return coverStudy;
    }
    if (_containsAny(text, const [
      'fitness',
      'workout',
      'sport',
      'run',
      '运动',
      '健身',
      '训练',
      '跑步',
    ])) {
      return coverFitness;
    }
    if (_containsAny(text, const [
      'rain',
      'white noise',
      'noise',
      '雨',
      '白噪音',
      '下雨',
      '雨声',
    ])) {
      return coverRain;
    }
    if (_containsAny(text, const [
      'morning',
      'sunrise',
      'wake',
      '晨间',
      '清晨',
      '早晨',
      '唤醒',
    ])) {
      return coverMorning;
    }
    return coverDefault;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static const all = <String>[
    catFavorite,
    catHeadphone,
    catPlaylist,
    catRain,
    catRelax,
    catSleep,
    catStudy,
    decoHeart,
    decoNote,
    decoNotePair,
    decoSoundWave,
    decoSparkle,
    decoStar,
    emptyFavorite,
    emptyHistory,
    emptyImport,
    emptyPlaylist,
    itemBook,
    itemCloud,
    itemCoffee,
    itemHeadphone,
    itemRecordPlayer,
    itemVinyl,
    capsuleIdle,
    capsulePlaying,
    floatPlaceholder,
    wavePlaying,
    coverDefault,
    coverFitness,
    coverLofi,
    coverMorning,
    coverRain,
    coverSleep,
    coverStudy,
    playlistCoverDefault,
    playlistCoverFitness,
    playlistCoverMorning,
    playlistCoverRain,
    playlistCoverRelax,
    playlistCoverSleep,
    playlistCoverStudy,
    settingBackgroundPlay,
    settingCapsule,
    settingImport,
    settingScene,
    settingTimer,
  ];
}
