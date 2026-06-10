import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../models/workout_session_state.dart';

final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionController, WorkoutSessionState>((ref) {
      return WorkoutSessionController();
    });

class WorkoutSessionController extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionController() : super(WorkoutSessionState.setup());

  Timer? _ticker;

  void loadTemplate(
    FitnessWorkoutTemplate template,
    List<FitnessWorkoutTemplateExercise> exercises,
  ) {
    _ticker?.cancel();
    state = WorkoutSessionState.setup(
      templateName: template.name,
      bodyPart: template.bodyPart,
      exercises: exercises.map(WorkoutExercisePlan.fromTemplate).toList(),
    );
  }

  void setCustomPlan({
    required String templateName,
    required String bodyPart,
    required List<WorkoutExercisePlan> exercises,
  }) {
    _ticker?.cancel();
    state = WorkoutSessionState.setup(
      templateName: templateName,
      bodyPart: bodyPart,
      exercises: exercises,
    );
  }

  void start() {
    if (state.exercises.isEmpty) return;
    _ticker?.cancel();
    state = state.copyWith(
      phase: WorkoutSessionPhase.exercise,
      currentExerciseIndex: 0,
      currentSet: 1,
      currentSetElapsedSeconds: 0,
      restRemainingSeconds: 0,
      isPaused: false,
      startedAt: DateTime.now(),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void tick() {
    if (state.isPaused || state.phase == WorkoutSessionPhase.summary) return;
    if (state.phase == WorkoutSessionPhase.setup) return;

    if (state.phase == WorkoutSessionPhase.rest) {
      final nextRest = state.restRemainingSeconds - 1;
      final nextTotalElapsed = state.totalElapsedSeconds + 1;
      if (nextRest <= 0) {
        state = state.copyWith(totalElapsedSeconds: nextTotalElapsed);
        _advanceAfterRest();
        return;
      }
      state = state.copyWith(
        restRemainingSeconds: nextRest,
        totalElapsedSeconds: nextTotalElapsed,
      );
      return;
    }

    state = state.copyWith(
      totalElapsedSeconds: state.totalElapsedSeconds + 1,
      currentSetElapsedSeconds: state.currentSetElapsedSeconds + 1,
    );

    final current = state.currentExercise;
    if (current?.type == WorkoutExerciseType.timed &&
        state.currentSetElapsedSeconds >= (current?.targetSeconds ?? 0)) {
      completeCurrentSet();
    }
  }

  void togglePause() {
    if (state.phase == WorkoutSessionPhase.setup ||
        state.phase == WorkoutSessionPhase.summary) {
      return;
    }
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void completeCurrentSet() {
    final current = state.currentExercise;
    if (current == null || state.phase != WorkoutSessionPhase.exercise) return;

    final completed = Map<int, WorkoutExerciseProgress>.from(state.completed);
    final previous = completed[state.currentExerciseIndex];
    completed[state.currentExerciseIndex] = WorkoutExerciseProgress(
      plan: current,
      completedSets: (previous?.completedSets ?? 0) + 1,
      elapsedSeconds:
          (previous?.elapsedSeconds ?? 0) + state.currentSetElapsedSeconds,
    );

    final hasMoreWork = _hasMoreWorkAfterCurrentSet(current);
    if (!hasMoreWork) {
      _ticker?.cancel();
      state = state.copyWith(
        phase: WorkoutSessionPhase.summary,
        completed: completed,
        currentSetElapsedSeconds: 0,
        restRemainingSeconds: 0,
        isPaused: false,
      );
      return;
    }

    final restSeconds = current.restSeconds;
    if (restSeconds <= 0) {
      state = state.copyWith(completed: completed);
      _advanceAfterRest();
      return;
    }

    state = state.copyWith(
      phase: WorkoutSessionPhase.rest,
      completed: completed,
      currentSetElapsedSeconds: 0,
      restRemainingSeconds: restSeconds,
      isPaused: false,
    );
  }

  void skipRest() {
    if (state.phase != WorkoutSessionPhase.rest) return;
    _advanceAfterRest();
  }

  void skipCurrentExercise() {
    if (state.exercises.isEmpty || state.phase == WorkoutSessionPhase.summary) {
      return;
    }
    final nextIndex = state.currentExerciseIndex + 1;
    if (nextIndex >= state.exercises.length) {
      finish();
      return;
    }
    state = state.copyWith(
      phase: WorkoutSessionPhase.exercise,
      currentExerciseIndex: nextIndex,
      currentSet: 1,
      currentSetElapsedSeconds: 0,
      restRemainingSeconds: 0,
      isPaused: false,
    );
  }

  void finish() {
    _ticker?.cancel();
    state = state.copyWith(
      phase: WorkoutSessionPhase.summary,
      currentSetElapsedSeconds: 0,
      restRemainingSeconds: 0,
      isPaused: false,
    );
  }

  void reset() {
    _ticker?.cancel();
    state = WorkoutSessionState.setup(
      templateName: state.templateName,
      bodyPart: state.bodyPart,
      exercises: state.exercises,
    );
  }

  bool _hasMoreWorkAfterCurrentSet(WorkoutExercisePlan current) {
    if (state.currentSet < current.targetSets) return true;
    return state.currentExerciseIndex + 1 < state.exercises.length;
  }

  void _advanceAfterRest() {
    final current = state.currentExercise;
    if (current == null) return;
    if (state.currentSet < current.targetSets) {
      state = state.copyWith(
        phase: WorkoutSessionPhase.exercise,
        currentSet: state.currentSet + 1,
        currentSetElapsedSeconds: 0,
        restRemainingSeconds: 0,
        isPaused: false,
      );
      return;
    }

    final nextIndex = state.currentExerciseIndex + 1;
    if (nextIndex >= state.exercises.length) {
      finish();
      return;
    }
    state = state.copyWith(
      phase: WorkoutSessionPhase.exercise,
      currentExerciseIndex: nextIndex,
      currentSet: 1,
      currentSetElapsedSeconds: 0,
      restRemainingSeconds: 0,
      isPaused: false,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
