import 'package:flutter/services.dart' show rootBundle;

import 'pet_assets.dart';

/// 宠物资源完整性验证工具
///
/// 调用 [validateAll] 检查 PetAssets 中所有路径对应的文件是否存在。
/// 用于调试和 CI。
class PetAssetsValidator {
  PetAssetsValidator._();

  /// 所有需验证的路径（反射不可用，需手动维护）
  static const _allPaths = <String>[
    // Module scene states
    PetAssets.studyReading, PetAssets.studyWriting, PetAssets.studyFocus, PetAssets.studyDone,
    PetAssets.fitnessLifting, PetAssets.fitnessStretch, PetAssets.fitnessDrink, PetAssets.fitnessDone,
    PetAssets.journalWriting, PetAssets.journalThinking, PetAssets.journalBook, PetAssets.journalDone,
    PetAssets.dietEating, PetAssets.dietDrink, PetAssets.dietPlate, PetAssets.dietDone,
    PetAssets.sleepYawn, PetAssets.sleepSleeping, PetAssets.sleepStretch, PetAssets.sleepDone,
    // Module defaults
    PetAssets.moduleDefaultStudy, PetAssets.moduleDefaultFitness, PetAssets.moduleDefaultJournal,
    PetAssets.moduleDefaultDiet, PetAssets.moduleDefaultSleep,
    // Common
    PetAssets.commonHappy, PetAssets.commonIdle, PetAssets.commonThinking, PetAssets.commonReport,
    PetAssets.commonError, PetAssets.commonLoading, PetAssets.commonEmpty, PetAssets.commonWarning,
    PetAssets.commonFallback,
    // Events
    PetAssets.eventLevelUp, PetAssets.eventExpGain, PetAssets.eventStreak7, PetAssets.eventStreak30,
    PetAssets.eventGoalDone, PetAssets.eventTaskDone, PetAssets.eventWeeklyRpt, PetAssets.eventMonthlyRpt,
    PetAssets.eventComeback, PetAssets.eventEncourage,
    // AI
    PetAssets.aiThinking, PetAssets.aiReport, PetAssets.aiPrivacy, PetAssets.aiPointing,
    PetAssets.aiNetworkError, PetAssets.aiKeyMissing, PetAssets.aiJsonError, PetAssets.aiDailySummary,
    // Hero
    PetAssets.heroMorning, PetAssets.heroAfternoon, PetAssets.heroEvening, PetAssets.heroNight,
    // Root fallbacks
    PetAssets.petIdle, PetAssets.petHappy, PetAssets.petPeek, PetAssets.petSleepy,
  ];

  static Future<Map<String, bool>> validateAll() async {
    final results = <String, bool>{};
    for (final path in _allPaths) {
      try {
        await rootBundle.load(path);
        results[path] = true;
      } catch (_) {
        debugPrint('❌ Missing asset: $path');
        results[path] = false;
      }
    }
    return results;
  }

  static int missingCount(Map<String, bool> results) =>
      results.values.where((v) => !v).length;

  static void debugPrint(String message) {
    // ignore: avoid_print
    print(message);
  }
}
