/// 宠物事件类型
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

/// 宠物事件
class PetEvent {
  const PetEvent({
    required this.type,
    this.module,
    this.payload,
    required this.createdAt,
  });

  final PetEventType type;
  final String? module; // PetModuleType name
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  @override
  String toString() => 'PetEvent($type, module=$module)';
}
