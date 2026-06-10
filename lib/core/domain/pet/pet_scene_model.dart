/// 宠物展示系统模型
///
/// 定义模块类型、场景状态、装饰元素等数据结构。

library;

import '../../constants/pet_assets.dart';

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
  focus,
  music,
  accounting,
}

class PetModuleDefinition {
  const PetModuleDefinition({
    required this.type,
    required this.label,
    required this.softColorHex,
    required this.primaryColorHex,
    required this.defaultImagePath,
    required this.idleStates,
    required this.doneState,
    required this.welcomeMessage,
    required this.encourageMessage,
    required this.doneMessage,
    required this.welcomeBubble,
  });

  final PetModuleType type;
  final String label;
  final String softColorHex;
  final String primaryColorHex;
  final String defaultImagePath;
  final List<PetSceneStateType> idleStates;
  final PetSceneStateType doneState;
  final String welcomeMessage;
  final String encourageMessage;
  final String doneMessage;
  final String welcomeBubble;

  List<String> get ambientMessages => [welcomeMessage, encourageMessage];
}

class PetModuleDefinitions {
  PetModuleDefinitions._();

  static const byType = <PetModuleType, PetModuleDefinition>{
    PetModuleType.study: PetModuleDefinition(
      type: PetModuleType.study,
      label: '学习',
      softColorHex: '#EFF6FF',
      primaryColorHex: '#3B82F6',
      defaultImagePath: PetAssets.moduleDefaultStudy,
      idleStates: [
        PetSceneStateType.studyReading,
        PetSceneStateType.studyWriting,
        PetSceneStateType.studyFocus,
      ],
      doneState: PetSceneStateType.studyDone,
      welcomeMessage: '今天先开始一点点吧～',
      encourageMessage: '已经努力了一会儿啦，继续加油～',
      doneMessage: '学习记录完成啦！',
      welcomeBubble: '嗨～今天也要好好学习哦！',
    ),
    PetModuleType.fitness: PetModuleDefinition(
      type: PetModuleType.fitness,
      label: '健身',
      softColorHex: '#ECFDF5',
      primaryColorHex: '#10B981',
      defaultImagePath: PetAssets.moduleDefaultFitness,
      idleStates: [
        PetSceneStateType.fitnessLifting,
        PetSceneStateType.fitnessStretch,
        PetSceneStateType.fitnessDrink,
      ],
      doneState: PetSceneStateType.fitnessDone,
      welcomeMessage: '动一动身体会更棒哦～',
      encourageMessage: '训练得很认真呢，真棒！',
      doneMessage: '训练完成，辛苦啦！',
      welcomeBubble: '嗨～一起运动吧！',
    ),
    PetModuleType.journal: PetModuleDefinition(
      type: PetModuleType.journal,
      label: '日记',
      softColorHex: '#FFF1F2',
      primaryColorHex: '#F472B6',
      defaultImagePath: PetAssets.moduleDefaultJournal,
      idleStates: [
        PetSceneStateType.journalWriting,
        PetSceneStateType.journalThinking,
        PetSceneStateType.journalBook,
      ],
      doneState: PetSceneStateType.journalDone,
      welcomeMessage: '记录一下今天的成长吧！',
      encourageMessage: '坚持记录的习惯真好～',
      doneMessage: '日记写好啦，真棒！',
      welcomeBubble: '嗨～来写点什么吧！',
    ),
    PetModuleType.diet: PetModuleDefinition(
      type: PetModuleType.diet,
      label: '饮食',
      softColorHex: '#FFFBEB',
      primaryColorHex: '#F59E0B',
      defaultImagePath: PetAssets.moduleDefaultDiet,
      idleStates: [
        PetSceneStateType.dietEating,
        PetSceneStateType.dietDrink,
        PetSceneStateType.dietPlate,
      ],
      doneState: PetSceneStateType.dietDone,
      welcomeMessage: '记得记录今天的饮食哦～',
      encourageMessage: '饮食记录得很认真呢！',
      doneMessage: '饮食记录完成！',
      welcomeBubble: '嗨～记得好好吃饭哦！',
    ),
    PetModuleType.sleep: PetModuleDefinition(
      type: PetModuleType.sleep,
      label: '睡眠',
      softColorHex: '#F5F3FF',
      primaryColorHex: '#8B5CF6',
      defaultImagePath: PetAssets.moduleDefaultSleep,
      idleStates: [
        PetSceneStateType.sleepYawn,
        PetSceneStateType.sleepSleeping,
        PetSceneStateType.sleepStretch,
      ],
      doneState: PetSceneStateType.sleepDone,
      welcomeMessage: '好好休息很重要呢～',
      encourageMessage: '睡眠记录很详细，继续保持～',
      doneMessage: '睡眠记录完成，晚安～',
      welcomeBubble: '嗨～今晚早点休息吧！',
    ),
    PetModuleType.focus: PetModuleDefinition(
      type: PetModuleType.focus,
      label: '专注',
      softColorHex: '#F0FDF4',
      primaryColorHex: '#059669',
      defaultImagePath: PetAssets.moduleDefaultFocus,
      idleStates: [
        PetSceneStateType.focusReading,
        PetSceneStateType.focusWriting,
        PetSceneStateType.focusThinking,
      ],
      doneState: PetSceneStateType.focusDone,
      welcomeMessage: '准备好了吗？开始专注吧～',
      encourageMessage: '专注中的你很棒，继续加油～',
      doneMessage: '专注完成！休息一下吧～',
      welcomeBubble: '嗨～一起专注吧！',
    ),
    PetModuleType.music: PetModuleDefinition(
      type: PetModuleType.music,
      label: '音乐',
      softColorHex: '#F0F9FF',
      primaryColorHex: '#0EA5E9',
      defaultImagePath: PetAssets.moduleDefaultMusic,
      idleStates: [PetSceneStateType.musicIdle],
      doneState: PetSceneStateType.musicDone,
      welcomeMessage: '放点喜欢的声音，慢慢进入状态～',
      encourageMessage: '这段旋律正在陪你稳定下来～',
      doneMessage: '音乐陪伴完成啦～',
      welcomeBubble: '嗨～要听点音乐吗？',
    ),
    PetModuleType.accounting: PetModuleDefinition(
      type: PetModuleType.accounting,
      label: '记账',
      softColorHex: '#F7FEE7',
      primaryColorHex: '#65A30D',
      defaultImagePath: PetAssets.moduleDefaultAccounting,
      idleStates: [PetSceneStateType.accountingIdle],
      doneState: PetSceneStateType.accountingDone,
      welcomeMessage: '记一笔小账，生活会更清楚～',
      encourageMessage: '收支记录得越稳，心里越有底～',
      doneMessage: '这笔账记好啦～',
      welcomeBubble: '嗨～要记一笔吗？',
    ),
  };

  static PetModuleDefinition of(PetModuleType type) => byType[type]!;

  static PetModuleDefinition? maybeByName(String? name) {
    if (name == null) return null;
    for (final entry in byType.entries) {
      if (entry.key.name == name) return entry.value;
    }
    return null;
  }
}

/// 模块扩展
extension PetModuleTypeX on PetModuleType {
  PetModuleDefinition get definition => PetModuleDefinitions.of(this);

  /// 模块显示名称
  String get label => definition.label;

  /// 模块背景色 (浅色)
  String get softColorHex => definition.softColorHex;

  /// 模块主色
  String get primaryColorHex => definition.primaryColorHex;

  /// 该模块的待机状态池（不含 done）
  List<PetSceneStateType> get idleStates => definition.idleStates;

  /// 该模块的完成状态
  PetSceneStateType get doneState => definition.doneState;
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

  // 专注
  focusReading,
  focusWriting,
  focusThinking,
  focusRest,
  focusDone,

  // 音乐（预留接口）
  musicIdle,
  musicDone,

  // 记账（预留接口）
  accountingIdle,
  accountingDone,

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
      case PetSceneStateType.focusReading:
        return PetAssets.focusReading;
      case PetSceneStateType.focusWriting:
        return PetAssets.focusWriting;
      case PetSceneStateType.focusThinking:
        return PetAssets.focusThinking;
      case PetSceneStateType.focusRest:
        return PetAssets.focusRest;
      case PetSceneStateType.focusDone:
        return PetAssets.focusDone;
      case PetSceneStateType.musicIdle:
      case PetSceneStateType.musicDone:
        return PetAssets.moduleDefaultMusic;
      case PetSceneStateType.accountingIdle:
      case PetSceneStateType.accountingDone:
        return PetAssets.moduleDefaultAccounting;
      case PetSceneStateType.thinking:
        return PetAssets.commonThinking;
      case PetSceneStateType.report:
        return PetAssets.commonReport;
      case PetSceneStateType.error:
        return PetAssets.commonError;
    }
  }

  /// 完整底图路径（日记陪伴卡轮播用，其他模块 fallback 到 assetPath）
  String get bannerPath {
    switch (this) {
      case PetSceneStateType.journalWriting:
        return PetAssets.journalBannerWriting;
      case PetSceneStateType.journalThinking:
        return PetAssets.journalBannerThinking;
      case PetSceneStateType.journalBook:
        return PetAssets.journalBannerReading;
      case PetSceneStateType.journalDone:
        return PetAssets.journalBannerDone;
      default:
        return assetPath;
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
    if (name.startsWith('focus')) return PetModuleType.focus;
    if (name.startsWith('music')) return PetModuleType.music;
    if (name.startsWith('accounting')) return PetModuleType.accounting;
    // thinking / report / error → default study, not really used
    return PetModuleType.study;
  }
}

// =============================================================================
// 装饰元素
// =============================================================================

/// 装饰 emoji 配置
class PetDecoration {
  const PetDecoration({required this.primary, this.secondary, this.tertiary});

  /// 主道具 emoji
  final String primary;

  /// 小装饰 1
  final String? secondary;

  /// 小装饰 2
  final String? tertiary;

  /// 所有装饰
  List<String> get all => [primary, ?secondary, ?tertiary];
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

    // 专注
    case PetSceneStateType.focusReading:
      return const PetDecoration(primary: '📖', secondary: '🧠');
    case PetSceneStateType.focusWriting:
      return const PetDecoration(primary: '✏️', secondary: '🔥');
    case PetSceneStateType.focusThinking:
      return const PetDecoration(primary: '💭', secondary: '🎯');
    case PetSceneStateType.focusRest:
      return const PetDecoration(primary: '☕', secondary: '🌿');
    case PetSceneStateType.focusDone:
      return const PetDecoration(primary: '✅', secondary: '🏆');

    // 音乐
    case PetSceneStateType.musicIdle:
      return const PetDecoration(primary: '🎵', secondary: '🎧');
    case PetSceneStateType.musicDone:
      return const PetDecoration(primary: '✅', secondary: '🎶');

    // 记账
    case PetSceneStateType.accountingIdle:
      return const PetDecoration(primary: '🧾', secondary: '💰');
    case PetSceneStateType.accountingDone:
      return const PetDecoration(primary: '✅', secondary: '📒');

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
