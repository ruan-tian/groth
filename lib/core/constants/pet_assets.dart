/// 宠物系统全部资源路径统一管理
///
/// 所有组件只能引用这个类的常量，不允许散写字符串路径。
class PetAssets {
  PetAssets._();

  // ── Root-level PetState images ──
  static const petIdle = 'assets/pet/common/common_fallback.webp';
  static const petHappy = 'assets/pet/common/common_happy.webp';
  static const petPeek =
      'assets/pet/common/common_happy.webp'; // peek 无专属文件，临时复用
  static const petSleepy = 'assets/pet/emotions/好困.webp';

  // ── Module Scene States ──
  static const studyReading = 'assets/pet/study/study_reading.webp';
  static const studyWriting = 'assets/pet/study/study_writing.webp';
  static const studyFocus = 'assets/pet/study/study_focus.webp';
  static const studyDone = 'assets/pet/study/study_done.webp';

  static const fitnessLifting = 'assets/pet/fitness/fitness_lifting.webp';
  static const fitnessStretch = 'assets/pet/fitness/fitness_stretch.webp';
  static const fitnessDrink = 'assets/pet/fitness/fitness_drink.webp';
  static const fitnessDone = 'assets/pet/fitness/fitness_done.webp';

  static const journalWriting = 'assets/pet/journal/journal_writing.webp';
  static const journalThinking = 'assets/pet/journal/journal_thinking.webp';
  static const journalBook = 'assets/pet/journal/journal_book.webp';
  static const journalDone = 'assets/pet/journal/journal_writing.webp';

  // ── Journal Banners (完整底图，陪伴卡轮播用) ──
  static const journalBannerWriting =
      'assets/journal/banners/journal_banner_writing.webp';
  static const journalBannerThinking =
      'assets/journal/banners/journal_banner_thinking.webp';
  static const journalBannerReading =
      'assets/journal/banners/journal_banner_reading.webp';
  static const journalBannerDone =
      'assets/journal/banners/journal_banner_done.webp';
  static const journalTodayRecordBg =
      'assets/journal/banners/journal_today_record_bg.webp';

  static const dietEating = 'assets/pet/diet/diet_eating.webp';
  static const dietDrink = 'assets/pet/diet/diet_drink.webp';
  static const dietPlate = 'assets/pet/diet/diet_plate.webp';
  static const dietDone = 'assets/pet/diet/diet_done.webp';

  static const sleepYawn = 'assets/pet/sleep/sleep_yawn.webp';
  static const sleepSleeping = 'assets/pet/sleep/sleep_sleeping.webp';
  static const sleepStretch = 'assets/pet/sleep/sleep_stretch.webp';
  static const sleepDone = 'assets/pet/sleep/sleep_done.webp';

  // ── Module defaults (每个模块的默认展示图) ──
  static const moduleDefaultStudy = 'assets/pet/study/study_reading.webp';
  static const moduleDefaultFitness = 'assets/pet/fitness/fitness_lifting.webp';
  static const moduleDefaultJournal = 'assets/pet/journal/journal_writing.webp';
  static const moduleDefaultDiet = 'assets/pet/diet/diet_eating.webp';
  static const moduleDefaultSleep = 'assets/pet/sleep/sleep_yawn.webp';
  static const moduleDefaultFocus = 'assets/pet/study/study_focus.webp';
  static const moduleDefaultMusic = 'assets/pet/common/common_happy.webp';
  static const moduleDefaultAccounting = 'assets/pet/common/common_report.webp';

  // ── Empty States ──
  static const emptyStudy = 'assets/pet/empty/empty_study.webp';
  static const emptyFitness = 'assets/pet/empty/empty_fitness.webp';
  static const emptyJournal = 'assets/pet/empty/empty_journal.webp';
  static const emptyDiet = 'assets/pet/empty/empty_diet.webp';
  static const emptySleep = 'assets/pet/empty/empty_sleep.webp';

  // ── Focus Module (aliases to existing images) ──
  static const focusReading = 'assets/pet/study/study_reading.webp';
  static const focusWriting = 'assets/pet/study/study_writing.webp';
  static const focusThinking = 'assets/pet/study/study_focus.webp';
  static const focusDone = 'assets/pet/study/study_done.webp';
  static const focusRest = 'assets/pet/life/喝个茶.webp';

  // ── Common States ──
  static const commonHappy = 'assets/pet/common/common_happy.webp';
  static const commonIdle = 'assets/pet/common/common_idle.webp';
  static const commonThinking = 'assets/pet/common/common_thinking.webp';
  static const commonReport = 'assets/pet/common/common_report.webp';
  static const commonError = 'assets/pet/common/common_error.webp';
  static const commonLoading = 'assets/pet/common/common_loading.webp';
  static const commonEmpty = 'assets/pet/common/common_empty.webp';
  static const commonWarning = 'assets/pet/common/common_warning.webp';
  static const commonFallback = 'assets/pet/common/common_fallback.webp';

  // ── Events ──
  static const eventLevelUp = 'assets/pet/events/event_level_up.webp';
  static const eventExpGain = 'assets/pet/events/event_exp_gain.webp';
  static const eventStreak7 = 'assets/pet/events/event_streak_7.webp';
  static const eventStreak30 = 'assets/pet/events/event_streak_30.webp';
  static const eventGoalDone = 'assets/pet/events/event_goal_done.webp';
  static const eventTaskDone = 'assets/pet/events/event_task_done.webp';
  static const eventWeeklyRpt = 'assets/pet/events/event_weekly_report.webp';
  static const eventMonthlyRpt = 'assets/pet/events/event_monthly_report.webp';
  static const eventComeback = 'assets/pet/events/event_comeback.webp';
  static const eventEncourage = 'assets/pet/events/event_encourage.webp';

  // ── AI States ──
  static const aiThinking = 'assets/pet/ai/ai_thinking.webp';
  static const aiReport = 'assets/pet/ai/ai_report.webp';
  static const aiPrivacy = 'assets/pet/ai/ai_privacy.webp';
  static const aiPointing = 'assets/pet/ai/ai_pointing.webp';
  static const aiNetworkError = 'assets/pet/ai/ai_network_error.webp';
  static const aiKeyMissing = 'assets/pet/ai/ai_key_missing.webp';
  static const aiJsonError = 'assets/pet/ai/ai_json_error.webp';
  static const aiDailySummary = 'assets/pet/ai/ai_daily_summary.webp';

  // ── Center Hero (time-of-day greetings) ──
  static const heroMorning = 'assets/pet/emotions/打招呼.webp';
  static const heroAfternoon = 'assets/pet/life/敲键盘.webp';
  static const heroEvening = 'assets/pet/life/听音乐.webp';
  static const heroNight = 'assets/pet/emotions/好困.webp';
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

  static const petIdle = '$_root/pets/pet_center_idle.webp';
  static const petWave = '$_root/pets/pet_center_wave.webp';
  static const petRead = '$_root/pets/pet_center_read.webp';
  static const petSleep = '$_root/pets/pet_center_sleep.webp';
  static const petHappy = '$_root/pets/pet_center_happy.webp';
  static const petThink = '$_root/pets/pet_center_think.webp';

  static const decoBook = '$_root/deco/deco_book.webp';
  static const decoPencil = '$_root/deco/deco_pencil.webp';
  static const decoTarget = '$_root/deco/deco_target.webp';
  static const decoStar = '$_root/deco/deco_star.webp';
  static const decoTrophy = '$_root/deco/deco_trophy.webp';
  static const decoHeart = '$_root/deco/deco_heart.webp';
  static const decoPlant = '$_root/deco/deco_plant.webp';
  static const decoLamp = '$_root/deco/deco_lamp.webp';

  static const particleHeart = '$_root/particles/particle_heart.webp';
  static const particleStar = '$_root/particles/particle_star.webp';
  static const particleSparkle = '$_root/particles/particle_sparkle.webp';
  static const particlePetals = '$_root/particles/particle_petals.webp';

  static const bubbleTip = '$_root/effects/bubble_pet_tip.webp';
  static const softShadow = '$_root/effects/soft_shadow_pet.webp';
  static const roomGlow = '$_root/effects/light_room_glow.webp';
  static const bubbleTail = 'assets/images/weather/common/bubble_tail.webp';

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
