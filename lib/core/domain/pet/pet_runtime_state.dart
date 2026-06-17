import 'pet_display_intent.dart';

/// 宠物运行时状态
///
/// 管理主页生活状态、模块待机状态和 activeIntent（临时覆盖）。
/// 如果 activeIntent 存在且未过期，优先显示 activeIntent。
class PetRuntimeState {
  const PetRuntimeState({
    this.lifeIntent,
    this.moduleIntents = const {},
    this.activeIntent,
    this.lastBubbleTime,
    this.recentMessageKeys = const [],
  });

  /// 主页生活状态。
  final PetDisplayIntent? lifeIntent;

  /// 模块待机状态，按模块隔离，避免污染主页和其他模块。
  final Map<String, PetDisplayIntent> moduleIntents;

  /// 临时覆盖（反馈/系统状态）
  final PetDisplayIntent? activeIntent;

  /// 上次气泡显示时间
  final DateTime? lastBubbleTime;

  /// 最近显示的消息 key（防重复）
  final List<String> recentMessageKeys;

  /// 当前应显示的 Intent
  PetDisplayIntent? get effectiveIntent {
    if (activeIntent != null && !activeIntent!.isExpired) {
      return activeIntent;
    }
    return lifeIntent;
  }

  /// 是否有有效的 activeIntent
  bool get hasActiveIntent => activeIntent != null && !activeIntent!.isExpired;

  PetRuntimeState copyWith({
    PetDisplayIntent? lifeIntent,
    Map<String, PetDisplayIntent>? moduleIntents,
    PetDisplayIntent? activeIntent,
    bool clearActiveIntent = false,
    DateTime? lastBubbleTime,
    List<String>? recentMessageKeys,
  }) {
    return PetRuntimeState(
      lifeIntent: lifeIntent ?? this.lifeIntent,
      moduleIntents: moduleIntents ?? this.moduleIntents,
      activeIntent: clearActiveIntent
          ? null
          : activeIntent ?? this.activeIntent,
      lastBubbleTime: lastBubbleTime ?? this.lastBubbleTime,
      recentMessageKeys: recentMessageKeys ?? this.recentMessageKeys,
    );
  }

  /// 清除过期的 activeIntent
  PetRuntimeState clearExpired() {
    if (activeIntent != null && activeIntent!.isExpired) {
      return copyWith(clearActiveIntent: true);
    }
    return this;
  }
}
