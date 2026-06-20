import 'dart:math';

/// 经验值计算服务。
///
/// 纯计算逻辑，无构造函数依赖。人物等级和宠物等级都从同一份
/// GrowthExpLogs 总经验派生，宠物不再拥有独立经验曲线。
class ExpService {
  /// 每级经验系数（用于等级计算公式）
  static const int expPerLevelUnit = 5;

  /// 每分钟基础经验
  static const int minutesPerBaseExp = 10;

  // ---------------------------------------------------------------------------
  // 学习经验值
  // ---------------------------------------------------------------------------

  /// 计算单次学习获得的经验值。
  ///
  /// - [durationMinutes] 学习时长（分钟）
  /// - [focusLevel] 专注度 0-5，默认 0
  /// - [difficultyLevel] 难度 0-5，默认 0
  /// - [hasReview] 是否有复习，默认 false
  int calculateStudyExp({
    required int durationMinutes,
    int focusLevel = 0,
    int difficultyLevel = 0,
    bool hasReview = false,
  }) {
    final base = durationMinutes ~/ minutesPerBaseExp;
    final focusBonus = focusLevel * 2;
    final difficultyBonus = difficultyLevel * 2;
    final reviewBonus = hasReview ? 5 : 0;
    return base + focusBonus + difficultyBonus + reviewBonus;
  }

  // ---------------------------------------------------------------------------
  // 健身经验值
  // ---------------------------------------------------------------------------

  /// 计算单次健身获得的经验值。
  ///
  /// - [durationMinutes] 训练时长（分钟）
  /// - [intensityLevel] 强度 0-5，默认 0
  /// - [exerciseCount] 动作数量，默认 0
  /// - [hasFeeling] 是否记录训练感受，默认 false
  int calculateFitnessExp({
    required int durationMinutes,
    int intensityLevel = 0,
    int exerciseCount = 0,
    bool hasFeeling = false,
  }) {
    final base = durationMinutes ~/ minutesPerBaseExp;
    final intensityBonus = intensityLevel * 3;
    final exerciseBonus = exerciseCount * 2;
    final completeBonus = hasFeeling ? 5 : 0;
    return base + intensityBonus + exerciseBonus + completeBonus;
  }

  // ---------------------------------------------------------------------------
  // 专注经验值
  // ---------------------------------------------------------------------------

  /// 计算单轮专注完成获得的经验值。
  ///
  /// 专注会同时生成 FocusSession 与一条简单学习记录，但成长经验只写入
  /// GrowthExpLogs 一次，来源为 `focus`。
  int calculateFocusExp({required int durationMinutes, bool completed = true}) {
    if (!completed) return 0;
    return durationMinutes ~/ minutesPerBaseExp + 5;
  }

  // ---------------------------------------------------------------------------
  // 日记经验值
  // ---------------------------------------------------------------------------

  /// 计算单篇日记获得的经验值。
  ///
  /// 每日上限 20 EXP。
  /// - [wordCount] 字数
  int calculateJournalExp({required int wordCount}) {
    const base = 5;
    final wordBonus = wordCount ~/ 100;
    return min(base + wordBonus, 20);
  }

  // ---------------------------------------------------------------------------
  // 健康类经验值
  // ---------------------------------------------------------------------------

  /// 计算单次饮食记录的经验值。
  int calculateDietExp({
    required bool hasCompleteMeals,
    bool hasReasonableTarget = false,
  }) {
    const base = 4;
    final mealBonus = hasCompleteMeals ? 4 : 0;
    final targetBonus = hasReasonableTarget ? 2 : 0;
    return min(base + mealBonus + targetBonus, 12);
  }

  /// 计算每日饮水经验值。
  int calculateWaterExp({
    required int drinkCount,
    required bool reachedGoal,
    bool completedReminders = false,
  }) {
    if (drinkCount <= 0) return 0;
    final drinkBonus = drinkCount;
    final goalBonus = reachedGoal ? 5 : 0;
    final reminderBonus = completedReminders ? 2 : 0;
    return min(drinkBonus + goalBonus + reminderBonus, 10);
  }

  /// 计算单次睡眠记录的经验值。
  int calculateSleepExp({
    required int durationMinutes,
    int qualityLevel = 0,
    int targetMinutes = 480,
    bool isRegularSchedule = false,
  }) {
    if (durationMinutes <= 0) return 0;
    const recordBonus = 5;
    final durationBonus = (durationMinutes - targetMinutes).abs() <= 60 ? 4 : 0;
    final qualityBonus = qualityLevel >= 4 ? 3 : 0;
    final regularBonus = isRegularSchedule ? 2 : 0;
    return min(recordBonus + durationBonus + qualityBonus + regularBonus, 14);
  }

  // ---------------------------------------------------------------------------
  // 等级系统
  // ---------------------------------------------------------------------------

  /// 根据总经验值计算当前等级。
  ///
  /// 公式：`floor(sqrt(totalExp / 5)) + 1`
  int calculateLevel(int totalExp) {
    return (sqrt(totalExp / expPerLevelUnit)).floor() + 1;
  }

  /// 获取当前等级起点所需的总经验值。
  int getExpForLevelStart(int currentLevel) {
    if (currentLevel <= 1) return 0;
    return (currentLevel - 1) * (currentLevel - 1) * expPerLevelUnit;
  }

  /// 获取升到下一级所需的总经验值。
  ///
  /// 公式：`(currentLevel * currentLevel) * 100`
  int getExpForNextLevel(int currentLevel) {
    return currentLevel * currentLevel * expPerLevelUnit;
  }

  /// 获取当前等级内的经验值进度。
  ///
  /// 返回值为距离当前等级起点的经验值（即已在本级累积的经验）。
  /// 不会返回负值（防止数据异常时 UI 显示负数）。
  int getExpProgress(int totalExp, int currentLevel) {
    final currentLevelStart = getExpForLevelStart(currentLevel);
    return max(0, totalExp - currentLevelStart);
  }

  /// 统一的人物/宠物等级进度投影。
  GrowthLevelProgress calculateLevelProgress(int totalExp) {
    final level = calculateLevel(totalExp);
    final levelStartExp = getExpForLevelStart(level);
    final nextLevelExp = getExpForNextLevel(level);
    final levelRange = max(1, nextLevelExp - levelStartExp);
    final expProgress = (totalExp - levelStartExp).clamp(0, levelRange).toInt();
    final expRemaining = max(0, nextLevelExp - totalExp);

    return GrowthLevelProgress(
      totalExp: totalExp,
      level: level,
      levelStartExp: levelStartExp,
      nextLevelExp: nextLevelExp,
      levelRange: levelRange,
      expProgress: expProgress,
      expRemaining: expRemaining,
    );
  }
}

class GrowthLevelProgress {
  const GrowthLevelProgress({
    required this.totalExp,
    required this.level,
    required this.levelStartExp,
    required this.nextLevelExp,
    required this.levelRange,
    required this.expProgress,
    required this.expRemaining,
  });

  final int totalExp;
  final int level;
  final int levelStartExp;
  final int nextLevelExp;
  final int levelRange;
  final int expProgress;
  final int expRemaining;

  double get progressRatio => (expProgress / levelRange).clamp(0.0, 1.0);
}
