enum PlanModuleType { study, fitness, journal, diet, sleep }

class PlanModuleAssets {
  PlanModuleAssets._();

  static const _root = 'assets/images/plan_modules';

  static const studyHero = [
    '$_root/study/hero/study_hero_1.webp',
    '$_root/study/hero/study_hero_2.webp',
    '$_root/study/hero/study_hero_3.webp',
    '$_root/study/hero/study_hero_4.webp',
  ];
  static const fitnessHero = [
    '$_root/fitness/hero/fitness_hero_1.webp',
    '$_root/fitness/hero/fitness_hero_2.webp',
    '$_root/fitness/hero/fitness_hero_3.webp',
    '$_root/fitness/hero/fitness_hero_4.webp',
  ];
  static const journalHero = [
    '$_root/journal/hero/journal_hero_1.webp',
    '$_root/journal/hero/journal_hero_2.webp',
    '$_root/journal/hero/journal_hero_3.webp',
    '$_root/journal/hero/journal_hero_4.webp',
  ];
  static const dietHero = [
    '$_root/diet/hero/diet_hero_1.webp',
    '$_root/diet/hero/diet_hero_2.webp',
    '$_root/diet/hero/diet_hero_3.webp',
    '$_root/diet/hero/diet_hero_4.webp',
  ];
  static const sleepHero = [
    '$_root/sleep/hero/sleep_hero_1.webp',
    '$_root/sleep/hero/sleep_hero_2.webp',
    '$_root/sleep/hero/sleep_hero_3.webp',
    '$_root/sleep/hero/sleep_hero_4.webp',
  ];

  static const studyTimer = '$_root/study/timer/study_timer.webp';
  static const fitnessTimer = '$_root/fitness/timer/fitness_timer.webp';
  static const journalTimer = '$_root/journal/timer/journal_timer.webp';
  static const dietTimer = '$_root/diet/timer/diet_timer.webp';
  static const sleepTimer = '$_root/sleep/timer/sleep_timer.webp';

  static const studyPremiumPetBanner = '$_root/study/premium/pet_banner.webp';
  static const studyPremiumHeroScene = '$_root/study/premium/hero_scene.webp';
  static const studyPremiumV2PetBanner =
      '$_root/study/premium_v2/pet_banner.webp';
  static const studyPremiumV2HeroScene =
      '$_root/study/premium_v2/hero_scene.webp';
  static const fitnessPremiumPetBanner =
      '$_root/fitness/premium/pet_banner.webp';
  static const fitnessPremiumHeroScene =
      '$_root/fitness/premium/hero_scene.webp';
  static const fitnessPremiumV2PetBanner =
      '$_root/fitness/premium_v2/pet_banner.webp';
  static const fitnessPremiumV2HeroScene =
      '$_root/fitness/premium_v2/hero_scene.webp';
  static const journalPremiumPetBanner =
      '$_root/journal/premium/pet_banner.webp';
  static const journalPremiumHeroScene =
      '$_root/journal/premium/hero_scene.webp';
  static const journalPremiumV2PetBanner =
      '$_root/journal/premium_v2/pet_banner.webp';
  static const journalPremiumV2HeroScene =
      '$_root/journal/premium_v2/hero_scene.webp';
  static const dietPremiumPetBanner = '$_root/diet/premium/pet_banner.webp';
  static const dietPremiumHeroScene = '$_root/diet/premium/hero_scene.webp';
  static const dietPremiumV2PetBanner =
      '$_root/diet/premium_v2/pet_banner.webp';
  static const dietPremiumV2HeroScene =
      '$_root/diet/premium_v2/hero_scene.webp';
  static const sleepPremiumPetBanner = '$_root/sleep/premium/pet_banner.webp';
  static const sleepPremiumHeroScene = '$_root/sleep/premium/hero_scene.webp';
  static const sleepPremiumV2PetBanner =
      '$_root/sleep/premium_v2/pet_banner.webp';
  static const sleepPremiumV2HeroScene =
      '$_root/sleep/premium_v2/hero_scene.webp';

  static List<String> heroImages(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => studyHero,
      PlanModuleType.fitness => fitnessHero,
      PlanModuleType.journal => journalHero,
      PlanModuleType.diet => dietHero,
      PlanModuleType.sleep => sleepHero,
    };
  }

  static String timerImage(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => studyTimer,
      PlanModuleType.fitness => fitnessTimer,
      PlanModuleType.journal => journalTimer,
      PlanModuleType.diet => dietTimer,
      PlanModuleType.sleep => sleepTimer,
    };
  }

  static String premiumPetBanner(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => studyPremiumPetBanner,
      PlanModuleType.fitness => fitnessPremiumPetBanner,
      PlanModuleType.journal => journalPremiumPetBanner,
      PlanModuleType.diet => dietPremiumPetBanner,
      PlanModuleType.sleep => sleepPremiumPetBanner,
    };
  }

  static String premiumV2PetBanner(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => studyPremiumV2PetBanner,
      PlanModuleType.fitness => fitnessPremiumV2PetBanner,
      PlanModuleType.journal => journalPremiumV2PetBanner,
      PlanModuleType.diet => dietPremiumV2PetBanner,
      PlanModuleType.sleep => sleepPremiumV2PetBanner,
    };
  }

  static String premiumHeroScene(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => studyPremiumHeroScene,
      PlanModuleType.fitness => fitnessPremiumHeroScene,
      PlanModuleType.journal => journalPremiumHeroScene,
      PlanModuleType.diet => dietPremiumHeroScene,
      PlanModuleType.sleep => sleepPremiumHeroScene,
    };
  }

  static String premiumV2HeroScene(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => studyPremiumV2HeroScene,
      PlanModuleType.fitness => fitnessPremiumV2HeroScene,
      PlanModuleType.journal => journalPremiumV2HeroScene,
      PlanModuleType.diet => dietPremiumV2HeroScene,
      PlanModuleType.sleep => sleepPremiumV2HeroScene,
    };
  }

  static const premiumFallbacks = <String>[
    studyPremiumPetBanner,
    studyPremiumHeroScene,
    fitnessPremiumPetBanner,
    fitnessPremiumHeroScene,
    journalPremiumPetBanner,
    journalPremiumHeroScene,
    dietPremiumPetBanner,
    dietPremiumHeroScene,
    sleepPremiumPetBanner,
    sleepPremiumHeroScene,
  ];

  static const premiumV2Fallbacks = <String>[
    studyPremiumV2PetBanner,
    studyPremiumV2HeroScene,
    fitnessPremiumV2PetBanner,
    fitnessPremiumV2HeroScene,
    journalPremiumV2PetBanner,
    journalPremiumV2HeroScene,
    dietPremiumV2PetBanner,
    dietPremiumV2HeroScene,
    sleepPremiumV2PetBanner,
    sleepPremiumV2HeroScene,
  ];

  static List<String> heroCaptions(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => const [
        '今天适合先把最重要的一科拿下。',
        '番茄钟准备好了，专注一点点就会看见进步。',
        '学习记录会帮你看见每一次认真。',
        '复盘一下，找到今天最顺的节奏。',
      ],
      PlanModuleType.fitness => const [
        '先热身，再把身体慢慢唤醒。',
        '训练计时已经备好，跟着节奏来。',
        '每一组完成，都是给未来的礼物。',
        '拉伸收尾，让今天的训练更完整。',
      ],
      PlanModuleType.journal => const [
        '写下今天的小确幸，给心情留个位置。',
        '不用写很多，真实一点就很好。',
        '灵感来了就接住它，慢慢写。',
        '今天的你，也值得被认真记录。',
      ],
      PlanModuleType.diet => const [
        '吃饭和喝水都算照顾自己。',
        '补水提醒可以帮你稳稳保持状态。',
        '记录一餐，慢慢看见身体的反馈。',
        '清爽的一天，从一杯水开始。',
      ],
      PlanModuleType.sleep => const [
        '早点收心，给明天留一点精神。',
        '设好入睡提醒，到点就温柔提醒你。',
        '睡前少一点打扰，梦会更轻一点。',
        '今晚慢慢放松，明天再继续发光。',
      ],
    };
  }

  static String actionTitle(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => '开始今日学习',
      PlanModuleType.fitness => '开始今日训练',
      PlanModuleType.journal => '写下今日复盘',
      PlanModuleType.diet => '开启饮水提醒',
      PlanModuleType.sleep => '设置入睡节奏',
    };
  }

  static String actionCaption(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => '把最重要的一段时间，温柔地留给专注。',
      PlanModuleType.fitness => '每一次坚持，都是更好的自己。',
      PlanModuleType.journal => '把今天轻轻放进纸里，留下成长的线索。',
      PlanModuleType.diet => '清爽的一天，从一杯水开始。',
      PlanModuleType.sleep => '早点收心，给明天留一点精神。',
    };
  }

  static String actionButtonLabel(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => '开始专注',
      PlanModuleType.fitness => '开始训练',
      PlanModuleType.journal => '开始写',
      PlanModuleType.diet => '去设置',
      PlanModuleType.sleep => '去设置',
    };
  }

  static const all = <String>[
    ...studyHero,
    studyTimer,
    ...fitnessHero,
    fitnessTimer,
    ...journalHero,
    journalTimer,
    ...dietHero,
    dietTimer,
    ...sleepHero,
    sleepTimer,
    ...premiumV2Fallbacks,
    ...premiumFallbacks,
  ];
}
