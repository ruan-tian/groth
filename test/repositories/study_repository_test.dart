import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/study_repository.dart';

/// Helper: build a [StudyRecordsCompanion] for insertion.
StudyRecordsCompanion _buildCompanion({
  String mode = 'simple',
  String title = 'Flutter 学习',
  String? subject,
  int? startTimeMs,
  int? endTimeMs,
  int durationMinutes = 60,
  int? focusLevel,
  int? difficultyLevel,
  String? note,
  int expGained = 0,
  int? createdAtMs,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return StudyRecordsCompanion.insert(
    mode: mode,
    title: title,
    subject: Value(subject),
    startTime: startTimeMs ?? now - durationMinutes * 60 * 1000,
    endTime: endTimeMs ?? now,
    durationMinutes: durationMinutes,
    focusLevel: Value(focusLevel),
    difficultyLevel: Value(difficultyLevel),
    note: Value(note),
    expGained: Value(expGained),
    createdAt: createdAtMs ?? now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late StudyRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StudyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ===========================================================================
  // insertStudyRecord
  // ===========================================================================

  group('insertStudyRecord', () {
    test('inserts a record and returns a positive id', () async {
      final companion = _buildCompanion();
      final id = await repo.insertStudyRecord(companion);
      expect(id, greaterThan(0));
    });

    test('inserted record can be retrieved by id', () async {
      final companion = _buildCompanion(
        title: 'Dart advanced',
        durationMinutes: 45,
      );
      final id = await repo.insertStudyRecord(companion);

      final record = await repo.getStudyRecordById(id);

      expect(record.title, equals('Dart advanced'));
      expect(record.durationMinutes, equals(45));
    });

    test('inserts multiple records with auto-increment ids', () async {
      final id1 = await repo.insertStudyRecord(_buildCompanion(title: 'A'));
      final id2 = await repo.insertStudyRecord(_buildCompanion(title: 'B'));
      final id3 = await repo.insertStudyRecord(_buildCompanion(title: 'C'));

      expect(id1, lessThan(id2));
      expect(id2, lessThan(id3));
    });

    test(
      'saves record exp and exp log in one repository transaction',
      () async {
        final id = await repo.saveStudyRecordWithExp(
          record: _buildCompanion(title: '事务保存'),
          exp: 16,
          reason: '学习: 事务保存 (60 min)',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final record = await (db.select(
          db.studyRecords,
        )..where((t) => t.id.equals(id))).getSingle();
        final logs =
            await (db.select(db.growthExpLogs)..where(
                  (t) => t.sourceType.equals('study') & t.sourceId.equals(id),
                ))
                .get();

        expect(record.expGained, 16);
        expect(logs, hasLength(1));
        expect(logs.single.expValue, 16);
      },
    );
  });

  // ===========================================================================
  // updateStudyRecord
  // ===========================================================================

  group('updateStudyRecord', () {
    test('updates an existing record title and duration', () async {
      final id = await repo.insertStudyRecord(
        _buildCompanion(title: '原始标题', durationMinutes: 30),
      );

      final updated = StudyRecordsCompanion(
        id: Value(id),
        mode: const Value('professional'),
        title: const Value('更新后标题'),
        startTime: Value(
          DateTime.now().millisecondsSinceEpoch - 60 * 60 * 1000,
        ),
        endTime: Value(DateTime.now().millisecondsSinceEpoch),
        durationMinutes: const Value(60),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
      await repo.updateStudyRecord(updated);

      final record = await (db.select(
        db.studyRecords,
      )..where((t) => t.id.equals(id))).getSingle();

      expect(record.title, equals('更新后标题'));
      expect(record.durationMinutes, equals(60));
      expect(record.mode, equals('professional'));
    });
  });

  // ===========================================================================
  // updateStudyRecordExp
  // ===========================================================================

  group('updateStudyRecordExp', () {
    test('updates only the expGained field', () async {
      final id = await repo.insertStudyRecord(_buildCompanion(expGained: 0));

      await repo.updateStudyRecordExp(id, 15);

      final record = await (db.select(
        db.studyRecords,
      )..where((t) => t.id.equals(id))).getSingle();

      expect(record.expGained, equals(15));
      // Title should remain unchanged
      expect(record.title, equals('Flutter 学习'));
    });
  });

  // ===========================================================================
  // deleteStudyRecord
  // ===========================================================================

  group('deleteStudyRecord', () {
    test('deletes a record by id', () async {
      final id = await repo.insertStudyRecord(_buildCompanion());
      await repo.deleteStudyRecord(id);

      final records = await (db.select(
        db.studyRecords,
      )..where((t) => t.id.equals(id))).get();

      expect(records, isEmpty);
    });

    test('deleting non-existent id does not throw', () async {
      // Should not throw
      await repo.deleteStudyRecord(99999);
    });

    test('only deletes the targeted record', () async {
      final id1 = await repo.insertStudyRecord(_buildCompanion(title: 'A'));
      final id2 = await repo.insertStudyRecord(_buildCompanion(title: 'B'));

      await repo.deleteStudyRecord(id1);

      final remaining = await db.select(db.studyRecords).get();
      expect(remaining, hasLength(1));
      expect(remaining.first.id, equals(id2));
    });

    test(
      'clears focus session link before deleting linked study record',
      () async {
        final id = await repo.insertStudyRecord(_buildCompanion());
        final now = DateTime.now().millisecondsSinceEpoch;
        final focusId = await db
            .into(db.focusSessions)
            .insert(
              FocusSessionsCompanion.insert(
                type: 'pomodoro',
                title: 'Linked focus',
                relatedStudyId: Value(id),
                startTime: now - 25 * 60 * 1000,
                endTime: now,
                durationMinutes: 25,
                createdAt: now,
              ),
            );

        await repo.deleteStudyRecord(id);

        final records = await (db.select(
          db.studyRecords,
        )..where((t) => t.id.equals(id))).get();
        final focus = await (db.select(
          db.focusSessions,
        )..where((t) => t.id.equals(focusId))).getSingle();

        expect(records, isEmpty);
        expect(focus.relatedStudyId, equals(null));
      },
    );

    test(
      'clears knowledge card source link before deleting linked study record',
      () async {
        final id = await repo.insertStudyRecord(_buildCompanion());
        final now = DateTime.now().millisecondsSinceEpoch;
        final cardId = await db
            .into(db.knowledgeCards)
            .insert(
              KnowledgeCardsCompanion.insert(
                title: 'Linked card',
                question: 'What should remain?',
                answer: 'The card should remain after deleting the study log.',
                sourceStudyId: Value(id),
                dueAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            );

        await repo.deleteStudyRecord(id);

        final records = await (db.select(
          db.studyRecords,
        )..where((t) => t.id.equals(id))).get();
        final card = await (db.select(
          db.knowledgeCards,
        )..where((t) => t.id.equals(cardId))).getSingle();

        expect(records, isEmpty);
        expect(card.sourceStudyId, equals(null));
      },
    );
  });

  // ===========================================================================
  // getStudyRecordsByDate
  // ===========================================================================

  group('getStudyRecordsByDate', () {
    test('returns records for the specified date', () async {
      final now = DateTime(2026, 6, 5, 14, 30);
      final todayMs = now.millisecondsSinceEpoch;

      await repo.insertStudyRecord(
        _buildCompanion(
          title: '今日学习',
          createdAtMs: todayMs,
          startTimeMs: todayMs - 3600000,
          endTimeMs: todayMs,
        ),
      );

      final records = await repo.getStudyRecordsByDate(now);
      expect(records, hasLength(1));
      expect(records.first.title, equals('今日学习'));
    });

    test('excludes records from other dates', () async {
      final today = DateTime(2026, 6, 5, 12, 0);
      final yesterday = DateTime(2026, 6, 4, 12, 0);

      await repo.insertStudyRecord(
        _buildCompanion(
          title: '今日',
          createdAtMs: today.millisecondsSinceEpoch,
          startTimeMs: today.millisecondsSinceEpoch - 3600000,
          endTimeMs: today.millisecondsSinceEpoch,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          title: '昨日',
          createdAtMs: yesterday.millisecondsSinceEpoch,
          startTimeMs: yesterday.millisecondsSinceEpoch - 3600000,
          endTimeMs: yesterday.millisecondsSinceEpoch,
        ),
      );

      final records = await repo.getStudyRecordsByDate(today);
      expect(records, hasLength(1));
      expect(records.first.title, equals('今日'));
    });

    test('returns empty list when no records for the date', () async {
      final date = DateTime(2025, 1, 1);
      final records = await repo.getStudyRecordsByDate(date);
      expect(records, isEmpty);
    });

    test('returns records ordered by createdAt descending', () async {
      final date = DateTime(2026, 6, 5);
      final baseMs = date.millisecondsSinceEpoch;

      await repo.insertStudyRecord(
        _buildCompanion(
          title: '较早',
          createdAtMs: baseMs + 3600000, // 01:00
          startTimeMs: baseMs,
          endTimeMs: baseMs + 3600000,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          title: '较晚',
          createdAtMs: baseMs + 7200000, // 02:00
          startTimeMs: baseMs + 3600000,
          endTimeMs: baseMs + 7200000,
        ),
      );

      final records = await repo.getStudyRecordsByDate(date);
      expect(records, hasLength(2));
      expect(records.first.title, equals('较晚'));
      expect(records.last.title, equals('较早'));
    });
  });

  // ===========================================================================
  // getStudyRecordsByRange
  // ===========================================================================

  group('getStudyRecordsByRange', () {
    test('returns records within the date range (inclusive)', () async {
      final june1 = DateTime(2026, 6, 1, 10, 0);
      final june3 = DateTime(2026, 6, 3, 10, 0);
      final june5 = DateTime(2026, 6, 5, 10, 0);

      await repo.insertStudyRecord(
        _buildCompanion(
          title: 'June 1',
          createdAtMs: june1.millisecondsSinceEpoch,
          startTimeMs: june1.millisecondsSinceEpoch - 3600000,
          endTimeMs: june1.millisecondsSinceEpoch,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          title: 'June 3',
          createdAtMs: june3.millisecondsSinceEpoch,
          startTimeMs: june3.millisecondsSinceEpoch - 3600000,
          endTimeMs: june3.millisecondsSinceEpoch,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          title: 'June 5',
          createdAtMs: june5.millisecondsSinceEpoch,
          startTimeMs: june5.millisecondsSinceEpoch - 3600000,
          endTimeMs: june5.millisecondsSinceEpoch,
        ),
      );

      // Range: June 1 ~ June 3 (inclusive)
      final records = await repo.getStudyRecordsByRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 3),
      );

      expect(records, hasLength(2));
      final titles = records.map((r) => r.title).toSet();
      expect(titles, containsAll(['June 1', 'June 3']));
    });

    test('returns empty when range has no records', () async {
      final records = await repo.getStudyRecordsByRange(
        DateTime(2020, 1, 1),
        DateTime(2020, 1, 31),
      );
      expect(records, isEmpty);
    });
  });

  // ===========================================================================
  // getRecentStudyRecords
  // ===========================================================================

  group('getRecentStudyRecords', () {
    test('returns records ordered by createdAt descending', () async {
      final base = DateTime(2026, 6, 5).millisecondsSinceEpoch;
      for (var i = 0; i < 5; i++) {
        await repo.insertStudyRecord(
          _buildCompanion(
            title: 'Record $i',
            createdAtMs: base + i * 3600000,
            startTimeMs: base + i * 3600000 - 1800000,
            endTimeMs: base + i * 3600000,
          ),
        );
      }

      final records = await repo.getRecentStudyRecords(limit: 3);
      expect(records, hasLength(3));
      expect(records.first.title, equals('Record 4'));
      expect(records.last.title, equals('Record 2'));
    });

    test('respects limit parameter', () async {
      final base = DateTime(2026, 6, 5).millisecondsSinceEpoch;
      for (var i = 0; i < 10; i++) {
        await repo.insertStudyRecord(
          _buildCompanion(
            title: 'R$i',
            createdAtMs: base + i * 3600000,
            startTimeMs: base + i * 3600000 - 1800000,
            endTimeMs: base + i * 3600000,
          ),
        );
      }

      final records = await repo.getRecentStudyRecords(limit: 5);
      expect(records, hasLength(5));
    });

    test('returns empty when no records exist', () async {
      final records = await repo.getRecentStudyRecords();
      expect(records, isEmpty);
    });
  });

  // ===========================================================================
  // getTotalStudyMinutesByDate
  // ===========================================================================

  group('getTotalStudyMinutesByDate', () {
    test('returns 0 when no records for the date', () async {
      final total = await repo.getTotalStudyMinutesByDate(DateTime(2020, 1, 1));
      expect(total, equals(0));
    });

    test('returns sum of durationMinutes for the date', () async {
      final date = DateTime(2026, 6, 5, 12, 0);
      final baseMs = date.millisecondsSinceEpoch;

      await repo.insertStudyRecord(
        _buildCompanion(
          durationMinutes: 30,
          createdAtMs: baseMs,
          startTimeMs: baseMs - 1800000,
          endTimeMs: baseMs,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          durationMinutes: 45,
          createdAtMs: baseMs + 3600000,
          startTimeMs: baseMs + 1800000,
          endTimeMs: baseMs + 3600000,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          durationMinutes: 25,
          createdAtMs: baseMs + 7200000,
          startTimeMs: baseMs + 5400000,
          endTimeMs: baseMs + 7200000,
        ),
      );

      final total = await repo.getTotalStudyMinutesByDate(date);
      expect(total, equals(100)); // 30 + 45 + 25
    });

    test('excludes records from other dates', () async {
      final date = DateTime(2026, 6, 5, 12, 0);
      final other = DateTime(2026, 6, 4, 12, 0);

      await repo.insertStudyRecord(
        _buildCompanion(
          durationMinutes: 60,
          createdAtMs: date.millisecondsSinceEpoch,
          startTimeMs: date.millisecondsSinceEpoch - 3600000,
          endTimeMs: date.millisecondsSinceEpoch,
        ),
      );
      await repo.insertStudyRecord(
        _buildCompanion(
          durationMinutes: 120,
          createdAtMs: other.millisecondsSinceEpoch,
          startTimeMs: other.millisecondsSinceEpoch - 7200000,
          endTimeMs: other.millisecondsSinceEpoch,
        ),
      );

      final total = await repo.getTotalStudyMinutesByDate(date);
      expect(total, equals(60));
    });
  });
}
