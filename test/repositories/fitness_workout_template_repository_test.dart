import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/fitness/repositories/fitness_repository.dart';

void main() {
  late AppDatabase db;
  late FitnessRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FitnessRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('workout templates', () {
    test(
      'seeds built-in workout templates once with ordered exercises',
      () async {
        await repo.ensureBuiltInWorkoutTemplates();
        await repo.ensureBuiltInWorkoutTemplates();

        final templates = await repo.getWorkoutTemplates();
        expect(templates, hasLength(3));
        expect(
          templates.map((template) => template.name),
          containsAll(['全身基础', '核心稳定', '上肢力量']),
        );
        expect(templates.every((template) => template.isBuiltIn), isTrue);

        for (final template in templates) {
          final exercises = await repo.getWorkoutTemplateExercises(template.id);
          expect(exercises, isNotEmpty, reason: template.name);
          expect(
            exercises.map((exercise) => exercise.sortOrder),
            orderedEquals(List.generate(exercises.length, (index) => index)),
            reason: template.name,
          );
        }
      },
    );

    test(
      'copying a built-in template creates editable custom template',
      () async {
        await repo.ensureBuiltInWorkoutTemplates();
        final source = (await repo.getWorkoutTemplates()).firstWhere(
          (template) => template.name == '全身基础',
        );
        final sourceExercises = await repo.getWorkoutTemplateExercises(
          source.id,
        );

        final copyId = await repo.copyWorkoutTemplate(
          source.id,
          name: '我的全身训练',
        );

        final copy = await repo.getWorkoutTemplateById(copyId);
        final copiedExercises = await repo.getWorkoutTemplateExercises(copyId);

        expect(copy, isNotNull);
        expect(copy!.name, '我的全身训练');
        expect(copy.isBuiltIn, isFalse);
        expect(copy.bodyPart, source.bodyPart);
        expect(copiedExercises, hasLength(sourceExercises.length));
        expect(
          copiedExercises.first.exerciseName,
          sourceExercises.first.exerciseName,
        );
        expect(copiedExercises.first.templateId, copyId);
        expect(copiedExercises.first.sortOrder, 0);
      },
    );

    test('built-in templates cannot be deleted', () async {
      await repo.ensureBuiltInWorkoutTemplates();
      final builtIn = (await repo.getWorkoutTemplates()).first;

      expect(
        () => repo.deleteWorkoutTemplate(builtIn.id),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('fitness records', () {
    test('deleting a record also deletes child exercises', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final recordId = await repo.insertFitnessRecord(
        FitnessRecordsCompanion.insert(
          mode: 'professional',
          title: const Value('Strength day'),
          bodyPart: 'Full body',
          startTime: now - 30 * 60 * 1000,
          endTime: now,
          durationMinutes: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repo.insertFitnessExercise(
        FitnessExercisesCompanion.insert(
          fitnessRecordId: recordId,
          exerciseName: 'Squat',
          sets: 3,
          reps: 12,
          createdAt: now,
        ),
      );

      await repo.deleteFitnessRecord(recordId);

      expect(await repo.getFitnessExercisesByRecordId(recordId), isEmpty);
      expect(await repo.getRecentFitnessRecords(limit: 10), isEmpty);
    });
  });
}
