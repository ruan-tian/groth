import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'repository_providers.dart';

// =============================================================================
// 饮食记录 Provider
// =============================================================================

/// 指定日期的饮食记录
final dietRecordsByDateProvider =
    FutureProvider.family<List<DietRecord>, DateTime>((ref, date) async {
      final repo = ref.watch(dietRepositoryProvider);
      return repo.getDietRecordsByDate(date);
    });

/// 今日饮食记录
final todayDietRecordsProvider = FutureProvider<List<DietRecord>>((ref) {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getTodayDietRecords();
});

/// 今日饮食次数
final todayDietCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getTodayDietCount();
});

/// 今日平均健康评分
final todayAvgHealthScoreProvider = FutureProvider<double?>((ref) {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getAvgHealthScoreByDate(DateTime.now());
});

/// 最近 [limit] 条饮食记录
final recentDietRecordsProvider = FutureProvider.family<List<DietRecord>, int>((
  ref,
  limit,
) async {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getRecentDietRecords(limit: limit);
});

/// 最近7天每日平均健康评分
final weeklyHealthScoreProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getDailyAvgHealthScore(7);
});

/// 最近30天每日平均健康评分
final monthlyHealthScoreProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getDailyAvgHealthScore(30);
});

/// 根据 ID 获取单条饮食记录
final dietRecordByIdProvider = FutureProvider.family<DietRecord?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(dietRepositoryProvider);
  return repo.getDietRecordById(id);
});

/// 最近 [days] 天每日卡路里总量 (kcal)
///
/// 返回 Map<日期字符串 'YYYY-MM-DD', 当日总卡路里>。
/// 卡路里根据 calorieLevel 估算：low=300, normal=500, high=800。
final dailyCalorieTotalsProvider = FutureProvider.family<Map<String, int>, int>(
  (ref, days) async {
    final repo = ref.watch(dietRepositoryProvider);
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final records = await repo.getDietRecordsByRange(start, now);

    final map = <String, int>{};
    for (final r in records) {
      int cal;
      switch (r.calorieLevel) {
        case 'low':
          cal = 300;
          break;
        case 'high':
          cal = 800;
          break;
        default:
          cal = 500;
      }
      map[r.mealDate] = (map[r.mealDate] ?? 0) + cal;
    }
    return map;
  },
);

/// 最近 [days] 天每日卡路里 + 饮水量汇总
///
/// 返回 `(calorieMap, waterMap)`，key 均为 'YYYY-MM-DD'。
final dailyCalorieWaterProvider =
    FutureProvider.family<DailyNutritionData, int>((ref, days) async {
      final repo = ref.watch(dietRepositoryProvider);
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1));
      final records = await repo.getDietRecordsByRange(start, now);

      final calorieMap = <String, int>{};
      for (final r in records) {
        int cal;
        switch (r.calorieLevel) {
          case 'low':
            cal = 300;
            break;
          case 'high':
            cal = 800;
            break;
          default:
            cal = 500;
        }
        calorieMap[r.mealDate] = (calorieMap[r.mealDate] ?? 0) + cal;
      }

      // 从 settings 读取饮水量数据
      final waterMap = <String, int>{};
      final settingRepo = ref.watch(settingRepositoryProvider);
      final waterValue = await settingRepo.getSetting('daily_water_intake');
      if (waterValue != null) {
        try {
          final map = (jsonDecode(waterValue) as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int),
          );
          waterMap.addAll(map);
        } catch (_) {
          // 解析失败则使用空值
        }
      }

      return DailyNutritionData(calorieMap: calorieMap, waterMap: waterMap);
    });

/// 卡路里 + 饮水量数据容器
class DailyNutritionData {
  const DailyNutritionData({required this.calorieMap, required this.waterMap});

  final Map<String, int> calorieMap;
  final Map<String, int> waterMap;
}
