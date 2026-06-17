import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/setting_repository.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../core/domain/pet/life_session.dart';
import '../../../core/utils/pet_image_messages.dart';

/// LifeSession 管理器
///
/// 管理 Dashboard 首页的生活状态。
/// - 读取/创建 LifeSession
/// - 按时间段/周末选择图片
/// - 每张图片绑定 5 条固定语录
/// - 可选 AI 文案（每个 session 最多一次）
/// - 保存到 AppSettings
class LifeSessionManager {
  LifeSessionManager({
    required SettingRepository settingRepository,
    required bool aiLifeMessageEnabled,
  }) : _settingRepository = settingRepository,
       _aiLifeMessageEnabled = aiLifeMessageEnabled;

  final SettingRepository _settingRepository;
  final bool _aiLifeMessageEnabled;
  static const _storageKey = 'pet_life_session';

  LifeSession? _current;

  /// 获取当前 LifeSession（如果过期则创建新的）
  Future<LifeSession> getCurrent() async {
    // 1. 尝试从内存读取
    if (_current != null && !_current!.isExpired) {
      return _current!;
    }

    // 2. 尝试从存储读取
    final stored = await _loadFromStorage();
    if (stored != null && !stored.isExpired) {
      _current = stored;
      return stored;
    }

    // 3. 创建新的
    final session = await _createNew();
    _current = session;
    await _saveToStorage(session);
    return session;
  }

  /// 强制刷新（用于测试或手动触发）
  Future<LifeSession> refresh() async {
    final session = await _createNew();
    _current = session;
    await _saveToStorage(session);
    return session;
  }

  /// 创建新的 LifeSession
  Future<LifeSession> _createNew() async {
    final now = DateTime.now();
    final imageName = _selectImageByTime(now);
    final imagePath = PetImageMessages.getImagePath(imageName);
    final directory = PetImageMessages.getDirectory(imageName);
    final messages = PetImageMessages.getMessages(imageName);

    // 随机持续时间：30分钟 ~ 3小时
    final durationMinutes = 30 + Random().nextInt(151); // 30-180
    final expiresAt = now.add(Duration(minutes: durationMinutes));

    String? aiMessage;
    bool aiUsed = false;

    // 如果开启了 AI 生活文案，尝试生成
    final aiEnabled = _aiLifeMessageEnabled;
    if (aiEnabled) {
      aiMessage = await _tryGenerateAIMessage(imageName);
      if (aiMessage != null) {
        aiUsed = true;
      }
    }

    return LifeSession(
      id: '${now.millisecondsSinceEpoch}',
      imageName: imageName,
      imagePath: imagePath,
      directory: directory,
      messages: messages,
      aiMessage: aiMessage,
      startedAt: now,
      expiresAt: expiresAt,
      aiUsed: aiUsed,
    );
  }

  /// 按时间段选择图片（带概率池）
  ///
  /// 常规生活池 (emotions/life): 70%
  /// 彩蛋池 (travel/concerts/experience/sports): 20%
  /// 社交池 (social): 10%
  String _selectImageByTime(DateTime now) {
    final hour = now.hour;
    final weekday = now.weekday;
    final isWeekend = weekday == 6 || weekday == 7;

    // 决定使用哪个池
    final roll = Random().nextInt(100);
    List<String> pool;

    if (roll < 70) {
      // 70% - 常规生活池
      pool = isWeekend
          ? PetImageMessages.getWeekendPool()
          : PetImageMessages.getTimePool(hour);
    } else if (roll < 90) {
      // 20% - 彩蛋池（旅行/演唱会/体验/赛事）
      pool = PetImageMessages.getEasterEggPool();
    } else {
      // 10% - 社交池
      pool = PetImageMessages.getSocialPool();
    }

    // 排除最近使用过的图片
    final recentKeys = _current != null ? [_current!.imageName] : <String>[];
    final available = pool.where((name) => !recentKeys.contains(name)).toList();
    final finalPool = available.isNotEmpty ? available : pool;

    return finalPool[Random().nextInt(finalPool.length)];
  }

  /// 尝试生成 AI 文案（失败返回 null）
  Future<String?> _tryGenerateAIMessage(String imageName) async {
    try {
      // TODO: 接入 AI 服务生成生活文案
      // 当前返回 null，后续实现
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 从存储加载
  Future<LifeSession?> _loadFromStorage() async {
    try {
      final repo = _settingRepository;
      final json = await repo.getSetting(_storageKey);
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return LifeSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// 保存到存储
  Future<void> _saveToStorage(LifeSession session) async {
    try {
      final repo = _settingRepository;
      await repo.setSetting(_storageKey, jsonEncode(session.toJson()));
    } catch (_) {
      // 保存失败不影响显示
    }
  }
}

/// AI 生活文案开关
final petAiLifeMessageEnabledProvider = StateProvider<bool>((ref) => false);

/// LifeSession 管理器 Provider
final lifeSessionManagerProvider = Provider<LifeSessionManager>((ref) {
  return LifeSessionManager(
    settingRepository: ref.read(settingRepositoryProvider),
    aiLifeMessageEnabled: ref.read(petAiLifeMessageEnabledProvider),
  );
});

/// 当前 LifeSession Provider
final currentLifeSessionProvider = FutureProvider<LifeSession>((ref) async {
  final manager = ref.read(lifeSessionManagerProvider);
  return manager.getCurrent();
});
