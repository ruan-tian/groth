import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_card_repository.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_source_repository.dart';
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
      payload.remove('checksum'); // data was mutated, clear stale checksum

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
    payload.remove('checksum'); // data was mutated, clear stale checksum

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
      payload.remove('checksum'); // data was mutated, clear stale checksum

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
      payload.remove('checksum'); // data was mutated, clear stale checksum

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

  test('exports and restores V3 knowledge tables', () async {
    // Create V3 tables manually (they're created by raw SQL in migration)
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_spaces_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'custom',
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'text',
        source_path TEXT,
        url TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ready',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_cards_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        material_id INTEGER,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT,
        card_type TEXT NOT NULL DEFAULT 'recall',
        importance INTEGER NOT NULL DEFAULT 3,
        difficulty INTEGER NOT NULL DEFAULT 3,
        source_title TEXT,
        source_excerpt TEXT,
        tags_json TEXT,
        mastery_level INTEGER NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_review_logs_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL,
        next_due_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        referenced_material_ids_json TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        sources_json TEXT,
        saved_as_card INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Insert V3 data into source
    await sourceDb.customInsert(
      "INSERT INTO knowledge_spaces_v3 (name, type, note, sort_order, is_archived, created_at, updated_at) VALUES ('测试空间', 'custom', '备注', 0, 0, 1000, 1000)",
    );
    final spaces = await sourceDb.customSelect('SELECT * FROM knowledge_spaces_v3').get();
    expect(spaces, hasLength(1));

    final spaceId = spaces.first.data['id'];

    await sourceDb.customInsert(
      "INSERT INTO knowledge_materials (space_id, title, content, source_type, status, is_archived, order_index, created_at, updated_at) VALUES ($spaceId, '资料', '内容', 'text', 'ready', 0, 0, 1000, 1000)",
    );

    // Export
    final json = await BackupService(sourceDb).exportToJson();
    final payload = jsonDecode(json) as Map<String, dynamic>;

    expect(payload['data']['knowledge_spaces_v3'], hasLength(1));
    expect(payload['data']['knowledge_materials'], hasLength(1));

    // Create V3 tables in target
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_spaces_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'custom',
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'text',
        source_path TEXT,
        url TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ready',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_cards_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        material_id INTEGER,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT,
        card_type TEXT NOT NULL DEFAULT 'recall',
        importance INTEGER NOT NULL DEFAULT 3,
        difficulty INTEGER NOT NULL DEFAULT 3,
        source_title TEXT,
        source_excerpt TEXT,
        tags_json TEXT,
        mastery_level INTEGER NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_review_logs_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL,
        next_due_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        referenced_material_ids_json TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        sources_json TEXT,
        saved_as_card INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Restore to target
    await BackupService(targetDb).importFromJson(json);

    // Verify V3 data in target
    final restoredSpaces = await targetDb.customSelect('SELECT * FROM knowledge_spaces_v3').get();
    expect(restoredSpaces, hasLength(1));
    expect(restoredSpaces.first.data['name'], '测试空间');

    final restoredMaterials = await targetDb.customSelect('SELECT * FROM knowledge_materials').get();
    expect(restoredMaterials, hasLength(1));
    expect(restoredMaterials.first.data['title'], '资料');
  });

  test('restore throws when V3 table operations fail', () async {
    // Create V3 tables
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_spaces_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'custom',
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'text',
        source_path TEXT,
        url TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ready',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_cards_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        material_id INTEGER,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT,
        card_type TEXT NOT NULL DEFAULT 'recall',
        importance INTEGER NOT NULL DEFAULT 3,
        difficulty INTEGER NOT NULL DEFAULT 3,
        source_title TEXT,
        source_excerpt TEXT,
        tags_json TEXT,
        mastery_level INTEGER NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_review_logs_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL,
        next_due_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        referenced_material_ids_json TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await sourceDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        sources_json TEXT,
        saved_as_card INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Insert valid V3 data
    await sourceDb.customInsert(
      "INSERT INTO knowledge_spaces_v3 (name, type, note, sort_order, is_archived, created_at, updated_at) VALUES ('空间', 'custom', '', 0, 0, 1000, 1000)",
    );

    final json = await BackupService(sourceDb).exportToJson();

    // Corrupt the V3 data to cause insert failure
    final payload = jsonDecode(json) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    data['knowledge_spaces_v3'] = [
      {'id': 'not_a_number', 'name': 123},
    ];
    final corruptedJson = jsonEncode(payload);

    // Create V3 tables in target
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_spaces_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'custom',
        note TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'text',
        source_path TEXT,
        url TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ready',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_cards_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        material_id INTEGER,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT,
        card_type TEXT NOT NULL DEFAULT 'recall',
        importance INTEGER NOT NULL DEFAULT 3,
        difficulty INTEGER NOT NULL DEFAULT 3,
        source_title TEXT,
        source_excerpt TEXT,
        tags_json TEXT,
        mastery_level INTEGER NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_review_logs_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL,
        next_due_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        referenced_material_ids_json TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await targetDb.customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        sources_json TEXT,
        saved_as_card INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Restore should throw because V3 insert fails
    expect(
      () => BackupService(targetDb).importFromJson(corruptedJson),
      throwsA(isA<BackupRestoreException>()),
    );
  });
}
