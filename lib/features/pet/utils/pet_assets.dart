/// 宠物系统全部资源路径统一管理
///
/// 所有组件只能引用这个类的常量，不允许散写字符串路径。
class PetAssets {
  PetAssets._();

  // ── Root-level PetState images ──
  static const petIdle = 'assets/pet/common/common_fallback.png';
  static const petHappy = 'assets/pet/common/common_happy.png';
  static const petPeek =
      'assets/pet/common/common_happy.png'; // peek 无专属文件，临时复用
  static const petSleepy = 'assets/pet/emotions/好困.png';

  // ── Module Scene States ──
  static const studyReading = 'assets/pet/study/study_reading.png';
  static const studyWriting = 'assets/pet/study/study_writing.png';
  static const studyFocus = 'assets/pet/study/study_focus.png';
  static const studyDone = 'assets/pet/study/study_done.png';

  static const fitnessLifting = 'assets/pet/fitness/fitness_lifting.png';
  static const fitnessStretch = 'assets/pet/fitness/fitness_stretch.png';
  static const fitnessDrink = 'assets/pet/fitness/fitness_drink.png';
  static const fitnessDone = 'assets/pet/fitness/fitness_done.png';

  static const journalWriting = 'assets/pet/journal/journal_writing.png';
  static const journalThinking = 'assets/pet/journal/journal_thinking.png';
  static const journalBook = 'assets/pet/journal/journal_book.png';
  static const journalDone = 'assets/pet/journal/journal_done.png';

  static const dietEating = 'assets/pet/diet/diet_eating.png';
  static const dietDrink = 'assets/pet/diet/diet_drink.png';
  static const dietPlate = 'assets/pet/diet/diet_plate.png';
  static const dietDone = 'assets/pet/diet/diet_done.png';

  static const sleepYawn = 'assets/pet/sleep/sleep_yawn.png';
  static const sleepSleeping = 'assets/pet/sleep/sleep_sleeping.png';
  static const sleepStretch = 'assets/pet/sleep/sleep_stretch.png';
  static const sleepDone = 'assets/pet/sleep/sleep_done.png';

  // ── Module defaults (每个模块的默认展示图) ──
  static const moduleDefaultStudy = 'assets/pet/study/study_reading.png';
  static const moduleDefaultFitness = 'assets/pet/fitness/fitness_lifting.png';
  static const moduleDefaultJournal = 'assets/pet/journal/journal_writing.png';
  static const moduleDefaultDiet = 'assets/pet/diet/diet_eating.png';
  static const moduleDefaultSleep = 'assets/pet/sleep/sleep_yawn.png';
  static const moduleDefaultFocus = 'assets/pet/study/study_focus.png';

  // ── Focus Module (aliases to existing images) ──
  static const focusReading = 'assets/pet/study/study_reading.png';
  static const focusWriting = 'assets/pet/study/study_writing.png';
  static const focusThinking = 'assets/pet/study/study_focus.png';
  static const focusDone = 'assets/pet/study/study_done.png';
  static const focusRest = 'assets/pet/life/喝个茶.png';

  // ── Common States ──
  static const commonHappy = 'assets/pet/common/common_happy.png';
  static const commonIdle = 'assets/pet/common/common_idle.png';
  static const commonThinking = 'assets/pet/common/common_thinking.png';
  static const commonReport = 'assets/pet/common/common_report.png';
  static const commonError = 'assets/pet/common/common_error.png';
  static const commonLoading = 'assets/pet/common/common_loading.png';
  static const commonEmpty = 'assets/pet/common/common_empty.png';
  static const commonWarning = 'assets/pet/common/common_warning.png';
  static const commonFallback = 'assets/pet/common/common_fallback.png';

  // ── Events ──
  static const eventLevelUp = 'assets/pet/events/event_level_up.png';
  static const eventExpGain = 'assets/pet/events/event_exp_gain.png';
  static const eventStreak7 = 'assets/pet/events/event_streak_7.png';
  static const eventStreak30 = 'assets/pet/events/event_streak_30.png';
  static const eventGoalDone = 'assets/pet/events/event_goal_done.png';
  static const eventTaskDone = 'assets/pet/events/event_task_done.png';
  static const eventWeeklyRpt = 'assets/pet/events/event_weekly_report.png';
  static const eventMonthlyRpt = 'assets/pet/events/event_monthly_report.png';
  static const eventComeback = 'assets/pet/events/event_comeback.png';
  static const eventEncourage = 'assets/pet/events/event_encourage.png';

  // ── AI States ──
  static const aiThinking = 'assets/pet/ai/ai_thinking.png';
  static const aiReport = 'assets/pet/ai/ai_report.png';
  static const aiPrivacy = 'assets/pet/ai/ai_privacy.png';
  static const aiPointing = 'assets/pet/ai/ai_pointing.png';
  static const aiNetworkError = 'assets/pet/ai/ai_network_error.png';
  static const aiKeyMissing = 'assets/pet/ai/ai_key_missing.png';
  static const aiJsonError = 'assets/pet/ai/ai_json_error.png';
  static const aiDailySummary = 'assets/pet/ai/ai_daily_summary.png';

  // ── Center Hero (time-of-day greetings) ──
  static const heroMorning = 'assets/pet/emotions/打招呼.png';
  static const heroAfternoon = 'assets/pet/life/敲键盘.png';
  static const heroEvening = 'assets/pet/life/听音乐.png';
  static const heroNight = 'assets/pet/emotions/好困.png';
}

enum PetCenterTimeSlot { morning, afternoon, evening, night }

class PetCenterAssets {
  PetCenterAssets._();

  static const _root = 'assets/images/pet_center';

  static const bgMorning = '$_root/backgrounds/bg_pet_morning.webp';
  static const bgAfternoon = '$_root/backgrounds/bg_pet_afternoon.webp';
  static const bgEvening = '$_root/backgrounds/bg_pet_evening.webp';
  static const bgNight = '$_root/backgrounds/bg_pet_night.webp';

  static const ground = '$_root/foregrounds/fg_pet_ground.webp';
  static const furniture = '$_root/foregrounds/fg_pet_furniture.webp';

  static const petIdle = '$_root/pets/pet_center_idle.png';
  static const petWave = '$_root/pets/pet_center_wave.png';
  static const petRead = '$_root/pets/pet_center_read.png';
  static const petSleep = '$_root/pets/pet_center_sleep.png';
  static const petHappy = '$_root/pets/pet_center_happy.png';
  static const petThink = '$_root/pets/pet_center_think.png';

  static const decoBook = '$_root/deco/deco_book.png';
  static const decoPencil = '$_root/deco/deco_pencil.png';
  static const decoTarget = '$_root/deco/deco_target.png';
  static const decoStar = '$_root/deco/deco_star.png';
  static const decoTrophy = '$_root/deco/deco_trophy.png';
  static const decoHeart = '$_root/deco/deco_heart.png';
  static const decoPlant = '$_root/deco/deco_plant.png';
  static const decoLamp = '$_root/deco/deco_lamp.png';

  static const particleHeart = '$_root/particles/particle_heart.png';
  static const particleStar = '$_root/particles/particle_star.png';
  static const particleSparkle = '$_root/particles/particle_sparkle.png';
  static const particlePetals = '$_root/particles/particle_petals.png';

  static const bubbleTip = '$_root/effects/bubble_pet_tip.png';
  static const softShadow = '$_root/effects/soft_shadow_pet.png';
  static const roomGlow = '$_root/effects/light_room_glow.webp';
  static const bubbleTail = 'assets/images/weather/common/bubble_tail.png';

  static const all = <String>[
    bgMorning,
    bgAfternoon,
    bgEvening,
    bgNight,
    ground,
    furniture,
    petIdle,
    petWave,
    petRead,
    petSleep,
    petHappy,
    petThink,
    decoBook,
    decoPencil,
    decoTarget,
    decoStar,
    decoTrophy,
    decoHeart,
    decoPlant,
    decoLamp,
    particleHeart,
    particleStar,
    particleSparkle,
    particlePetals,
    bubbleTip,
    bubbleTail,
    softShadow,
    roomGlow,
  ];

  static String backgroundForTime(PetCenterTimeSlot slot) {
    switch (slot) {
      case PetCenterTimeSlot.morning:
        return bgMorning;
      case PetCenterTimeSlot.afternoon:
        return bgAfternoon;
      case PetCenterTimeSlot.evening:
        return bgEvening;
      case PetCenterTimeSlot.night:
        return bgNight;
    }
  }

  static String fallbackPetForTime(PetCenterTimeSlot slot) {
    switch (slot) {
      case PetCenterTimeSlot.morning:
        return petWave;
      case PetCenterTimeSlot.afternoon:
        return petRead;
      case PetCenterTimeSlot.evening:
        return petIdle;
      case PetCenterTimeSlot.night:
        return petSleep;
    }
  }

  static String petForAction(String? action, PetCenterTimeSlot slot) {
    switch (action) {
      case 'wave':
      case 'greeting':
        return petWave;
      case 'read':
      case 'study':
      case 'focus':
        return petRead;
      case 'sleep':
      case 'rest':
        return petSleep;
      case 'happy':
      case 'done':
      case 'complete':
      case 'levelUp':
      case 'level_up':
        return petHappy;
      case 'think':
      case 'thinking':
      case 'ai':
      case 'analysis':
        return petThink;
      case 'idle':
        return petIdle;
      default:
        return fallbackPetForTime(slot);
    }
  }

  static List<String> decoForLevel(int level) {
    if (level >= 20) {
      return const [decoBook, decoPencil, decoTarget, decoStar, decoTrophy];
    }
    if (level >= 11) {
      return const [decoBook, decoPencil, decoStar, decoLamp];
    }
    if (level >= 6) {
      return const [decoBook, decoStar, decoPlant];
    }
    return const [decoBook, decoHeart];
  }
}
