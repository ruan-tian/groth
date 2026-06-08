/// 宠物事件类型
///
/// 事件矩阵 (15个):
/// ┌──────────────────────┬──────┬──────┬─────────┬───────┬────┬──────┐
/// │ 事件                 │ 定义 │ emit │ handler │ intent│ UI │ 日志 │
/// ├──────────────────────┼──────┼──────┼─────────┼───────┼────┼──────┤
/// │ appOpened            │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ studyCompleted       │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ fitnessCompleted     │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ journalCompleted     │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ dietCompleted        │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ sleepCompleted       │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ taskCompleted        │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ levelUp              │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ streakAchieved       │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ inactiveFor48Hours   │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ aiAnalysisStarted    │  ✅  │  ✅  │   ✅    │  ❌   │ ❌ │  ✅  │
/// │ aiAnalysisCompleted  │  ✅  │  ✅  │   ✅    │  ✅   │ ✅ │  ✅  │
/// │ aiAnalysisFailed     │  ✅  │  ✅  │   ✅    │  ❌   │ ❌ │  ✅  │
/// │ pageEntered          │  ✅  │  ✅  │   ✅    │  ❌   │ ❌ │  ✅  │
/// │ bubbleDismissed      │  ✅  │  ✅  │   ✅    │  ❌   │ ❌ │  ✅  │
/// └──────────────────────┴──────┴──────┴─────────┴───────┴────┴──────┘
/// 接通率: 15/15 emit, 13/15 intent, 13/15 UI
enum PetEventType {
  appOpened,
  studyCompleted,
  fitnessCompleted,
  journalCompleted,
  dietCompleted,
  sleepCompleted,
  taskCompleted,
  levelUp,
  streakAchieved,
  inactiveFor48Hours,
  aiAnalysisStarted,
  aiAnalysisCompleted,
  aiAnalysisFailed,
  pageEntered,
  bubbleDismissed,
}

enum PetEventSource { userAction, system, ai, lifecycle }

/// 宠物事件
///
/// 幂等保证：每个事件有唯一 eventId，Orchestrator 通过 correlationId 去重。
class PetEvent {
  PetEvent({
    required this.eventId,
    this.correlationId,
    this.source,
    required this.type,
    this.module,
    this.payload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String eventId;
  final String? correlationId;
  final PetEventSource? source;
  final PetEventType type;
  final String? module;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  // ── 工厂方法 ──

  factory PetEvent.moduleCompleted({
    required String eventId,
    String? correlationId,
    required PetEventType type,
    required String module,
    Map<String, dynamic>? payload,
  }) {
    return PetEvent(
      eventId: eventId,
      correlationId: correlationId,
      source: PetEventSource.userAction,
      type: type,
      module: module,
      payload: payload,
    );
  }

  factory PetEvent.taskCompleted({
    required String eventId,
    String? correlationId,
    required String module,
    int? exp,
    String? summary,
  }) {
    return PetEvent(
      eventId: eventId,
      correlationId: correlationId,
      source: PetEventSource.userAction,
      type: PetEventType.taskCompleted,
      module: module,
      payload: {'exp': exp, 'summary': summary},
    );
  }

  factory PetEvent.aiCompleted({
    required String eventId,
    String? correlationId,
    required String module,
    required String shortMessage,
    int? reportId,
  }) {
    return PetEvent(
      eventId: eventId,
      correlationId: correlationId,
      source: PetEventSource.ai,
      type: PetEventType.aiAnalysisCompleted,
      module: module,
      payload: {'shortPetMessage': shortMessage, 'reportId': reportId},
    );
  }

  factory PetEvent.levelUp({
    required int oldLevel,
    required int newLevel,
  }) {
    return PetEvent(
      eventId: 'level_up_${oldLevel}_to_$newLevel',
      source: PetEventSource.system,
      type: PetEventType.levelUp,
      payload: {'oldLevel': oldLevel, 'newLevel': newLevel},
    );
  }

  factory PetEvent.pageEntered({required String module}) {
    return PetEvent(
      eventId: 'page_entered_$module',
      source: PetEventSource.lifecycle,
      type: PetEventType.pageEntered,
      module: module,
    );
  }

  factory PetEvent.appOpened() {
    return PetEvent(
      eventId: 'app_opened',
      source: PetEventSource.lifecycle,
      type: PetEventType.appOpened,
    );
  }

  @override
  String toString() => 'PetEvent($type, module=$module, id=$eventId)';
}
