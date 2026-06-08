import '../models/pet_scene_model.dart';

/// 宠物场景解析器
///
/// 根据模块类型和当前数据状态，决定展示哪个宠物 PNG、什么文案、什么装饰。
class PetSceneResolver {
  PetSceneResolver._();

  /// 解析当前场景配置
  ///
  /// [module] 当前模块
  /// [hasRecords] 今日是否有记录
  /// [justCompleted] 是否刚完成一条记录（用于完成反馈）
  static PetSceneConfig resolve({
    required PetModuleType module,
    required bool hasRecords,
    bool justCompleted = false,
  }) {
    // 刚完成记录 → 显示 done 状态
    if (justCompleted) {
      return PetSceneConfig(
        state: module.doneState,
        message: _getDoneMessage(module),
        decoration: getDecorationForState(module.doneState),
      );
    }

    // 无记录 → 显示鼓励开始的文案
    if (!hasRecords) {
      final idleStates = module.idleStates;
      final state = idleStates[DateTime.now().millisecond % idleStates.length];
      return PetSceneConfig(
        state: state,
        message: _getWelcomeMessage(module),
        decoration: getDecorationForState(state),
      );
    }

    // 有记录 → 显示继续加油的文案
    final idleStates = module.idleStates;
    final state = idleStates[(DateTime.now().second ~/ 20) % idleStates.length];
    return PetSceneConfig(
      state: state,
      message: _getEncourageMessage(module),
      decoration: getDecorationForState(state),
    );
  }

  /// 随机切换待机状态（同模块内）
  static PetSceneStateType randomIdleState(PetModuleType module) {
    final states = module.idleStates;
    return states[DateTime.now().millisecondsSinceEpoch % states.length];
  }

  // ── 文案生成 ──

  static String _getWelcomeMessage(PetModuleType module) {
    switch (module) {
      case PetModuleType.study:
        return '今天先开始一点点吧～';
      case PetModuleType.fitness:
        return '动一动身体会更棒哦～';
      case PetModuleType.journal:
        return '记录一下今天的成长吧！';
      case PetModuleType.diet:
        return '记得记录今天的饮食哦～';
      case PetModuleType.sleep:
        return '好好休息很重要呢～';
      case PetModuleType.focus:
        return '准备好了吗？开始专注吧～';
    }
  }

  static String _getEncourageMessage(PetModuleType module) {
    switch (module) {
      case PetModuleType.study:
        return '已经努力了一会儿啦，继续加油～';
      case PetModuleType.fitness:
        return '训练得很认真呢，真棒！';
      case PetModuleType.journal:
        return '坚持记录的习惯真好～';
      case PetModuleType.diet:
        return '饮食记录得很认真呢！';
      case PetModuleType.sleep:
        return '睡眠记录很详细，继续保持～';
      case PetModuleType.focus:
        return '专注中的你很棒，继续加油～';
    }
  }

  static String _getDoneMessage(PetModuleType module) {
    switch (module) {
      case PetModuleType.study:
        return '学习记录完成啦！';
      case PetModuleType.fitness:
        return '训练完成，辛苦啦！';
      case PetModuleType.journal:
        return '日记写好啦，真棒！';
      case PetModuleType.diet:
        return '饮食记录完成！';
      case PetModuleType.sleep:
        return '睡眠记录完成，晚安～';
      case PetModuleType.focus:
        return '专注完成！休息一下吧～';
    }
  }

  /// 获取页面进入欢迎文案
  static String getWelcomeBubble(PetModuleType module) {
    switch (module) {
      case PetModuleType.study:
        return '嗨～今天也要好好学习哦！';
      case PetModuleType.fitness:
        return '嗨～一起运动吧！';
      case PetModuleType.journal:
        return '嗨～来写点什么吧！';
      case PetModuleType.diet:
        return '嗨～记得好好吃饭哦！';
      case PetModuleType.sleep:
        return '嗨～今晚早点休息吧！';
      case PetModuleType.focus:
        return '嗨～一起专注吧！';
    }
  }
}
