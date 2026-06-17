import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_card_repository.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
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
    expect(tables.keys, contains('knowledgeCards'));
    expect(tables.keys, contains('knowledgeReviewLogs'));
    expect(tables.keys, contains('knowledgeCustomTemplates'));
    expect(tables.keys, contains('knowledgeCustomTemplateModules'));
    expect(tables.keys, contains('knowledgeSources'));
    expect(tables.keys, contains('knowledgeChunks'));
    expect(tables.keys, contains('knowledgeCardSourceLinks'));
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

  test(
    'import accepts older backups without optional knowledge card tables',
    () async {
      final payload =
          jsonDecode(await BackupService(sourceDb).exportToJson())
              as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>;
      data.remove('knowledgeCards');
      data.remove('knowledgeReviewLogs');
      data.remove('knowledgeCustomTemplates');
      data.remove('knowledgeCustomTemplateModules');
      data.remove('knowledgeSources');
      data.remove('knowledgeChunks');
      data.remove('knowledgeCardSourceLinks');

      await BackupService(targetDb).importFromJson(jsonEncode(payload));

      final cards = await targetDb.select(targetDb.knowledgeCards).get();
      final logs = await targetDb.select(targetDb.knowledgeReviewLogs).get();
      final templates = await targetDb
          .select(targetDb.knowledgeCustomTemplates)
          .get();
      final modules = await targetDb
          .select(targetDb.knowledgeCustomTemplateModules)
          .get();
      final sources = await targetDb.select(targetDb.knowledgeSources).get();
      final chunks = await targetDb.select(targetDb.knowledgeChunks).get();
      final links = await targetDb
          .select(targetDb.knowledgeCardSourceLinks)
          .get();
      expect(cards, isEmpty);
      expect(logs, isEmpty);
      expect(templates, isEmpty);
      expect(modules, isEmpty);
      expect(sources, isEmpty);
      expect(chunks, isEmpty);
      expect(links, isEmpty);
    },
  );

  test('round-trip preserves custom knowledge templates', () async {
    final repo = KnowledgeCardRepository(sourceDb);
    final templateId = await repo.createCustomTemplate(
      name: '软考高级',
      description: '案例分析和论文复习',
    );
    await repo.createCustomTemplateModule(
      templateId: templateId,
      name: '案例分析',
      deckKey: 'computer',
    );

    final json = await BackupService(sourceDb).exportToJson();
    await BackupService(targetDb).importFromJson(json);

    final importedTemplates = await targetDb
        .select(targetDb.knowledgeCustomTemplates)
        .get();
    final importedModules = await targetDb
        .select(targetDb.knowledgeCustomTemplateModules)
        .get();
    expect(importedTemplates, hasLength(1));
    expect(importedTemplates.single.name, '软考高级');
    expect(importedModules, hasLength(1));
    expect(importedModules.single.name, '案例分析');
    expect(importedModules.single.deckKey, 'computer');
  });

  test(
    'round-trip preserves knowledge sources, chunks and card links',
    () async {
      final cardRepo = KnowledgeCardRepository(sourceDb);
      final sourceRepo = KnowledgeSourceRepository(sourceDb);
      final now = DateTime.now().millisecondsSinceEpoch;
      final cardId = await cardRepo.insertCard(
        KnowledgeCardsCompanion.insert(
          deckKey: const Value('computer'),
          goalKey: const Value('kaoyan_computer'),
          moduleKey: const Value('operating_system'),
          subject: const Value('进程管理'),
          title: '进程和线程',
          question: '进程和线程有什么区别？',
          answer: '进程是资源分配单位，线程是 CPU 调度单位。',
          dueAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final sourceId = await sourceRepo.importTextSource(
        title: '操作系统笔记',
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
        content: '进程是资源分配单位，线程是 CPU 调度单位。',
      );
      final chunk = (await sourceRepo.getChunksForSource(sourceId)).single;
      await sourceRepo.linkCardToChunk(
        cardId: cardId,
        sourceId: sourceId,
        chunkId: chunk.id,
        quote: '线程是 CPU 调度单位',
      );

      final json = await BackupService(sourceDb).exportToJson();
      await BackupService(targetDb).importFromJson(json);

      final importedSources = await targetDb
          .select(targetDb.knowledgeSources)
          .get();
      final importedChunks = await targetDb
          .select(targetDb.knowledgeChunks)
          .get();
      final importedLinks = await targetDb
          .select(targetDb.knowledgeCardSourceLinks)
          .get();
      expect(importedSources, hasLength(1));
      expect(importedSources.single.title, '操作系统笔记');
      expect(importedChunks, hasLength(1));
      expect(importedChunks.single.content, contains('线程'));
      expect(importedLinks, hasLength(1));
      expect(importedLinks.single.quote, '线程是 CPU 调度单位');
    },
  );

  test(
    'import accepts schema 23 knowledge cards without goal fields',
    () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final payload =
          jsonDecode(await BackupService(sourceDb).exportToJson())
              as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>;
      data['knowledgeCards'] = [
        {
          'id': 1,
          'deckKey': 'computer',
          'subject': '操作系统',
          'title': '进程与线程',
          'question': '进程和线程有什么区别？',
          'answer': '进程是资源分配单位，线程是 CPU 调度单位。',
          'explanation': null,
          'tags': null,
          'sourceStudyId': null,
          'masteryLevel': 0,
          'reviewCount': 0,
          'correctStreak': 0,
          'lastReviewedAt': null,
          'dueAt': now,
          'archived': false,
          'createdAt': now,
          'updatedAt': now,
        },
      ];

      await BackupService(targetDb).importFromJson(jsonEncode(payload));

      final cards = await targetDb.select(targetDb.knowledgeCards).get();
      expect(cards, hasLength(1));
      expect(cards.first.goalKey, 'custom');
      expect(cards.first.moduleKey, 'custom');
    },
  );

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
