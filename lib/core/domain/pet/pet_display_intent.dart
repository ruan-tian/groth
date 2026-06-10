import 'pet_priority.dart';

/// 宠物展示意图
///
/// 描述一次完整的宠物展示：显示什么图片、什么文案、持续多久、优先级多高。
/// 所有宠物展示都通过 Intent 驱动，不再分散在多个 Provider 中。
class PetDisplayIntent {
  const PetDisplayIntent({
    required this.id,
    required this.type,
    this.module,
    required this.priority,
    required this.imagePath,
    required this.messages,
    this.fixedMessage,
    required this.startedAt,
    this.expiresAt,
    this.fromAI = false,
    this.payload,
  });

  /// 唯一标识
  final String id;

  /// 类型标识（如 'life_session', 'feedback_study', 'system_ai_thinking'）
  final String type;

  /// 模块名（如 'study', 'fitness'，null 表示全局）
  final String? module;

  /// 优先级
  final PetPriority priority;

  /// 图片资源路径
  final String imagePath;

  /// 可选消息列表（随机选一条）
  final List<String> messages;

  /// 固定消息（优先于 messages）
  final String? fixedMessage;

  /// 开始时间
  final DateTime startedAt;

  /// 过期时间（null 表示不过期）
  final DateTime? expiresAt;

  /// 是否来自 AI
  final bool fromAI;

  /// 附加数据
  final Map<String, dynamic>? payload;

  /// 是否已过期
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// 获取当前应显示的消息（每 5 分钟轮换）
  String get displayMessage {
    if (fixedMessage != null && fixedMessage!.isNotEmpty) {
      return fixedMessage!;
    }
    if (messages.isEmpty) return '甜甜在这里陪你～';
    final elapsed = DateTime.now().difference(startedAt);
    final fiveMinIntervals = elapsed.inMinutes ~/ 5;
    final index = fiveMinIntervals % messages.length;
    return messages[index];
  }

  /// 复制并修改
  PetDisplayIntent copyWith({
    String? id,
    String? type,
    String? module,
    PetPriority? priority,
    String? imagePath,
    List<String>? messages,
    String? fixedMessage,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? fromAI,
    Map<String, dynamic>? payload,
  }) {
    return PetDisplayIntent(
      id: id ?? this.id,
      type: type ?? this.type,
      module: module ?? this.module,
      priority: priority ?? this.priority,
      imagePath: imagePath ?? this.imagePath,
      messages: messages ?? this.messages,
      fixedMessage: fixedMessage ?? this.fixedMessage,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      fromAI: fromAI ?? this.fromAI,
      payload: payload ?? this.payload,
    );
  }
}
