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
    expect(tables.keys, contains('journalFolders'));
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

  test(
    'round-trip: export with data then import to empty db preserves all rows',
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
              durationMinutes: 30,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await sourceDb
          .into(sourceDb.studyRecords)
          .insert(
            StudyRecordsCompanion.insert(
              mode: 'professional',
              title: 'Physics',
              startTime: now - 1200000,
              endTime: now - 600000,
              durationMinutes: 60,
              createdAt: now - 600000,
              updatedAt: now - 600000,
            ),
          );
      await sourceDb
          .into(sourceDb.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              key: 'theme_mode',
              value: 'dark',
              updatedAt: now,
            ),
          );

      final json = await BackupService(sourceDb).exportToJson();
      await BackupService(targetDb).importFromJson(json);

      final importedStudy = await targetDb.select(targetDb.studyRecords).get();
      expect(importedStudy.length, 2);
      expect(importedStudy[0].title, 'Math');
      expect(importedStudy[1].title, 'Physics');

      final importedSettings = await targetDb
          .select(targetDb.appSettings)
          .get();
      expect(importedSettings.length, 1);
      expect(importedSettings[0].key, 'theme_mode');
      expect(importedSettings[0].value, 'dark');
    },
  );

  test('empty db round-trip: export then import produces no errors', () async {
    final json = await BackupService(sourceDb).exportToJson();
    await BackupService(targetDb).importFromJson(json);

    final studyRows = await targetDb.select(targetDb.studyRecords).get();
    expect(studyRows, isEmpty);
    final settingsRows = await targetDb.select(targetDb.appSettings).get();
    expect(settingsRows, isEmpty);
  });

  test(
    'import clears old data before restoring (replace, not merge)',
    () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Target has 3 study records
      for (var i = 0; i < 3; i++) {
        await targetDb
            .into(targetDb.studyRecords)
            .insert(
              StudyRecordsCompanion.insert(
                mode: 'simple',
                title: 'Old $i',
                startTime: now - 600000,
                endTime: now,
                durationMinutes: 10,
                createdAt: now - i * 1000,
                updatedAt: now - i * 1000,
              ),
            );
      }
      expect((await targetDb.select(targetDb.studyRecords).get()).length, 3);

      // Source has 1 study record
      await sourceDb
          .into(sourceDb.studyRecords)
          .insert(
            StudyRecordsCompanion.insert(
              mode: 'simple',
              title: 'New',
              startTime: now - 600000,
              endTime: now,
              durationMinutes: 10,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final json = await BackupService(sourceDb).exportToJson();
      await BackupService(targetDb).importFromJson(json);

      final imported = await targetDb.select(targetDb.studyRecords).get();
      expect(imported.length, 1);
      expect(imported[0].title, 'New');
    },
  );

  test('import skips backupRecords table (no self-reference)', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Source has a backup record (pointing to a fake path)
    await sourceDb
        .into(sourceDb.backupRecords)
        .insert(
          BackupRecordsCompanion.insert(
            backupName: 'backup_20260101.json',
            backupPath: '/fake/path/backup.json',
            backupType: 'json',
            fileSize: const Value(1024),
            createdAt: now,
          ),
        );

    final json = await BackupService(sourceDb).exportToJson();
    await BackupService(targetDb).importFromJson(json);

    // backupRecords should be empty (skipped during import)
    final importedBackups = await targetDb.select(targetDb.backupRecords).get();
    expect(importedBackups, isEmpty);
  });

  test('import throws when a required table is missing from backup', () async {
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

    final payload =
        jsonDecode(await BackupService(sourceDb).exportToJson())
            as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    data.remove('fitnessRecords');

    await expectLater(
      BackupService(targetDb).importFromJson(jsonEncode(payload)),
      throwsA(
        isA<BackupRestoreException>().having(
          (e) => e.tableName,
          'tableName',
          'fitnessRecords',
        ),
      ),
    );
  });

  test('import throws on unsupported backup version', () async {
    final payload = {
      'version': 1,
      'backupVersion': 1,
      'schemaVersion': 1,
      'data': <String, dynamic>{},
    };

    await expectLater(
      BackupService(targetDb).importFromJson(jsonEncode(payload)),
      throwsA(
        isA<BackupRestoreException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported backup version'),
        ),
      ),
    );
  });
}
