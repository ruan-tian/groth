import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/fitness/models/workout_session_state.dart';
import 'package:growth_os/features/fitness/providers/workout_session_provider.dart';

void main() {
  group('WorkoutSessionController', () {
    late WorkoutSessionController controller;

    setUp(() {
      controller = WorkoutSessionController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts a plan and moves completed set into rest', () {
      controller.setCustomPlan(
        templateName: '测试训练',
        bodyPart: '全身',
        exercises: const [
          WorkoutExercisePlan(
            name: '哑铃深蹲',
            type: WorkoutExerciseType.reps,
            targetSets: 2,
            targetReps: 12,
            restSeconds: 30,
          ),
        ],
      );

      controller.start();
      controller.tick();
      controller.tick();
      controller.completeCurrentSet();

      expect(controller.state.phase, WorkoutSessionPhase.rest);
      expect(controller.state.completedSets, 1);
      expect(controller.state.restRemainingSeconds, 30);
      expect(controller.state.currentSetElapsedSeconds, 0);
    });

    test('skipping rest advances to the next set', () {
      controller.setCustomPlan(
        templateName: '测试训练',
        bodyPart: '全身',
        exercises: const [
          WorkoutExercisePlan(
            name: '俯卧撑',
            type: WorkoutExerciseType.reps,
            targetSets: 2,
            targetReps: 10,
            restSeconds: 45,
          ),
        ],
      );

      controller.start();
      controller.completeCurrentSet();
      controller.skipRest();

      expect(controller.state.phase, WorkoutSessionPhase.exercise);
      expect(controller.state.currentSet, 2);
      expect(controller.state.currentExercise?.name, '俯卧撑');
    });

    test('rest countdown reaching zero advances and counts elapsed time', () {
      controller.setCustomPlan(
        templateName: '测试训练',
        bodyPart: '全身',
        exercises: const [
          WorkoutExercisePlan(
            name: '深蹲',
            type: WorkoutExerciseType.reps,
            targetSets: 2,
            targetReps: 12,
            restSeconds: 2,
          ),
        ],
      );

      controller.start();
      controller.completeCurrentSet();
      controller.tick();
      controller.tick();

      expect(controller.state.phase, WorkoutSessionPhase.exercise);
      expect(controller.state.currentSet, 2);
      expect(controller.state.totalElapsedSeconds, 2);
    });

    test(
      'timed exercise auto-completes when the target duration is reached',
      () {
        controller.setCustomPlan(
          templateName: '核心',
          bodyPart: '核心',
          exercises: const [
            WorkoutExercisePlan(
              name: '平板支撑',
              type: WorkoutExerciseType.timed,
              targetSets: 1,
              targetSeconds: 3,
              restSeconds: 0,
            ),
          ],
        );

        controller.start();
        controller.tick();
        controller.tick();
        controller.tick();

        expect(controller.state.phase, WorkoutSessionPhase.summary);
        expect(controller.state.completedSets, 1);
        expect(controller.state.canSave, isTrue);
      },
    );

    test('pause prevents ticks from changing elapsed time', () {
      controller.setCustomPlan(
        templateName: '测试训练',
        bodyPart: '全身',
        exercises: const [
          WorkoutExercisePlan(
            name: '哑铃推举',
            type: WorkoutExerciseType.reps,
            targetSets: 1,
            targetReps: 10,
          ),
        ],
      );

      controller.start();
      controller.tick();
      controller.togglePause();
      controller.tick();

      expect(controller.state.isPaused, isTrue);
      expect(controller.state.totalElapsedSeconds, 1);
      expect(controller.state.currentSetElapsedSeconds, 1);
    });
  });

  test('switching exercise type clears incompatible target fields', () {
    const repsPlan = WorkoutExercisePlan(
      name: '动作',
      type: WorkoutExerciseType.reps,
      targetSets: 3,
      targetReps: 12,
      targetSeconds: 99,
      restSeconds: 60,
    );

    final timedPlan = repsPlan.withType(WorkoutExerciseType.timed);
    final nextRepsPlan = timedPlan.withType(WorkoutExerciseType.reps);

    expect(timedPlan.type, WorkoutExerciseType.timed);
    expect(timedPlan.targetReps, isNull);
    expect(timedPlan.targetSeconds, 99);
    expect(nextRepsPlan.type, WorkoutExerciseType.reps);
    expect(nextRepsPlan.targetReps, 12);
    expect(nextRepsPlan.targetSeconds, isNull);
  });
}
