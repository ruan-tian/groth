import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/health/repositories/diet_repository.dart';
import 'package:growth_os/features/fitness/repositories/fitness_repository.dart';
import 'package:growth_os/features/health/repositories/sleep_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'fitness save writes record, exercises, exp and log atomically',
    () async {
      final repo = FitnessRepository(db);
      final now = DateTime.now().millisecondsSinceEpoch;

      final id = await repo.saveFitnessRecordWithExp(
        record: FitnessRecordsCompanion(
          mode: const Value('professional'),
          title: const Value('Strength'),
          bodyPart: const Value('Full body'),
          activityType: const Value('strength'),
          startTime: Value(now - 45 * 60 * 1000),
          endTime: Value(now),
          durationMinutes: const Value(45),
          intensityLevel: const Value(4),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        exercises: [
          FitnessExercisesCompanion(
            exerciseName: const Value('Squat'),
            sets: const Value(3),
            reps: const Value(8),
            createdAt: Value(now),
          ),
        ],
        exp: 18,
        reason: 'fitness test',
        createdAt: now,
      );

      final record = await repo.getFitnessRecordById(id);
      final exercises = await repo.getFitnessExercisesByRecordId(id);
      final logs =
          await (db.select(db.growthExpLogs)..where(
                (t) => t.sourceType.equals('fitness') & t.sourceId.equals(id),
              ))
              .get();

      expect(record.expGained, 18);
      expect(exercises, hasLength(1));
      expect(exercises.single.fitnessRecordId, id);
      expect(logs.single.expValue, 18);
    },
  );

  test('diet save writes record and optional exp log atomically', () async {
    final repo = DietRepository(db);
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await repo.saveDietRecordWithExp(
      record: DietRecordsCompanion(
        mealType: const Value('breakfast'),
        mealDate: const Value('2026-06-23'),
        foodText: const Value('Eggs'),
        proteinLevel: const Value('high'),
        healthScore: const Value(90),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      exp: 6,
      reason: 'diet test',
      createdAt: now,
    );

    final record = await repo.getDietRecordById(id);
    final logs = await (db.select(
      db.growthExpLogs,
    )..where((t) => t.sourceType.equals('diet') & t.sourceId.equals(id))).get();

    expect(record?.foodText, 'Eggs');
    expect(logs.single.expValue, 6);
  });

  test('sleep save writes record and optional exp log atomically', () async {
    final repo = SleepRepository(db);
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await repo.saveSleepRecordWithExp(
      record: SleepRecordsCompanion(
        sleepDate: const Value('2026-06-23'),
        bedTime: const Value('22:00'),
        sleepTime: const Value('22:30'),
        wakeTime: const Value('06:30'),
        durationMinutes: const Value(480),
        qualityLevel: const Value(4),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      exp: 8,
      reason: 'sleep test',
      createdAt: now,
    );

    final record = await repo.getSleepRecordById(id);
    final logs =
        await (db.select(db.growthExpLogs)..where(
              (t) => t.sourceType.equals('sleep') & t.sourceId.equals(id),
            ))
            .get();

    expect(record?.durationMinutes, 480);
    expect(logs.single.expValue, 8);
  });
}

