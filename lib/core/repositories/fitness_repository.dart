import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'exp_repository.dart';

/// 健身记录仓库
///
/// 封装健身记录 & 健身动作表的 CRUD 操作与常用查询。
class FitnessRepository {
  FitnessRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 健身记录 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条健身记录，返回自增 ID。
  Future<int> insertFitnessRecord(FitnessRecordsCompanion record) {
    return _db.into(_db.fitnessRecords).insert(record);
  }

  /// 更新一条健身记录（以 companion 中的 id 为准）。
  Future<void> updateFitnessRecord(FitnessRecordsCompanion record) {
    return _db.update(_db.fitnessRecords).replace(record);
  }

  /// 根据 ID 删除一条健身记录。
  Future<void> deleteFitnessRecord(int id) {
    return _db.transaction(() async {
      await deleteFitnessExercisesByRecordId(id);
      await (_db.delete(
        _db.fitnessRecords,
      )..where((t) => t.id.equals(id))).go();
      await ExpRepository(_db).deleteExpLogsForSource('fitness', id);
    });
  }

  // ---------------------------------------------------------------------------
  // 健身记录查询
  // ---------------------------------------------------------------------------

  /// 根据 ID 获取单条健身记录。
  Future<FitnessRecord> getFitnessRecordById(int id) {
    return (_db.select(
      _db.fitnessRecords,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  /// 获取指定日期的健身记录（按 createdAt 毫秒时间戳范围过滤）。
  Future<List<FitnessRecord>> getFitnessRecordsByDate(DateTime date) {
    final range = _dayRange(date);
    return (_db.select(_db.fitnessRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(range.start) &
                t.createdAt.isSmallerThanValue(range.end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取日期范围内的健身记录（包含 start 和 end 当天）。
  Future<List<FitnessRecord>> getFitnessRecordsByRange(
    DateTime start,
    DateTime end,
  ) {
    final startMs = _startOfDay(start).millisecondsSinceEpoch;
    final endMs = _endOfDay(end).millisecondsSinceEpoch;
    return (_db.select(_db.fitnessRecords)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startMs) &
                t.createdAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取指定日期的健身总时长（分钟）。
  ///
  /// 若当天无记录则返回 0。
  Future<int> getTotalFitnessMinutesByDate(DateTime date) async {
    final range = _dayRange(date);
    final result =
        await (_db.selectOnly(_db.fitnessRecords)
              ..addColumns([_db.fitnessRecords.durationMinutes.sum()])
              ..where(
                _db.fitnessRecords.createdAt.isBiggerOrEqualValue(range.start) &
                    _db.fitnessRecords.createdAt.isSmallerThanValue(range.end),
              ))
            .getSingle();
    return result.read(_db.fitnessRecords.durationMinutes.sum()) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // 健身动作 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条健身动作，返回自增 ID。
  Future<int> insertFitnessExercise(FitnessExercisesCompanion exercise) {
    return _db.into(_db.fitnessExercises).insert(exercise);
  }

  /// 批量插入健身动作。
  Future<void> insertFitnessExercises(
    Iterable<FitnessExercisesCompanion> exercises,
  ) async {
    await _db.batch((batch) {
      batch.insertAll(_db.fitnessExercises, exercises.toList());
    });
  }

  /// 删除指定健身记录下的所有动作。
  Future<void> deleteFitnessExercisesByRecordId(int recordId) {
    return (_db.delete(
      _db.fitnessExercises,
    )..where((t) => t.fitnessRecordId.equals(recordId))).go();
  }

  /// 获取指定健身记录下的所有动作。
  Future<List<FitnessExercise>> getFitnessExercisesByRecordId(int recordId) {
    return (_db.select(_db.fitnessExercises)
          ..where((t) => t.fitnessRecordId.equals(recordId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // 健身训练模板
  // ---------------------------------------------------------------------------

  Future<void> ensureBuiltInWorkoutTemplates() async {
    final existing =
        await (_db.selectOnly(_db.fitnessWorkoutTemplates)
              ..addColumns([_db.fitnessWorkoutTemplates.id.count()])
              ..where(_db.fitnessWorkoutTemplates.isBuiltIn.equals(true)))
            .getSingle();
    if ((existing.read(_db.fitnessWorkoutTemplates.id.count()) ?? 0) > 0) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      for (final template in _builtInWorkoutTemplates(now)) {
        final id = await _db
            .into(_db.fitnessWorkoutTemplates)
            .insert(template.template);
        await _db.batch((batch) {
          batch.insertAll(
            _db.fitnessWorkoutTemplateExercises,
            template.exercises
                .map((exercise) => exercise.copyWith(templateId: Value(id)))
                .toList(),
          );
        });
      }
    });
  }

  Future<List<FitnessWorkoutTemplate>> getWorkoutTemplates() {
    return (_db.select(_db.fitnessWorkoutTemplates)..orderBy([
          (t) => OrderingTerm.desc(t.isBuiltIn),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
        .get();
  }

  Future<FitnessWorkoutTemplate?> getWorkoutTemplateById(int id) {
    return (_db.select(
      _db.fitnessWorkoutTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<FitnessWorkoutTemplateExercise>> getWorkoutTemplateExercises(
    int templateId,
  ) {
    return (_db.select(_db.fitnessWorkoutTemplateExercises)
          ..where((t) => t.templateId.equals(templateId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<int> insertWorkoutTemplate(
    FitnessWorkoutTemplatesCompanion template,
    List<FitnessWorkoutTemplateExercisesCompanion> exercises,
  ) async {
    return _db.transaction(() async {
      final id = await _db.into(_db.fitnessWorkoutTemplates).insert(template);
      if (exercises.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.fitnessWorkoutTemplateExercises,
            exercises
                .map((exercise) => exercise.copyWith(templateId: Value(id)))
                .toList(),
          );
        });
      }
      return id;
    });
  }

  Future<void> updateWorkoutTemplate(
    FitnessWorkoutTemplatesCompanion template,
    List<FitnessWorkoutTemplateExercisesCompanion> exercises,
  ) async {
    final id = template.id.value;
    await _db.transaction(() async {
      await _db.update(_db.fitnessWorkoutTemplates).replace(template);
      await (_db.delete(
        _db.fitnessWorkoutTemplateExercises,
      )..where((t) => t.templateId.equals(id))).go();
      if (exercises.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.fitnessWorkoutTemplateExercises,
            exercises
                .map((exercise) => exercise.copyWith(templateId: Value(id)))
                .toList(),
          );
        });
      }
    });
  }

  Future<int> copyWorkoutTemplate(int sourceTemplateId, {String? name}) async {
    final source = await getWorkoutTemplateById(sourceTemplateId);
    if (source == null) {
      throw StateError('Workout template not found: $sourceTemplateId');
    }
    final exercises = await getWorkoutTemplateExercises(sourceTemplateId);
    final now = DateTime.now().millisecondsSinceEpoch;
    return insertWorkoutTemplate(
      FitnessWorkoutTemplatesCompanion.insert(
        name: name ?? '${source.name} 副本',
        bodyPart: source.bodyPart,
        goalType: Value(source.goalType),
        description: Value(source.description),
        isBuiltIn: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
      exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;
        return FitnessWorkoutTemplateExercisesCompanion.insert(
          templateId: 0,
          exerciseName: exercise.exerciseName,
          exerciseType: Value(exercise.exerciseType),
          targetSets: exercise.targetSets,
          targetReps: Value(exercise.targetReps),
          targetSeconds: Value(exercise.targetSeconds),
          weightKg: Value(exercise.weightKg),
          restSeconds: Value(exercise.restSeconds),
          sortOrder: Value(index),
          note: Value(exercise.note),
          createdAt: now,
        );
      }).toList(),
    );
  }

  Future<void> deleteWorkoutTemplate(int id) async {
    final template = await getWorkoutTemplateById(id);
    if (template?.isBuiltIn ?? false) {
      throw StateError('Built-in workout templates cannot be deleted.');
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.fitnessWorkoutTemplateExercises,
      )..where((t) => t.templateId.equals(id))).go();
      await (_db.delete(
        _db.fitnessWorkoutTemplates,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  /// 获取最近的 [limit] 条健身记录（按创建时间倒序）。
  Future<List<FitnessRecord>> getRecentFitnessRecords({int limit = 5}) {
    return (_db.select(_db.fitnessRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 更新指定健身记录的经验值。
  Future<void> updateFitnessRecordExp(int id, int expGained) {
    return (_db.update(_db.fitnessRecords)..where((t) => t.id.equals(id)))
        .write(FitnessRecordsCompanion(expGained: Value(expGained)));
  }

  /// 获取指定日期的健身记录条数。
  Future<int> getFitnessRecordCountByDate(DateTime date) async {
    final range = _dayRange(date);
    final result =
        await (_db.selectOnly(_db.fitnessRecords)
              ..addColumns([_db.fitnessRecords.id.count()])
              ..where(
                _db.fitnessRecords.createdAt.isBiggerOrEqualValue(range.start) &
                    _db.fitnessRecords.createdAt.isSmallerThanValue(range.end),
              ))
            .getSingle();
    return result.read(_db.fitnessRecords.id.count()) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // 身体数据 CRUD
  // ---------------------------------------------------------------------------

  /// 插入一条身体数据，返回自增 ID。
  Future<int> insertBodyMetric(BodyMetricsCompanion metric) {
    return _db.into(_db.bodyMetrics).insert(metric);
  }

  /// 更新一条身体数据。
  Future<void> updateBodyMetric(BodyMetricsCompanion metric) {
    return _db.update(_db.bodyMetrics).replace(metric);
  }

  /// 根据 ID 删除一条身体数据。
  Future<void> deleteBodyMetric(int id) {
    return (_db.delete(_db.bodyMetrics)..where((t) => t.id.equals(id))).go();
  }

  /// 获取所有身体数据（按日期倒序）。
  Future<List<BodyMetric>> getAllBodyMetrics() {
    return (_db.select(
      _db.bodyMetrics,
    )..orderBy([(t) => OrderingTerm.desc(t.recordDate)])).get();
  }

  /// 获取最近 [limit] 条身体数据（按日期倒序）。
  Future<List<BodyMetric>> getRecentBodyMetrics({int limit = 10}) {
    return (_db.select(_db.bodyMetrics)
          ..orderBy([(t) => OrderingTerm.desc(t.recordDate)])
          ..limit(limit))
        .get();
  }

  /// 获取指定日期范围内的身体数据（按日期正序，适合画图）。
  Future<List<BodyMetric>> getBodyMetricsByRange(DateTime start, DateTime end) {
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    return (_db.select(_db.bodyMetrics)
          ..where(
            (t) =>
                t.recordDate.isBiggerOrEqualValue(startStr) &
                t.recordDate.isSmallerOrEqualValue(endStr),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.recordDate)]))
        .get();
  }

  /// 根据 ID 获取单条身体数据。
  Future<BodyMetric?> getBodyMetricById(int id) {
    return (_db.select(
      _db.bodyMetrics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 返回当天 [startMs, endMs) 的毫秒时间戳范围。
  _DayRange _dayRange(DateTime date) {
    final start = _startOfDay(date).millisecondsSinceEpoch;
    final end = _endOfDay(date).millisecondsSinceEpoch;
    return _DayRange(start, end);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day + 1);
}

/// 一天的毫秒时间戳区间 [start, end)。
class _DayRange {
  const _DayRange(this.start, this.end);
  final int start;
  final int end;
}

class _WorkoutTemplateSeed {
  const _WorkoutTemplateSeed({required this.template, required this.exercises});

  final FitnessWorkoutTemplatesCompanion template;
  final List<FitnessWorkoutTemplateExercisesCompanion> exercises;
}

List<_WorkoutTemplateSeed> _builtInWorkoutTemplates(int now) {
  FitnessWorkoutTemplateExercisesCompanion exercise({
    required String name,
    required int sets,
    int? reps,
    int? seconds,
    double? weight,
    required int rest,
    required int order,
    String? note,
  }) {
    final type = seconds == null ? 'reps' : 'timed';
    return FitnessWorkoutTemplateExercisesCompanion.insert(
      templateId: 0,
      exerciseName: name,
      exerciseType: Value(type),
      targetSets: sets,
      targetReps: Value(reps),
      targetSeconds: Value(seconds),
      weightKg: Value(weight),
      restSeconds: Value(rest),
      sortOrder: Value(order),
      note: Value(note),
      createdAt: now,
    );
  }

  return [
    _WorkoutTemplateSeed(
      template: FitnessWorkoutTemplatesCompanion.insert(
        name: '全身基础',
        bodyPart: '全身',
        goalType: const Value('strength'),
        description: const Value('适合日常训练的基础循环，兼顾腿部、上肢和核心。'),
        isBuiltIn: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
      exercises: [
        exercise(name: '哑铃深蹲', sets: 4, reps: 12, rest: 60, order: 0),
        exercise(name: '俯卧撑', sets: 3, reps: 10, rest: 60, order: 1),
        exercise(name: '平板支撑', sets: 3, seconds: 45, rest: 45, order: 2),
        exercise(name: '拉伸放松', sets: 1, seconds: 90, rest: 0, order: 3),
      ],
    ),
    _WorkoutTemplateSeed(
      template: FitnessWorkoutTemplatesCompanion.insert(
        name: '核心稳定',
        bodyPart: '核心',
        goalType: const Value('core'),
        description: const Value('以稳定和耐力为主，适合短时高质量核心训练。'),
        isBuiltIn: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
      exercises: [
        exercise(name: '平板支撑', sets: 4, seconds: 45, rest: 45, order: 0),
        exercise(name: '死虫式', sets: 3, reps: 12, rest: 45, order: 1),
        exercise(name: '登山跑', sets: 3, seconds: 40, rest: 45, order: 2),
        exercise(name: '侧桥', sets: 2, seconds: 30, rest: 30, order: 3),
      ],
    ),
    _WorkoutTemplateSeed(
      template: FitnessWorkoutTemplatesCompanion.insert(
        name: '上肢力量',
        bodyPart: '胸/肩/手臂',
        goalType: const Value('strength'),
        description: const Value('适合居家或轻器械上肢力量训练。'),
        isBuiltIn: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
      exercises: [
        exercise(name: '俯卧撑', sets: 4, reps: 10, rest: 75, order: 0),
        exercise(name: '哑铃推举', sets: 3, reps: 12, rest: 75, order: 1),
        exercise(name: '哑铃弯举', sets: 3, reps: 12, rest: 60, order: 2),
        exercise(name: '肩部拉伸', sets: 1, seconds: 60, rest: 0, order: 3),
      ],
    ),
  ];
}
