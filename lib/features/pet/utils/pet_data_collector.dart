import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/dashboard_provider.dart';

/// 宠物数据收集器
///
/// 从本地数据库收集用户数据，用于生成 AI Prompt。
class PetDataCollector {
  PetDataCollector(this._container);

  final ProviderContainer _container;

  /// 收集学习数据（最近 7 天）
  Future<Map<String, dynamic>> collectStudyData() async {
    final repo = _container.read(studyRepositoryProvider);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final records = await repo.getStudyRecordsByRange(start, now);

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    final studyDays = records
        .map((r) {
          final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
          return '${dt.year}-${dt.month}-${dt.day}';
        })
        .toSet()
        .length;

    final subjects = <String, int>{};
    for (final r in records) {
      final subject = r.subject ?? '未分类';
      subjects[subject] = (subjects[subject] ?? 0) + r.durationMinutes;
    }

    final focusLevels = records
        .where((r) => r.focusLevel != null)
        .map((r) => r.focusLevel!)
        .toList();
    final avgFocus = focusLevels.isEmpty
        ? 0.0
        : focusLevels.reduce((a, b) => a + b) / focusLevels.length;

    final problems = records
        .where((r) => r.problem != null && r.problem!.isNotEmpty)
        .map((r) => r.problem!)
        .toList();

    return {
      '记录条数': records.length,
      '总学习时长': '$totalMinutes 分钟',
      '学习天数': studyDays,
      '科目分布': subjects.entries.map((e) => '${e.key}: ${e.value}分钟').join(', '),
      '平均专注度': '${avgFocus.toStringAsFixed(1)}/5',
      '遗留问题': problems.isEmpty ? '无' : problems.join('; '),
    };
  }

  /// 收集健身数据（最近 7 天）
  Future<Map<String, dynamic>> collectFitnessData() async {
    final repo = _container.read(fitnessRepositoryProvider);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final records = await repo.getFitnessRecordsByRange(start, now);

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    final totalCalories = (totalMinutes * 7.5).toInt();
    final fitnessDays = records
        .map((r) {
          final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
          return '${dt.year}-${dt.month}-${dt.day}';
        })
        .toSet()
        .length;

    final bodyParts = <String, int>{};
    for (final r in records) {
      bodyParts[r.bodyPart] = (bodyParts[r.bodyPart] ?? 0) + 1;
    }

    final intensities = records
        .where((r) => r.intensityLevel != null)
        .map((r) => r.intensityLevel!)
        .toList();
    final avgIntensity = intensities.isEmpty
        ? 0.0
        : intensities.reduce((a, b) => a + b) / intensities.length;

    return {
      '记录条数': records.length,
      '总训练时长': '$totalMinutes 分钟',
      '训练天数': fitnessDays,
      '估算消耗': '$totalCalories kcal',
      '部位分布': bodyParts.entries.map((e) => '${e.key}: ${e.value}次').join(', '),
      '平均强度': '${avgIntensity.toStringAsFixed(1)}/5',
    };
  }

  /// 收集饮食数据（最近 7 天）
  Future<Map<String, dynamic>> collectDietData() async {
    final repo = _container.read(dietRepositoryProvider);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final records = await repo.getDietRecordsByRange(start, now);

    final totalCalories = records.fold<int>(0, (s, r) {
      switch (r.calorieLevel) {
        case 'low':
          return s + 300;
        case 'high':
          return s + 800;
        default:
          return s + 500;
      }
    });

    final healthScores = records.map((r) => r.healthScore).toList();
    final avgScore = healthScores.isEmpty
        ? 0.0
        : healthScores.reduce((a, b) => a + b) / healthScores.length;

    final mealTypes = <String, int>{};
    for (final r in records) {
      mealTypes[r.mealType] = (mealTypes[r.mealType] ?? 0) + 1;
    }

    final recordDays = records.map((r) => r.mealDate).toSet().length;

    return {
      '记录条数': records.length,
      '记录天数': recordDays,
      '估算总卡路里': '$totalCalories kcal',
      '平均健康评分': '${avgScore.toStringAsFixed(1)}/5',
      '餐次分布': mealTypes.entries.map((e) => '${e.key}: ${e.value}次').join(', '),
    };
  }

  /// 收集睡眠数据（最近 7 天）
  Future<Map<String, dynamic>> collectSleepData() async {
    final repo = _container.read(sleepRepositoryProvider);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final records = await repo.getSleepRecordsByRange(start, now);

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    final avgDuration = records.isEmpty ? 0.0 : totalMinutes / records.length;

    final qualities = records.map((r) => r.qualityLevel).toList();
    final avgQuality = qualities.isEmpty
        ? 0.0
        : qualities.reduce((a, b) => a + b) / qualities.length;

    final fallAsleepTimes = records.map((r) => r.fallAsleepMinutes).toList();
    final avgFallAsleep = fallAsleepTimes.isEmpty
        ? 0.0
        : fallAsleepTimes.reduce((a, b) => a + b) / fallAsleepTimes.length;

    final wakeCounts = records.map((r) => r.wakeCount).toList();
    final avgWakeCount = wakeCounts.isEmpty
        ? 0.0
        : wakeCounts.reduce((a, b) => a + b) / wakeCounts.length;

    return {
      '记录天数': records.length,
      '平均睡眠时长': '${(avgDuration / 60).toStringAsFixed(1)} 小时',
      '平均睡眠质量': '${avgQuality.toStringAsFixed(1)}/5',
      '平均入睡时间': '${avgFallAsleep.toStringAsFixed(0)} 分钟',
      '平均夜醒次数': '${avgWakeCount.toStringAsFixed(1)} 次',
    };
  }

  /// 收集周报数据（最近 7 天全部数据）
  Future<Map<String, dynamic>> collectWeeklyReportData() async {
    final study = await collectStudyData();
    final fitness = await collectFitnessData();
    final diet = await collectDietData();
    final sleep = await collectSleepData();

    return {'学习': study, '健身': fitness, '饮食': diet, '睡眠': sleep};
  }

  /// 收集月报数据（最近 30 天全部数据）
  Future<Map<String, dynamic>> collectMonthlyReportData() async {
    final repo = _container.read(studyRepositoryProvider);
    final fitnessRepo = _container.read(fitnessRepositoryProvider);
    final dietRepo = _container.read(dietRepositoryProvider);
    final sleepRepo = _container.read(sleepRepositoryProvider);

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));

    final studyRecords = await repo.getStudyRecordsByRange(start, now);
    final fitnessRecords = await fitnessRepo.getFitnessRecordsByRange(
      start,
      now,
    );
    final dietRecords = await dietRepo.getDietRecordsByRange(start, now);
    final sleepRecords = await sleepRepo.getSleepRecordsByRange(start, now);

    return {
      '学习记录数': studyRecords.length,
      '学习总时长':
          '${studyRecords.fold<int>(0, (s, r) => s + r.durationMinutes)} 分钟',
      '健身记录数': fitnessRecords.length,
      '健身总时长':
          '${fitnessRecords.fold<int>(0, (s, r) => s + r.durationMinutes)} 分钟',
      '饮食记录数': dietRecords.length,
      '睡眠记录数': sleepRecords.length,
      '平均睡眠质量': sleepRecords.isEmpty
          ? '无数据'
          : '${(sleepRecords.map((r) => r.qualityLevel).reduce((a, b) => a + b) / sleepRecords.length).toStringAsFixed(1)}/5',
    };
  }
}
