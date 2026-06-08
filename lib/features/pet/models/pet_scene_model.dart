/// 宠物展示系统模型
///
/// 定义模块类型、场景状态、装饰元素等数据结构。

import '../utils/pet_assets.dart';

// =============================================================================
// 模块类型
// =============================================================================

/// 宠物所属模块
enum PetModuleType {
  study,
  fitness,
  journal,
  diet,
  sleep,
}

/// 模块扩展
extension PetModuleTypeX on PetModuleType {
  /// 模块显示名称
  String get label {
    switch (this) {
      case PetModuleType.study:
        return '学习';
      case PetModuleType.fitness:
        return '健身';
      case PetModuleType.journal:
        return '日记';
      case PetModuleType.diet:
        return '饮食';
      case PetModuleType.sleep:
        return '睡眠';
    }
  }

  /// 模块背景色 (浅色)
  String get softColorHex {
    switch (this) {
      case PetModuleType.study:
        return '#EFF6FF'; // 浅蓝
      case PetModuleType.fitness:
        return '#ECFDF5'; // 浅绿
      case PetModuleType.journal:
        return '#FFF1F2'; // 浅粉
      case PetModuleType.diet:
        return '#FFFBEB'; // 浅橙
      case PetModuleType.sleep:
        return '#F5F3FF'; // 浅紫
    }
  }

  /// 模块主色
  String get primaryColorHex {
    switch (this) {
      case PetModuleType.study:
        return '#3B82F6'; // 蓝
      case PetModuleType.fitness:
        return '#10B981'; // 绿
      case PetModuleType.journal:
        return '#F472B6'; // 粉
      case PetModuleType.diet:
        return '#F59E0B'; // 橙
      case PetModuleType.sleep:
        return '#8B5CF6'; // 紫
    }
  }

  /// 该模块的待机状态池（不含 done）
  List<PetSceneStateType> get idleStates {
    switch (this) {
      case PetModuleType.study:
        return [
          PetSceneStateType.studyReading,
          PetSceneStateType.studyWriting,
          PetSceneStateType.studyFocus,
        ];
      case PetModuleType.fitness:
        return [
          PetSceneStateType.fitnessLifting,
          PetSceneStateType.fitnessStretch,
          PetSceneStateType.fitnessDrink,
        ];
      case PetModuleType.journal:
        return [
          PetSceneStateType.journalWriting,
          PetSceneStateType.journalThinking,
          PetSceneStateType.journalBook,
        ];
      case PetModuleType.diet:
        return [
          PetSceneStateType.dietEating,
          PetSceneStateType.dietDrink,
          PetSceneStateType.dietPlate,
        ];
      case PetModuleType.sleep:
        return [
          PetSceneStateType.sleepYawn,
          PetSceneStateType.sleepSleeping,
          PetSceneStateType.sleepStretch,
        ];
    }
  }

  /// 该模块的完成状态
  PetSceneStateType get doneState {
    switch (this) {
      case PetModuleType.study:
        return PetSceneStateType.studyDone;
      case PetModuleType.fitness:
        return PetSceneStateType.fitnessDone;
      case PetModuleType.journal:
        return PetSceneStateType.journalDone;
      case PetModuleType.diet:
        return PetSceneStateType.dietDone;
      case PetModuleType.sleep:
        return PetSceneStateType.sleepDone;
    }
  }
}

// =============================================================================
// 场景状态类型
// =============================================================================

/// 宠物场景状态（对应 PNG 图片）
enum PetSceneStateType {
  // 学习
  studyReading,
  studyWriting,
  studyFocus,
  studyDone,

  // 健身
  fitnessLifting,
  fitnessStretch,
  fitnessDrink,
  fitnessDone,

  // 日记
  journalWriting,
  journalThinking,
  journalBook,
  journalDone,

  // 饮食
  dietEating,
  dietDrink,
  dietPlate,
  dietDone,

  // 睡眠
  sleepYawn,
  sleepSleeping,
  sleepStretch,
  sleepDone,

  // 通用（AI 相关）
  thinking,
  report,
  error,
}

/// 状态扩展
extension PetSceneStateTypeX on PetSceneStateType {
  /// 对应的 PNG 资源路径
  String get assetPath {
    switch (this) {
      case PetSceneStateType.studyReading:
        return PetAssets.studyReading;
      case PetSceneStateType.studyWriting:
        return PetAssets.studyWriting;
      case PetSceneStateType.studyFocus:
        return PetAssets.studyFocus;
      case PetSceneStateType.studyDone:
        return PetAssets.studyDone;
      case PetSceneStateType.fitnessLifting:
        return PetAssets.fitnessLifting;
      case PetSceneStateType.fitnessStretch:
        return PetAssets.fitnessStretch;
      case PetSceneStateType.fitnessDrink:
        return PetAssets.fitnessDrink;
      case PetSceneStateType.fitnessDone:
        return PetAssets.fitnessDone;
      case PetSceneStateType.journalWriting:
        return PetAssets.journalWriting;
      case PetSceneStateType.journalThinking:
        return PetAssets.journalThinking;
      case PetSceneStateType.journalBook:
        return PetAssets.journalBook;
      case PetSceneStateType.journalDone:
        return PetAssets.journalDone;
      case PetSceneStateType.dietEating:
        return PetAssets.dietEating;
      case PetSceneStateType.dietDrink:
        return PetAssets.dietDrink;
      case PetSceneStateType.dietPlate:
        return PetAssets.dietPlate;
      case PetSceneStateType.dietDone:
        return PetAssets.dietDone;
      case PetSceneStateType.sleepYawn:
        return PetAssets.sleepYawn;
      case PetSceneStateType.sleepSleeping:
        return PetAssets.sleepSleeping;
      case PetSceneStateType.sleepStretch:
        return PetAssets.sleepStretch;
      case PetSceneStateType.sleepDone:
        return PetAssets.sleepDone;
      case PetSceneStateType.thinking:
        return PetAssets.commonThinking;
      case PetSceneStateType.report:
        return PetAssets.commonReport;
      case PetSceneStateType.error:
        return PetAssets.commonError;
    }
  }

  /// fallback 资源路径（使用现有 pet_idle.png）
  String get fallbackAssetPath => PetAssets.commonFallback;

  /// 所属模块
  PetModuleType get module {
    final name = this.name;
    if (name.startsWith('study')) return PetModuleType.study;
    if (name.startsWith('fitness')) return PetModuleType.fitness;
    if (name.startsWith('journal')) return PetModuleType.journal;
    if (name.startsWith('diet')) return PetModuleType.diet;
    if (name.startsWith('sleep')) return PetModuleType.sleep;
    // thinking / report / error → default study, not really used
    return PetModuleType.study;
  }
}

// =============================================================================
// 装饰元素
// =============================================================================

/// 装饰 emoji 配置
class PetDecoration {
  const PetDecoration({
    required this.primary,
    this.secondary,
    this.tertiary,
  });

  /// 主道具 emoji
  final String primary;

  /// 小装饰 1
  final String? secondary;

  /// 小装饰 2
  final String? tertiary;

  /// 所有装饰
  List<String> get all =>
      [primary, if (secondary != null) secondary!, if (tertiary != null) tertiary!];
}

/// 获取状态对应的装饰
PetDecoration getDecorationForState(PetSceneStateType state) {
  switch (state) {
    // 学习
    case PetSceneStateType.studyReading:
      return const PetDecoration(primary: '📖', secondary: '👓');
    case PetSceneStateType.studyWriting:
      return const PetDecoration(primary: '✏️', secondary: '📝');
    case PetSceneStateType.studyFocus:
      return const PetDecoration(primary: '📚', secondary: '🤓');
    case PetSceneStateType.studyDone:
      return const PetDecoration(primary: '✅', secondary: '🎉');

    // 健身
    case PetSceneStateType.fitnessLifting:
      return const PetDecoration(primary: '🏋️', secondary: '💪');
    case PetSceneStateType.fitnessStretch:
      return const PetDecoration(primary: '🧘', secondary: '🧣');
    case PetSceneStateType.fitnessDrink:
      return const PetDecoration(primary: '🥤', secondary: '💧');
    case PetSceneStateType.fitnessDone:
      return const PetDecoration(primary: '✅', secondary: '🏆');

    // 日记
    case PetSceneStateType.journalWriting:
      return const PetDecoration(primary: '📓', secondary: '🖊️');
    case PetSceneStateType.journalThinking:
      return const PetDecoration(primary: '💭', secondary: '🌸');
    case PetSceneStateType.journalBook:
      return const PetDecoration(primary: '📖', secondary: '🏷️');
    case PetSceneStateType.journalDone:
      return const PetDecoration(primary: '✅', secondary: '💐');

    // 饮食
    case PetSceneStateType.dietEating:
      return const PetDecoration(primary: '🍽️', secondary: '🍎');
    case PetSceneStateType.dietDrink:
      return const PetDecoration(primary: '🥤', secondary: '💧');
    case PetSceneStateType.dietPlate:
      return const PetDecoration(primary: '🥘', secondary: '🍴');
    case PetSceneStateType.dietDone:
      return const PetDecoration(primary: '✅', secondary: '😊');

    // 睡眠
    case PetSceneStateType.sleepYawn:
      return const PetDecoration(primary: '🥱', secondary: '🌙');
    case PetSceneStateType.sleepSleeping:
      return const PetDecoration(primary: '💤', secondary: '⭐');
    case PetSceneStateType.sleepStretch:
      return const PetDecoration(primary: '🛏️', secondary: '☁️');
    case PetSceneStateType.sleepDone:
      return const PetDecoration(primary: '✅', secondary: '🌞');

    // 通用（AI 相关）
    case PetSceneStateType.thinking:
      return const PetDecoration(primary: '🤔', secondary: '💭');
    case PetSceneStateType.report:
      return const PetDecoration(primary: '📊', secondary: '✨');
    case PetSceneStateType.error:
      return const PetDecoration(primary: '😿', secondary: '💔');
  }
}

// =============================================================================
// 场景配置
// =============================================================================

/// 宠物场景配置（状态 + 文案 + 装饰）
class PetSceneConfig {
  const PetSceneConfig({
    required this.state,
    required this.message,
    required this.decoration,
  });

  final PetSceneStateType state;
  final String message;
  final PetDecoration decoration;
}
