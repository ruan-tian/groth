import '../../../shared/providers/focus_provider.dart';

class FocusAssets {
  FocusAssets._();

  static const _root = 'assets/images/focus';

  static const bgOverview = '$_root/backgrounds/bg_focus_overview.webp';
  static const bgSessionPortrait =
      '$_root/backgrounds/bg_focus_session_portrait.webp';
  static const bgSessionLandscape =
      '$_root/backgrounds/bg_focus_session_landscape.webp';

  static const deskPortrait =
      '$_root/foregrounds/fg_focus_desk_portrait.png';
  static const deskLandscape =
      '$_root/foregrounds/fg_focus_desk_landscape.png';

  static const catIdle = '$_root/cats/focus_cat_idle.png';
  static const catReading = '$_root/cats/focus_cat_reading.png';
  static const catWriting = '$_root/cats/focus_cat_writing.png';
  static const catThinking = '$_root/cats/focus_cat_thinking.png';
  static const catRest = '$_root/cats/focus_cat_rest.png';
  static const catDone = '$_root/cats/focus_cat_done.png';

  static const iconPomodoro = '$_root/icons/icon_focus_pomodoro.png';
  static const iconDeep = '$_root/icons/icon_focus_deep.png';
  static const iconUltra = '$_root/icons/icon_focus_ultra.png';
  static const iconCustom = '$_root/icons/icon_focus_custom.png';

  static const soundRain = '$_root/sounds/icon_sound_rain.png';
  static const soundOcean = '$_root/sounds/icon_sound_ocean.png';
  static const soundForest = '$_root/sounds/icon_sound_forest.png';
  static const soundCafe = '$_root/sounds/icon_sound_cafe.png';
  static const soundWhiteNoise = '$_root/sounds/icon_sound_white_noise.png';
  static const soundNone = '$_root/sounds/icon_sound_none.png';

  static const roomGlow = '$_root/lights/light_focus_room_glow.png';
  static const ringGlow = '$_root/lights/light_focus_ring_glow.png';
  static const restGlow = '$_root/lights/light_focus_rest_glow.png';

  static const particleSparkle =
      '$_root/particles/particle_focus_sparkle.png';
  static const particleLeaf = '$_root/particles/particle_focus_leaf.png';
  static const particleHeart = '$_root/particles/particle_focus_heart.png';
  static const particleTomato = '$_root/particles/particle_focus_tomato.png';
  static const particleStar = '$_root/particles/particle_focus_star.png';
  static const particleRain = '$_root/particles/particle_focus_rain.png';

  static const successBadge = '$_root/status/focus_success_badge.png';
  static const breakCup = '$_root/status/focus_break_cup.png';
  static const interruptWarning =
      '$_root/status/focus_interrupt_warning.png';
  static const expReward = '$_root/status/focus_exp_reward.png';

  static const all = <String>[
    bgOverview,
    bgSessionPortrait,
    bgSessionLandscape,
    deskPortrait,
    deskLandscape,
    catIdle,
    catReading,
    catWriting,
    catThinking,
    catRest,
    catDone,
    iconPomodoro,
    iconDeep,
    iconUltra,
    iconCustom,
    soundRain,
    soundOcean,
    soundForest,
    soundCafe,
    soundWhiteNoise,
    soundNone,
    roomGlow,
    ringGlow,
    restGlow,
    particleSparkle,
    particleLeaf,
    particleHeart,
    particleTomato,
    particleStar,
    particleRain,
    successBadge,
    breakCup,
    interruptWarning,
    expReward,
  ];

  static String iconForType(String type) {
    switch (type) {
      case 'deep':
        return iconDeep;
      case 'ultra':
        return iconUltra;
      case 'custom':
        return iconCustom;
      case 'pomodoro':
      default:
        return iconPomodoro;
    }
  }

  static String iconForSound(String soundType) {
    switch (soundType) {
      case 'rain':
        return soundRain;
      case 'ocean':
        return soundOcean;
      case 'forest':
        return soundForest;
      case 'cafe':
        return soundCafe;
      case 'white_noise':
        return soundWhiteNoise;
      case 'none':
      default:
        return soundNone;
    }
  }

  static String catForCycle(FocusCycleState cycleState) {
    if (cycleState.isBreak) return catRest;
    if (!cycleState.isRunning && cycleState.remainingSeconds <= 0) {
      return catDone;
    }
    switch (cycleState.currentRound % 3) {
      case 1:
        return catReading;
      case 2:
        return catWriting;
      default:
        return catThinking;
    }
  }
}
