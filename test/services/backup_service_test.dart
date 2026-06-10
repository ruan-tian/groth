import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/services/backup_service.dart';

void main() {
  late AppDatabase sourceDb;
  late AppDatabase targetDb;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() {
    sourceDb = AppDatabase(NativeDatabase.memory());
    targetDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await sourceDb.close();
    await targetDb.close();
  });

  test('exports a v2 payload with every registered business table', () async {
    final payload =
        jsonDecode(await BackupService(sourceDb).exportToJson())
            as Map<String, dynamic>;
    final tables = payload['tables'] as Map<String, dynamic>;

    expect(payload['backupVersion'], 2);
    expect(payload['schemaVersion'], sourceDb.schemaVersion);
    expect(tables.keys, contains('studyRecords'));
    expect(tables.keys, contains('fitnessExercises'));
    expect(tables.keys, contains('dailyTasks'));
    expect(tables.keys, contains('dietRecords'));
    expect(tables.keys, contains('sleepRecords'));
    expect(tables.keys, contains('petMessages'));
    expect(tables.keys, contains('musicTracks'));
  });

  test(
    'bad records fail with table context and rollback prior inserts',
    () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await sourceDb
          .into(sourceDb.studyRecords)
          .insert(
            StudyRecordsCompanion.insert(
              mode: 'simple',
              title: 'Math',
              startTime: now - 600000,
              endTime: now,
              durationMinutes: 10,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await sourceDb
          .into(sourceDb.fitnessRecords)
          .insert(
            FitnessRecordsCompanion.insert(
              mode: 'simple',
              bodyPart: 'Full body',
              startTime: now - 600000,
              endTime: now,
              durationMinutes: 10,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payload =
          jsonDecode(await BackupService(sourceDb).exportToJson())
              as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>;
      final fitnessRows = data['fitnessRecords'] as List<dynamic>;
      (fitnessRows.first as Map<String, dynamic>)['durationMinutes'] = 'bad';

      final service = BackupService(targetDb);
      await expectLater(
        service.importFromJson(jsonEncode(payload)),
        throwsA(
          isA<BackupRestoreException>()
              .having((e) => e.tableName, 'tableName', 'fitnessRecords')
              .having((e) => e.rowIndex, 'rowIndex', 0),
        ),
      );

      final studyRows = await targetDb.select(targetDb.studyRecords).get();
      expect(studyRows, isEmpty);
    },
  );
}
