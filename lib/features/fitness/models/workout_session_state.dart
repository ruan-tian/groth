import '../../../core/database/app_database.dart';

enum WorkoutExerciseType { reps, timed }

enum WorkoutSessionPhase { setup, exercise, rest, summary }

class WorkoutExercisePlan {
  const WorkoutExercisePlan({
    required this.name,
    required this.type,
    required this.targetSets,
    this.targetReps,
    this.targetSeconds,
    this.weightKg,
    this.restSeconds = 60,
    this.note,
  });

  factory WorkoutExercisePlan.fromTemplate(
    FitnessWorkoutTemplateExercise exercise,
  ) {
    return WorkoutExercisePlan(
      name: exercise.exerciseName,
      type: exercise.exerciseType == 'timed'
          ? WorkoutExerciseType.timed
          : WorkoutExerciseType.reps,
      targetSets: exercise.targetSets,
      targetReps: exercise.targetReps,
      targetSeconds: exercise.targetSeconds,
      weightKg: exercise.weightKg,
      restSeconds: exercise.restSeconds,
      note: exercise.note,
    );
  }

  final String name;
  final WorkoutExerciseType type;
  final int targetSets;
  final int? targetReps;
  final int? targetSeconds;
  final double? weightKg;
  final int restSeconds;
  final String? note;

  String get typeCode => type == WorkoutExerciseType.timed ? 'timed' : 'reps';

  String get targetText {
    final prefix = '$targetSets 组';
    if (type == WorkoutExerciseType.timed) {
      return '$prefix × ${targetSeconds ?? 0} 秒';
    }
    final reps = targetReps ?? 0;
    final weight = weightKg == null || weightKg == 0
        ? ''
        : ' · ${weightKg!.toStringAsFixed(weightKg! % 1 == 0 ? 0 : 1)}kg';
    return '$prefix × $reps 次$weight';
  }

  WorkoutExercisePlan copyWith({
    String? name,
    WorkoutExerciseType? type,
    int? targetSets,
    int? targetReps,
    int? targetSeconds,
    double? weightKg,
    int? restSeconds,
    String? note,
  }) {
    return WorkoutExercisePlan(
      name: name ?? this.name,
      type: type ?? this.type,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      note: note ?? this.note,
    );
  }

  WorkoutExercisePlan withType(WorkoutExerciseType nextType) {
    if (nextType == WorkoutExerciseType.timed) {
      return WorkoutExercisePlan(
        name: name,
        type: nextType,
        targetSets: targetSets,
        targetSeconds: targetSeconds ?? 45,
        weightKg: weightKg,
        restSeconds: restSeconds,
        note: note,
      );
    }
    return WorkoutExercisePlan(
      name: name,
      type: nextType,
      targetSets: targetSets,
      targetReps: targetReps ?? 12,
      weightKg: weightKg,
      restSeconds: restSeconds,
      note: note,
    );
  }
}

class WorkoutExerciseProgress {
  const WorkoutExerciseProgress({
    required this.plan,
    required this.completedSets,
    required this.elapsedSeconds,
  });

  final WorkoutExercisePlan plan;
  final int completedSets;
  final int elapsedSeconds;

  int get volume {
    if (plan.type == WorkoutExerciseType.timed) {
      return completedSets * (plan.targetSeconds ?? 0);
    }
    final weight = (plan.weightKg ?? 0).round();
    final reps = plan.targetReps ?? 0;
    return completedSets * reps * weight;
  }
}

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.templateName,
    required this.bodyPart,
    required this.exercises,
    required this.phase,
    this.currentExerciseIndex = 0,
    this.currentSet = 1,
    this.totalElapsedSeconds = 0,
    this.currentSetElapsedSeconds = 0,
    this.restRemainingSeconds = 0,
    this.isPaused = false,
    this.completed = const {},
    this.startedAt,
  });

  factory WorkoutSessionState.setup({
    String templateName = '全身基础',
    String bodyPart = '全身',
    List<WorkoutExercisePlan> exercises = const [],
  }) {
    return WorkoutSessionState(
      templateName: templateName,
      bodyPart: bodyPart,
      exercises: exercises,
      phase: WorkoutSessionPhase.setup,
    );
  }

  final String templateName;
  final String bodyPart;
  final List<WorkoutExercisePlan> exercises;
  final WorkoutSessionPhase phase;
  final int currentExerciseIndex;
  final int currentSet;
  final int totalElapsedSeconds;
  final int currentSetElapsedSeconds;
  final int restRemainingSeconds;
  final bool isPaused;
  final Map<int, WorkoutExerciseProgress> completed;
  final DateTime? startedAt;

  WorkoutExercisePlan? get currentExercise {
    if (exercises.isEmpty || currentExerciseIndex >= exercises.length) {
      return null;
    }
    return exercises[currentExerciseIndex];
  }

  WorkoutExercisePlan? get nextExercise {
    final current = currentExercise;
    if (current == null) return null;
    if (currentSet < current.targetSets) return current;
    final nextIndex = currentExerciseIndex + 1;
    if (nextIndex >= exercises.length) return null;
    return exercises[nextIndex];
  }

  int get completedSets =>
      completed.values.fold(0, (total, item) => total + item.completedSets);

  int get totalTargetSets =>
      exercises.fold(0, (total, item) => total + item.targetSets);

  int get totalVolume =>
      completed.values.fold(0, (total, item) => total + item.volume);

  int get estimatedCalories => (totalElapsedSeconds / 60 * 7).round();

  bool get canSave => completedSets > 0;

  WorkoutSessionState copyWith({
    String? templateName,
    String? bodyPart,
    List<WorkoutExercisePlan>? exercises,
    WorkoutSessionPhase? phase,
    int? currentExerciseIndex,
    int? currentSet,
    int? totalElapsedSeconds,
    int? currentSetElapsedSeconds,
    int? restRemainingSeconds,
    bool? isPaused,
    Map<int, WorkoutExerciseProgress>? completed,
    DateTime? startedAt,
  }) {
    return WorkoutSessionState(
      templateName: templateName ?? this.templateName,
      bodyPart: bodyPart ?? this.bodyPart,
      exercises: exercises ?? this.exercises,
      phase: phase ?? this.phase,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      currentSetElapsedSeconds:
          currentSetElapsedSeconds ?? this.currentSetElapsedSeconds,
      restRemainingSeconds: restRemainingSeconds ?? this.restRemainingSeconds,
      isPaused: isPaused ?? this.isPaused,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
