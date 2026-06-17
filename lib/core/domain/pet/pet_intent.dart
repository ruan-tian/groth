/// 宠物 Intent 作用域
///
/// 序列化 key 映射: scope → index, replacePolicy → index
enum PetIntentScope { global, module, dashboard, petCenter }

/// Intent 替换策略
enum PetIntentReplacePolicy {
  stack, // 可入栈叠加（升级、连续打卡）
  replaceSameType, // 替换同类型（学习完成重复触发）
  replaceScope, // 替换同作用域
  ignoreIfExists, // 已存在则忽略
  single, // 只保留一个，不重叠
}

/// 展示 Surface 类型
enum PetSurface { dashboard, modulePage, petCenter }

/// 宠物 Intent —— 描述一次宠物反馈/状态
class PetIntent {
  PetIntent({
    required this.id,
    required this.type,
    this.eventId,
    this.scope = PetIntentScope.module,
    this.module,
    this.replacePolicy = PetIntentReplacePolicy.replaceSameType,
    required this.priority,
    required this.imagePath,
    this.messages = const [],
    this.fixedMessage,
    required this.startedAt,
    this.expiresAt,
    this.persistent = false,
    this.consumable = false,
    this.fromAI = false,
  });

  final String id;
  final String type;
  final String? eventId;
  final PetIntentScope scope;
  final String? module;
  final PetIntentReplacePolicy replacePolicy;
  final int priority;
  final String imagePath;
  final List<String> messages;
  final String? fixedMessage;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool persistent;
  bool consumable;
  bool consumed = false;
  final bool fromAI;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool visibleOn(PetSurface surface, [String? moduleName]) {
    switch (scope) {
      case PetIntentScope.global:
        return true;
      case PetIntentScope.module:
        return surface == PetSurface.modulePage && module == moduleName;
      case PetIntentScope.dashboard:
        return surface == PetSurface.dashboard;
      case PetIntentScope.petCenter:
        return surface == PetSurface.petCenter;
    }
  }

  String get displayMessage =>
      fixedMessage ?? (messages.isNotEmpty ? messages.first : '');

  PetIntent copyWith({
    String? id,
    String? type,
    String? eventId,
    PetIntentScope? scope,
    String? module,
    PetIntentReplacePolicy? replacePolicy,
    int? priority,
    String? imagePath,
    List<String>? messages,
    String? fixedMessage,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? persistent,
    bool? consumable,
    bool? consumed,
    bool? fromAI,
  }) {
    return PetIntent(
      id: id ?? this.id,
      type: type ?? this.type,
      eventId: eventId ?? this.eventId,
      scope: scope ?? this.scope,
      module: module ?? this.module,
      replacePolicy: replacePolicy ?? this.replacePolicy,
      priority: priority ?? this.priority,
      imagePath: imagePath ?? this.imagePath,
      messages: messages ?? this.messages,
      fixedMessage: fixedMessage ?? this.fixedMessage,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      persistent: persistent ?? this.persistent,
      consumable: consumable ?? this.consumable,
      fromAI: fromAI ?? this.fromAI,
    )..consumed = consumed ?? this.consumed;
  }

  // ── 序列化 ──

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'scope': scope.index,
    'replacePolicy': replacePolicy.index,
    'priority': priority,
    'imagePath': imagePath,
    'messages': messages,
    'fixedMessage': fixedMessage,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
    'persistent': persistent,
    'consumable': consumable,
    'consumed': consumed,
    'module': module,
    'eventId': eventId,
    'fromAI': fromAI,
  };

  factory PetIntent.fromJson(Map<String, dynamic> json) {
    return PetIntent(
      id: json['id'] as String,
      type: json['type'] as String,
      scope: PetIntentScope.values[json['scope'] as int],
      replacePolicy:
          PetIntentReplacePolicy.values[json['replacePolicy'] as int],
      priority: json['priority'] as int,
      imagePath: json['imagePath'] as String,
      messages: List<String>.from(json['messages'] as List),
      fixedMessage: json['fixedMessage'] as String?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : null,
      persistent: json['persistent'] as bool,
      consumable: json['consumable'] as bool,
      module: json['module'] as String?,
      eventId: json['eventId'] as String?,
      fromAI: json['fromAI'] as bool,
    )..consumed = json['consumed'] as bool;
  }
}

/// 优先级常量
class PetIntentPriority {
  static const int idle = 10;
  static const int pageEntered = 30;
  static const int lifeSession = 40;
  static const int aiInsight = 70;
  static const int taskCompleted = 80;
  static const int streakAchieved = 90;
  static const int levelUp = 100;
}
