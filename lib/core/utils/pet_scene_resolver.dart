import '../domain/pet/pet_scene_model.dart';

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
    return module.definition.welcomeMessage;
  }

  static String _getEncourageMessage(PetModuleType module) {
    return module.definition.encourageMessage;
  }

  static String _getDoneMessage(PetModuleType module) {
    return module.definition.doneMessage;
  }

  /// 获取页面进入欢迎文案
  static String getWelcomeBubble(PetModuleType module) {
    return module.definition.welcomeBubble;
  }
}
