import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/knowledge/services/knowledge_context_service.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('KnowledgeContextService', () {
    late AppDatabase db;
    late KnowledgeSourceRepository sourceRepo;
    late KnowledgeContextService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sourceRepo = KnowledgeSourceRepository(db);
      service = KnowledgeContextService(sourceRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test('builds a bounded local context from recent study records', () async {
      await sourceRepo.importTextSource(
        title: '操作系统笔记',
        type: 'markdown',
        content: '''
# 进程管理

进程是资源分配单位，线程是 CPU 调度单位。

# 内存管理

分页机制把逻辑地址分成页号和页内偏移。
''',
      );
      await sourceRepo.importTextSource(
        title: '英语阅读笔记',
        type: 'markdown',
        content: '长难句拆分需要先找谓语，再看从句结构。',
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final bundle = await service.buildForStudyRecords([
        StudyRecord(
          id: 1,
          mode: 'professional',
          title: '进程和线程复习',
          subject: '操作系统',
          startTime: now - 3600000,
          endTime: now,
          durationMinutes: 60,
          focusLevel: 4,
          difficultyLevel: 3,
          expGained: 8,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      expect(bundle.query, contains('操作系统'));
      expect(bundle.results, isNotEmpty);
      expect(
        bundle.results.length,
        lessThanOrEqualTo(KnowledgeContextService.maxChunks),
      );
      expect(
        bundle.tokenEstimate,
        lessThanOrEqualTo(KnowledgeContextService.maxTokens),
      );

      final prompt = bundle.toPromptSection();
      expect(prompt, contains('本地知识库检索片段'));
      expect(prompt, contains('引用规则'));
      expect(prompt, contains('【片段 1】'));
      expect(prompt, contains('片段 1: 操作系统笔记'));
      expect(prompt, contains('操作系统笔记'));
      expect(prompt, contains('进程'));
    });

    test('buildForQuery returns empty context for blank query', () async {
      final bundle = await service.buildForQuery('   ');

      expect(bundle.isEmpty, isTrue);
      expect(bundle.query, isEmpty);
      expect(bundle.toPromptSection(), isEmpty);
    });
  });
}
