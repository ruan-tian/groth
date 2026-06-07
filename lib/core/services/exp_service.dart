import 'dart:math';

/// 经验值计算服务
///
/// 纯计算逻辑，无构造函数依赖。
/// 负责学习 / 健身 / 日记的经验值计算以及等级系统。
class ExpService {
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
    final base = durationMinutes ~/ 10;
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
    final base = durationMinutes ~/ 10;
    final intensityBonus = intensityLevel * 3;
    final exerciseBonus = exerciseCount * 2;
    final completeBonus = hasFeeling ? 5 : 0;
    return base + intensityBonus + exerciseBonus + completeBonus;
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
  // 等级系统
  // ---------------------------------------------------------------------------

  /// 根据总经验值计算当前等级。
  ///
  /// 公式：`floor(sqrt(totalExp / 100)) + 1`
  int calculateLevel(int totalExp) {
    return (sqrt(totalExp / 100)).floor() + 1;
  }

  /// 获取升到下一级所需的总经验值。
  ///
  /// 公式：`(currentLevel * currentLevel) * 100`
  int getExpForNextLevel(int currentLevel) {
    return currentLevel * currentLevel * 100;
  }

  /// 获取当前等级内的经验值进度。
  ///
  /// 返回值为距离当前等级起点的经验值（即已在本级累积的经验）。
  int getExpProgress(int totalExp, int currentLevel) {
    final currentLevelStart = (currentLevel - 1) * (currentLevel - 1) * 100;
    return totalExp - currentLevelStart;
  }
}
