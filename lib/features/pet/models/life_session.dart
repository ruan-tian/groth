/// 生活会话
///
/// Dashboard 上的一次宠物生活状态。
/// 一张图片持续 30 分钟到数小时，每张图片绑定 5 条固定语录。
class LifeSession {
  const LifeSession({
    required this.id,
    required this.imageName,
    required this.imagePath,
    required this.directory,
    required this.messages,
    this.aiMessage,
    required this.startedAt,
    required this.expiresAt,
    this.aiUsed = false,
  });

  /// 唯一标识
  final String id;

  /// 图片名称（如 "吃薯片"）
  final String imageName;

  /// 图片完整路径
  final String imagePath;

  /// 图片所在目录（如 "life", "emotions"）
  final String directory;

  /// 绑定的 5 条固定语录
  final List<String> messages;

  /// AI 生成的语录（可选）
  final String? aiMessage;

  /// 开始时间
  final DateTime startedAt;

  /// 过期时间
  final DateTime expiresAt;

  /// 是否已使用 AI
  final bool aiUsed;

  /// 是否已过期
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 获取当前应显示的消息（优先 AI，每 5 分钟轮换）
  String get displayMessage {
    if (aiMessage != null && aiMessage!.isNotEmpty) {
      return aiMessage!;
    }
    if (messages.isEmpty) return '甜甜在这里陪你～';
    final elapsed = DateTime.now().difference(startedAt);
    final fiveMinIntervals = elapsed.inMinutes ~/ 5;
    final index = fiveMinIntervals % messages.length;
    return messages[index];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageName': imageName,
        'imagePath': imagePath,
        'directory': directory,
        'messages': messages,
        'aiMessage': aiMessage,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'aiUsed': aiUsed,
      };

  factory LifeSession.fromJson(Map<String, dynamic> json) {
    return LifeSession(
      id: json['id'] as String,
      imageName: json['imageName'] as String,
      imagePath: json['imagePath'] as String,
      directory: json['directory'] as String,
      messages: (json['messages'] as List<dynamic>).cast<String>(),
      aiMessage: json['aiMessage'] as String?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
      aiUsed: json['aiUsed'] as bool? ?? false,
    );
  }
}
