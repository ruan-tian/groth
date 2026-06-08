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
  ];
}
