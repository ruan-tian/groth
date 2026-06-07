import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_display_intent.dart';
import '../models/pet_event.dart';
import '../models/pet_priority.dart';
import '../models/pet_runtime_state.dart';
import 'pet_event_bus.dart';

/// 宠物总调度器 V2
///
/// 管理 baseIntent（默认展示）和 activeIntent（临时覆盖）。
/// 如果 activeIntent 存在且未过期，显示 activeIntent，否则显示 baseIntent。
///
/// 优先级覆盖规则：
/// - feedback 不能覆盖 system / urgent
/// - system 不能覆盖 urgent
/// - 同级或低级都能被高级覆盖
class PetOrchestratorV2 extends StateNotifier<PetRuntimeState> {
  PetOrchestratorV2(this._ref) : super(const PetRuntimeState());

  final Ref _ref;
  StreamSubscription<PetEvent>? _subscription;
  Timer? _expiryCheckTimer;

  void init() {
    _subscription = PetEventBus.instance.stream.listen(_handleEvent);

    _expiryCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _clearExpired(),
    );
  }

  // ──────────────────────────────────────────────
  //  Event handling
  // ──────────────────────────────────────────────

  void _handleEvent(PetEvent event) {
    switch (event.type) {
      // ── 用户反馈 ──
      case PetEventType.studyCompleted:
        _showFeedback(
          module: 'study',
          imagePath: 'assets/pet/study/study_done.png',
          messages: ['学习记录完成啦！📚', '今天的努力被记住啦～', '学习辛苦啦～'],
        );
        break;
      case PetEventType.fitnessCompleted:
        _showFeedback(
          module: 'fitness',
          imagePath: 'assets/pet/fitness/fitness_done.png',
          messages: ['训练完成，辛苦啦！💪', '运动让人快乐～', '记得拉伸哦～'],
        );
        break;
      case PetEventType.journalCompleted:
        _showFeedback(
          module: 'journal',
          imagePath: 'assets/pet/journal/journal_done.png',
          messages: ['日记写好啦！', '记录生活的你真棒～', '今天的成长被记下啦～'],
        );
        break;
      case PetEventType.dietCompleted:
        _showFeedback(
          module: 'diet',
          imagePath: 'assets/pet/diet/diet_done.png',
          messages: ['饮食记录完成！🍚', '好好吃饭很重要～', '记录完成啦～'],
        );
        break;
      case PetEventType.sleepCompleted:
        _showFeedback(
          module: 'sleep',
          imagePath: 'assets/pet/sleep/sleep_done.png',
          messages: ['睡眠记录完成～🌙', '晚安，好梦～', '好好休息～'],
        );
        break;
      case PetEventType.taskCompleted:
        _showFeedback(
          imagePath: 'assets/pet/events/event_task_done.png',
          messages: ['任务完成！', '做得好～', '又完成一个！'],
        );
        break;
      case PetEventType.levelUp:
        _showFeedback(
          imagePath: 'assets/pet/events/event_level_up.png',
          messages: ['升级啦！🎉', '等级提升！', '好厉害～'],
          duration: const Duration(seconds: 6),
        );
        break;
      case PetEventType.streakAchieved:
        _showFeedback(
          imagePath: 'assets/pet/events/event_streak.png',
          messages: ['连续打卡！🔥', '坚持的力量～', '太自律了～'],
        );
        break;

      // ── 系统状态 ──
      case PetEventType.aiAnalysisStarted:
        _showSystem(
          type: 'system_ai_thinking',
          imagePath: 'assets/pet/ai/ai_thinking.png',
          fixedMessage: '甜甜正在认真分析中～',
        );
        break;
      case PetEventType.aiAnalysisCompleted:
        final petMessage = event.payload?['petMessage'] as String? ?? '分析完成啦～';
        _showSystem(
          type: 'system_ai_report',
          imagePath: 'assets/pet/ai/ai_report.png',
          fixedMessage: petMessage,
          duration: const Duration(seconds: 8),
        );
        break;
      case PetEventType.aiAnalysisFailed:
        _showSystem(
          type: 'system_ai_error',
          imagePath: 'assets/pet/ai/ai_network_error.png',
          fixedMessage: '这次没分析成功，稍后再试试～',
          priority: PetPriority.urgent,
          duration: const Duration(seconds: 6),
        );
        break;
      case PetEventType.inactiveFor48Hours:
        _showSystem(
          type: 'system_inactive',
          imagePath: 'assets/pet/events/event_encourage.png',
          fixedMessage: '甜甜有点想你了～',
          duration: const Duration(seconds: 6),
        );
        break;

      case PetEventType.appOpened:
      case PetEventType.pageEntered:
      case PetEventType.bubbleDismissed:
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
    final cleared = state.clearExpired();
    if (cleared != state) {
      state = cleared;
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
