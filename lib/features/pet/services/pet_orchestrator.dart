import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/pet_provider.dart';
import '../models/pet_display_intent.dart';
import '../models/pet_event.dart';
import '../models/pet_intent.dart';
import '../models/pet_priority.dart';
import '../models/pet_runtime_state.dart';
import '../utils/pet_assets.dart';
import 'pet_event_bus.dart';

/// 宠物总调度器
///
/// 管理 baseIntent（默认展示）和 activeIntent（临时覆盖）。
/// 如果 activeIntent 存在且未过期，显示 activeIntent，否则显示 baseIntent。
///
/// 优先级覆盖规则：
/// - feedback 不能覆盖 system / urgent
/// - system 不能覆盖 urgent
/// - 同级或低级都能被高级覆盖
class PetOrchestrator extends StateNotifier<PetRuntimeState> {
  PetOrchestrator(this._ref) : super(const PetRuntimeState());

  final Ref _ref;
  StreamSubscription<PetEvent>? _subscription;
  Timer? _expiryCheckTimer;

  // ── 幂等去重 ──
  final Set<String> _handledEventIds = {};
  final List<_EventLog> _eventLog = [];
  static const _maxLogSize = 200;

  // ── 连续打卡 ──
  DateTime _lastStreakCheck = DateTime.now().subtract(const Duration(minutes: 5));
  int _lastKnownStreak = 0;

  void init() {
    _subscription = PetEventBus.instance.stream.listen(_handleEvent);

    _expiryCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _clearExpired(),
    );

    _loadPersistentIntents();
    Future.microtask(() => _handleEvent(PetEvent.appOpened()));
  }

  Future<void> _loadPersistentIntents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('pet_persistent_intents');
      if (json == null) return;

      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      final now = DateTime.now();
      for (final item in list) {
        final intent = PetIntent.fromJson(item);
        // 过滤条件：未过期、未消费
        if (!intent.isExpired && !intent.consumed) {
          // AI insight: 24小时过期
          if (intent.fromAI) {
            final age = now.difference(intent.startedAt);
            if (age.inHours >= 24) continue;
          }
          intent.consumable = true;
          _activeIntents.add(intent);
        }
      }
      if (_activeIntents.isNotEmpty) {
        _activeIntents.sort((a, b) => b.priority.compareTo(a.priority));
        debugPrint('[Orchestrator] restored ${_activeIntents.length} persistent intents');
      }
    } catch (e) {
      debugPrint('[Orchestrator] _loadPersistentIntents failed: $e');
    }
  }

  Future<void> _savePersistentIntents() async {
    try {
      final persistent = _activeIntents.where((i) => i.persistent).toList();
      if (persistent.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pet_persistent_intents');
        return;
      }
      final list = persistent.map((i) => i.toJson()).toList();
      final json = jsonEncode(list);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pet_persistent_intents', json);
    } catch (e) {
      debugPrint('[Orchestrator] _savePersistentIntents failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  Event handling
  // ──────────────────────────────────────────────

  void _handleEvent(PetEvent event) {
    // 幂等去重
    if (_handledEventIds.contains(event.eventId)) {
      _log(event, 'rejected: duplicate');
      return;
    }
    _handledEventIds.add(event.eventId);
    _log(event, 'accepted');

    switch (event.type) {
      // ── 用户反馈 ──
      case PetEventType.studyCompleted:
        _showFeedback(
          module: 'study',
          imagePath: PetAssets.studyDone,
          messages: ['学习记录完成啦！📚', '今天的努力被记住啦～', '学习辛苦啦～'],
        );
        break;
      case PetEventType.fitnessCompleted:
        _showFeedback(
          module: 'fitness',
          imagePath: PetAssets.fitnessDone,
          messages: ['训练完成，辛苦啦！💪', '运动让人快乐～', '记得拉伸哦～'],
        );
        break;
      case PetEventType.journalCompleted:
        _showFeedback(
          module: 'journal',
          imagePath: PetAssets.journalDone,
          messages: ['日记写好啦！', '记录生活的你真棒～', '今天的成长被记下啦～'],
        );
        break;
      case PetEventType.dietCompleted:
        _showFeedback(
          module: 'diet',
          imagePath: PetAssets.dietDone,
          messages: ['饮食记录完成！🍚', '好好吃饭很重要～', '记录完成啦～'],
        );
        break;
      case PetEventType.sleepCompleted:
        _showFeedback(
          module: 'sleep',
          imagePath: PetAssets.sleepDone,
          messages: ['睡眠记录完成～🌙', '晚安，好梦～', '好好休息～'],
        );
        break;
      case PetEventType.taskCompleted:
        _showFeedback(
          imagePath: PetAssets.eventTaskDone,
          messages: ['任务完成！', '做得好～', '又完成一个！'],
        );
        break;
      case PetEventType.levelUp:
        _showFeedback(
          imagePath: PetAssets.eventLevelUp,
          messages: ['升级啦！🎉', '等级提升！', '好厉害～'],
          duration: const Duration(seconds: 6),
        );
        break;
      case PetEventType.streakAchieved:
        final streakDays = event.payload?['days'] as int? ?? 7;
        _showFeedback(
          imagePath: streakDays >= 30 ? PetAssets.eventStreak30 : PetAssets.eventStreak7,
          messages: ['连续${streakDays}天打卡！🔥', '坚持的力量～', '太自律了～'],
        );
        _pushIntent(PetIntent(
          id: 'streak_${event.eventId}',
          type: 'streak',
          eventId: event.eventId,
          scope: PetIntentScope.global,
          replacePolicy: PetIntentReplacePolicy.stack,
          priority: PetIntentPriority.streakAchieved,
          imagePath: streakDays >= 30 ? PetAssets.eventStreak30 : PetAssets.eventStreak7,
          fixedMessage: '连续${streakDays}天打卡！',
          startedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(seconds: 6)),
          consumable: true,
        ));
        break;

      // ── 系统状态 ──
      case PetEventType.aiAnalysisStarted:
        _showSystem(
          type: 'system_ai_thinking',
          imagePath: PetAssets.aiThinking,
          fixedMessage: '甜甜正在认真分析中～',
        );
        break;
      case PetEventType.aiAnalysisCompleted:
        final petMessage = (event.payload?['shortPetMessage'] ?? event.payload?['petMessage']) as String? ?? '甜甜帮你分析完啦～';
        _showSystem(
          type: 'system_ai_report',
          imagePath: PetAssets.aiReport,
          fixedMessage: petMessage,
          duration: const Duration(seconds: 8),
        );
        _pushIntent(PetIntent(
          id: 'ai_${event.eventId}',
          type: 'ai_insight',
          eventId: event.eventId,
          scope: PetIntentScope.petCenter,
          module: event.module,
          replacePolicy: PetIntentReplacePolicy.ignoreIfExists,
          priority: PetIntentPriority.aiInsight,
          imagePath: PetAssets.aiReport,
          fixedMessage: petMessage,
          startedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          persistent: true,
          fromAI: true,
        ));
        break;
      case PetEventType.aiAnalysisFailed:
        _showSystem(
          type: 'system_ai_error',
          imagePath: PetAssets.aiNetworkError,
          fixedMessage: '这次没分析成功，稍后再试试～',
          priority: PetPriority.urgent,
          duration: const Duration(seconds: 6),
        );
        break;
      case PetEventType.inactiveFor48Hours:
        _showSystem(
          type: 'system_inactive',
          imagePath: PetAssets.eventEncourage,
          fixedMessage: '甜甜有点想你了～',
          duration: const Duration(seconds: 6),
        );
        break;

      case PetEventType.appOpened:
      case PetEventType.pageEntered:
      case PetEventType.bubbleDismissed:
        // 标记当前 active intent 为已消费
        if (state.activeIntent != null) {
          debugPrint('[Orchestrator] bubble dismissed');
        }
        break;
    }
  }

  // ──────────────────────────────────────────────
  //  Intent builders
  // ──────────────────────────────────────────────

  /// 显示用户反馈（feedback 优先级，4 秒后过期）
  void _showFeedback({
    String? module,
    required String imagePath,
    required List<String> messages,
    Duration duration = const Duration(seconds: 4),
  }) {
    final now = DateTime.now();
    final intent = PetDisplayIntent(
      id: 'feedback_${now.millisecondsSinceEpoch}',
      type: 'feedback',
      module: module,
      priority: PetPriority.feedback,
      imagePath: imagePath,
      messages: messages,
      startedAt: now,
      expiresAt: now.add(duration),
    );

    // feedback 不能覆盖 system / urgent
    if (_blocksActive(PetPriority.feedback)) return;

    state = state.copyWith(activeIntent: intent);
  }

  /// 显示系统状态（system / urgent 优先级）
  void _showSystem({
    required String type,
    required String imagePath,
    required String fixedMessage,
    PetPriority priority = PetPriority.system,
    Duration? duration,
  }) {
    final now = DateTime.now();
    final intent = PetDisplayIntent(
      id: '${type}_${now.millisecondsSinceEpoch}',
      type: type,
      priority: priority,
      imagePath: imagePath,
      messages: [],
      fixedMessage: fixedMessage,
      startedAt: now,
      expiresAt: duration != null ? now.add(duration) : null,
    );

    // system 不能覆盖 urgent
    if (priority == PetPriority.system && _blocksActive(PetPriority.system)) {
      return;
    }

    state = state.copyWith(activeIntent: intent);
  }

  /// 当前 activeIntent 是否阻止 [incoming] 优先级的覆盖
  bool _blocksActive(PetPriority incoming) {
    final active = state.activeIntent;
    if (active == null || active.isExpired) return false;
    return active.priority.level > incoming.level;
  }

  // ──────────────────────────────────────────────
  //  Intent queue (Phase 3 infrastructure)
  // ──────────────────────────────────────────────

  final List<PetIntent> _activeIntents = [];

  /// 将 Intent 压入队列，根据 replacePolicy 处理冲突
  void _pushIntent(PetIntent intent) {
    switch (intent.replacePolicy) {
      case PetIntentReplacePolicy.replaceSameType:
        _activeIntents.removeWhere((i) =>
            i.type == intent.type &&
            (i.module == null || intent.module == null || i.module == intent.module));
        _activeIntents.insert(0, intent);
      case PetIntentReplacePolicy.replaceScope:
        _activeIntents.removeWhere((i) => i.scope == intent.scope);
        _activeIntents.insert(0, intent);
      case PetIntentReplacePolicy.stack:
        if (!_activeIntents.any((i) => i.type == intent.type && i.module == intent.module)) {
          _activeIntents.insert(0, intent);
        }
      case PetIntentReplacePolicy.ignoreIfExists:
        if (!_activeIntents.any((i) => i.type == intent.type && i.module == intent.module)) {
          _activeIntents.insert(0, intent);
        }
      case PetIntentReplacePolicy.single:
        _activeIntents.insert(0, intent);
    }
    _activeIntents.sort((a, b) => b.priority.compareTo(a.priority));
    _savePersistentIntents();
  }

  // ──────────────────────────────────────────────
  //  Base intent management
  // ──────────────────────────────────────────────

  /// 设置 baseIntent（Dashboard LifeSession）
  void setBaseIntent(PetDisplayIntent intent) {
    state = state.copyWith(baseIntent: intent);
  }

  /// 设置模块待机状态
  void setModuleAmbient(
    String module,
    String imagePath,
    List<String> messages,
  ) {
    final now = DateTime.now();
    final intent = PetDisplayIntent(
      id: 'ambient_${module}_${now.millisecondsSinceEpoch}',
      type: 'ambient',
      module: module,
      priority: PetPriority.ambient,
      imagePath: imagePath,
      messages: messages,
      startedAt: now,
    );
    state = state.copyWith(baseIntent: intent);
  }

  /// 重置为初始状态
  void reset() {
    state = const PetRuntimeState();
  }

  // ──────────────────────────────────────────────
  //  Expiry
  // ──────────────────────────────────────────────

  void _clearExpired() {
    final hadActive = state.hasActiveIntent;
    final cleared = state.clearExpired();
    if (cleared != state) {
      if (hadActive && !cleared.hasActiveIntent) {
        _handleEvent(PetEvent(
          eventId: 'bubble_dismissed_${DateTime.now().millisecondsSinceEpoch}',
          source: PetEventSource.system,
          type: PetEventType.bubbleDismissed,
        ));
      }
      state = cleared;
    }
    _checkStreak();
    _checkInactive();
    _trimEventLog();
  }

  DateTime _lastInactiveCheck = DateTime.now().subtract(const Duration(hours: 2));

  void _checkInactive() {
    final now = DateTime.now();
    if (now.difference(_lastInactiveCheck).inHours < 1) return;
    _lastInactiveCheck = now;

    final petRepo = _ref.read(petRepositoryProvider);
    petRepo.shouldShowSleepy().then((sleepy) {
      if (sleepy) {
        _handleEvent(PetEvent(
          eventId: 'inactive_${now.millisecondsSinceEpoch}',
          source: PetEventSource.system,
          type: PetEventType.inactiveFor48Hours,
        ));
        debugPrint('[Orchestrator] inactiveFor48Hours detected');
      }
    });
  }

  // ──────────────────────────────────────────────
  //  Streak detection
  // ──────────────────────────────────────────────

  void _checkStreak() {
    final now = DateTime.now();
    if (now.difference(_lastStreakCheck).inSeconds < 60) return;
    _lastStreakCheck = now;

    final expRepo = _ref.read(expRepositoryProvider);
    expRepo.getConsecutiveActiveDays().then((days) {
      if (days > _lastKnownStreak && (days == 7 || days == 30 || days == 100 || _lastKnownStreak == 0)) {
        _lastKnownStreak = days;
        if (days >= 7) {
          _handleEvent(PetEvent(
            eventId: 'streak_${days}',
            source: PetEventSource.system,
            type: PetEventType.streakAchieved,
            payload: {'days': days},
          ));
          debugPrint('[Orchestrator] streak detected: $days days');
        }
      } else {
        _lastKnownStreak = days;
      }
    });
  }

  // ──────────────────────────────────────────────
  //  Logging
  // ──────────────────────────────────────────────

  void _log(PetEvent event, String status) {
    _eventLog.insert(0, _EventLog(event.eventId, event.type, status, DateTime.now()));
    if (_eventLog.length > _maxLogSize) _eventLog.removeLast();
    debugPrint('[Orchestrator] $status: ${event.eventId} (${event.type.name})');
  }

  void _trimEventLog() {
    if (_handledEventIds.length > 500) {
      _handledEventIds.clear();
      debugPrint('[Orchestrator] event dedup cache trimmed');
    }
  }

  // ──────────────────────────────────────────────
  //  Getters
  // ──────────────────────────────────────────────

  /// 当前应显示的 Intent
  PetDisplayIntent? get currentIntent => state.effectiveIntent;

  /// 是否有有效的 activeIntent
  bool get hasActiveIntent => state.hasActiveIntent;

  @override
  void dispose() {
    _subscription?.cancel();
    _expiryCheckTimer?.cancel();
    super.dispose();
  }
}

class _EventLog {
  final String eventId;
  final PetEventType type;
  final String status;
  final DateTime time;
  const _EventLog(this.eventId, this.type, this.status, this.time);
}
