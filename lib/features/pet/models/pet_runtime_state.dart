import 'pet_display_intent.dart';

/// 宠物运行时状态
///
/// 管理 baseIntent（默认展示）和 activeIntent（临时覆盖）。
/// 如果 activeIntent 存在且未过期，显示 activeIntent。
/// 否则显示 baseIntent。
class PetRuntimeState {
  const PetRuntimeState({
    this.baseIntent,
    this.activeIntent,
    this.lastBubbleTime,
    this.recentMessageKeys = const [],
  });

  /// 默认展示（LifeSession 或模块待机）
  final PetDisplayIntent? baseIntent;

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
    return baseIntent;
  }

  /// 是否有有效的 activeIntent
  bool get hasActiveIntent =>
      activeIntent != null && !activeIntent!.isExpired;

  PetRuntimeState copyWith({
    PetDisplayIntent? baseIntent,
    PetDisplayIntent? activeIntent,
    DateTime? lastBubbleTime,
    List<String>? recentMessageKeys,
  }) {
    return PetRuntimeState(
      baseIntent: baseIntent ?? this.baseIntent,
      activeIntent: activeIntent ?? this.activeIntent,
      lastBubbleTime: lastBubbleTime ?? this.lastBubbleTime,
      recentMessageKeys: recentMessageKeys ?? this.recentMessageKeys,
    );
  }

  /// 清除过期的 activeIntent
  PetRuntimeState clearExpired() {
    if (activeIntent != null && activeIntent!.isExpired) {
      return PetRuntimeState(
        baseIntent: baseIntent,
        activeIntent: null,
        lastBubbleTime: lastBubbleTime,
        recentMessageKeys: recentMessageKeys,
      );
    }
    return this;
  }
}
