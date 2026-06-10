import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/repositories/exp_repository.dart';
import '../../../core/repositories/pet_repository.dart';
import '../../../core/domain/pet/pet_display_intent.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/domain/pet/pet_intent.dart';
import '../../../core/domain/pet/pet_priority.dart';
import '../../../core/domain/pet/pet_runtime_state.dart';
import '../../../core/domain/pet/pet_scene_model.dart';
import '../../../core/constants/pet_assets.dart';
import '../../../core/services/pet_event_bus.dart';

/// 宠物总调度器
///
/// 管理 Dashboard life intent、模块 ambient intents 和 activeIntent（临时覆盖）。
/// Surface 投影层会按页面类型选择合适的默认状态。
///
/// 优先级覆盖规则：
/// - feedback 不能覆盖 system / urgent
/// - system 不能覆盖 urgent
/// - 同级或低级都能被高级覆盖
class PetOrchestrator extends StateNotifier<PetRuntimeState> {
  PetOrchestrator({
    required ExpRepository expRepository,
    required PetRepository petRepository,
  })  : _expRepository = expRepository,
        _petRepository = petRepository,
        super(const PetRuntimeState());

  final ExpRepository _expRepository;
  final PetRepository _petRepository;
  StreamSubscription<PetEvent>? _subscription;
  Timer? _expiryCheckTimer;

  // ── 幂等去重 ──
  final Set<String> _handledEventIds = {};
  final List<_EventLog> _eventLog = [];
  static const _maxLogSize = 200;

  // ── 连续打卡 ──
  DateTime _lastStreakCheck = DateTime.now().subtract(
    const Duration(minutes: 5),
  );
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
        debugPrint(
          '[Orchestrator] restored ${_activeIntents.length} persistent intents',
        );
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
        _showModuleFeedback(PetModuleType.study);
        break;
      case PetEventType.fitnessCompleted:
        _showModuleFeedback(PetModuleType.fitness);
        break;
      case PetEventType.journalCompleted:
        _showModuleFeedback(PetModuleType.journal);
        break;
      case PetEventType.dietCompleted:
        _showModuleFeedback(PetModuleType.diet);
        break;
      case PetEventType.sleepCompleted:
        _showModuleFeedback(PetModuleType.sleep);
        break;
      case PetEventType.musicCompleted:
        _showModuleFeedback(PetModuleType.music);
        break;
      case PetEventType.accountingCompleted:
        _showModuleFeedback(PetModuleType.accounting);
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
          imagePath: streakDays >= 30
              ? PetAssets.eventStreak30
              : PetAssets.eventStreak7,
          messages: ['连续$streakDays天打卡！🔥', '坚持的力量～', '太自律了～'],
        );
        _pushIntent(
          PetIntent(
            id: 'streak_${event.eventId}',
            type: 'streak',
            eventId: event.eventId,
            scope: PetIntentScope.global,
            replacePolicy: PetIntentReplacePolicy.stack,
            priority: PetIntentPriority.streakAchieved,
            imagePath: streakDays >= 30
                ? PetAssets.eventStreak30
                : PetAssets.eventStreak7,
            fixedMessage: '连续$streakDays天打卡！',
            startedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(seconds: 6)),
            consumable: true,
          ),
        );
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
        final petMessage =
            (event.payload?['shortPetMessage'] ?? event.payload?['petMessage'])
                as String? ??
            '甜甜帮你分析完啦～';
        _showSystem(
          type: 'system_ai_report',
          imagePath: PetAssets.aiReport,
          fixedMessage: petMessage,
          duration: const Duration(seconds: 8),
        );
        _pushIntent(
          PetIntent(
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
          ),
        );
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
      case PetEventType.musicStarted:
      case PetEventType.accountingStarted:
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
  void _showModuleFeedback(
    PetModuleType module, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final definition = module.definition;
    _showFeedback(
      module: module.name,
      imagePath: definition.doneState.assetPath,
      messages: [
        definition.doneMessage,
        '${definition.label}完成啦，甜甜记住了～',
        '今天又认真成长了一点～',
      ],
      duration: duration,
    );
  }

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
        _activeIntents.removeWhere(
          (i) =>
              i.type == intent.type &&
              (i.module == null ||
                  intent.module == null ||
                  i.module == intent.module),
        );
        _activeIntents.insert(0, intent);
      case PetIntentReplacePolicy.replaceScope:
        _activeIntents.removeWhere((i) => i.scope == intent.scope);
        _activeIntents.insert(0, intent);
      case PetIntentReplacePolicy.stack:
        if (!_activeIntents.any(
          (i) => i.type == intent.type && i.module == intent.module,
        )) {
          _activeIntents.insert(0, intent);
        }
      case PetIntentReplacePolicy.ignoreIfExists:
        if (!_activeIntents.any(
          (i) => i.type == intent.type && i.module == intent.module,
        )) {
          _activeIntents.insert(0, intent);
        }
      case PetIntentReplacePolicy.single:
        _activeIntents.insert(0, intent);
    }
    _activeIntents.sort((a, b) => b.priority.compareTo(a.priority));
    _savePersistentIntents();
  }

  // ──────────────────────────────────────────────
  //  Default intent management
  // ──────────────────────────────────────────────

  /// 设置 Dashboard LifeSession。
  void setLifeIntent(PetDisplayIntent intent) {
    state = state.copyWith(lifeIntent: intent);
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
    state = state.copyWith(
      moduleIntents: {...state.moduleIntents, module: intent},
    );
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
        _handleEvent(
          PetEvent(
            eventId:
                'bubble_dismissed_${DateTime.now().millisecondsSinceEpoch}',
            source: PetEventSource.system,
            type: PetEventType.bubbleDismissed,
          ),
        );
      }
      state = cleared;
    }
    _checkStreak();
    _checkInactive();
    _trimEventLog();
  }

  DateTime _lastInactiveCheck = DateTime.now().subtract(
    const Duration(hours: 2),
  );

  void _checkInactive() {
    final now = DateTime.now();
    if (now.difference(_lastInactiveCheck).inHours < 1) return;
    _lastInactiveCheck = now;

    final petRepo = _petRepository;
    petRepo.shouldShowSleepy().then((sleepy) {
      if (sleepy) {
        _handleEvent(
          PetEvent(
            eventId: 'inactive_${now.millisecondsSinceEpoch}',
            source: PetEventSource.system,
            type: PetEventType.inactiveFor48Hours,
          ),
        );
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

    final expRepo = _expRepository;
    expRepo.getConsecutiveActiveDays().then((days) {
      if (days > _lastKnownStreak &&
          (days == 7 || days == 30 || days == 100 || _lastKnownStreak == 0)) {
        _lastKnownStreak = days;
        if (days >= 7) {
          _handleEvent(
            PetEvent(
              eventId: 'streak_$days',
              source: PetEventSource.system,
              type: PetEventType.streakAchieved,
              payload: {'days': days},
            ),
          );
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
    _eventLog.insert(
      0,
      _EventLog(event.eventId, event.type, status, DateTime.now()),
    );
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
