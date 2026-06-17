import 'dart:convert';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/ai_config_repository.dart';
import 'package:growth_os/core/repositories/knowledge_card_repository.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/core/services/ai_service.dart';
import 'package:growth_os/features/study/services/knowledge_card_ai_service.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('KnowledgeCardAiService', () {
    late AppDatabase db;
    late KnowledgeSourceRepository sourceRepo;
    late KnowledgeCardAiService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sourceRepo = KnowledgeSourceRepository(db);
      service = KnowledgeCardAiService(
        aiConfigRepository: AiConfigRepository(db),
        cardRepository: KnowledgeCardRepository(db),
        sourceRepository: sourceRepo,
        aiService: AiService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('buildPayload sends only the selected chunk', () async {
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

      final result = (await sourceRepo.searchChunks(query: '线程 调度')).single;
      final payload = service.buildPayload(result);

      expect(payload.userPrompt, contains('线程是 CPU 调度单位'));
      expect(payload.userPrompt, isNot(contains('页号和页内偏移')));
      expect(payload.userPrompt, contains('返回严格 JSON'));
    });

    test('buildPayloadForResults sends only selected top chunks', () async {
      await sourceRepo.importTextSource(
        title: '操作系统笔记',
        type: 'markdown',
        content: '''
# 进程管理

进程是资源分配单位，线程是 CPU 调度单位。

# 内存管理

分页机制把逻辑地址分成页号和页内偏移。

# 文件管理

目录结构用于组织文件。
''',
      );

      final results = await sourceRepo.searchChunks(query: '线程 页号');
      // With dictionary-based tokenizer, both '线程' and '页号' are recognized terms
      expect(results.length, greaterThanOrEqualTo(2));
      final payload = service.buildPayloadForResults(
        results.take(2).toList(growable: false),
        topic: '操作系统重点',
      );

      expect(payload.userPrompt, contains('操作系统重点'));
      expect(payload.userPrompt, contains('资料片段 1 开始'));
      expect(payload.userPrompt, contains('资料片段 2 开始'));
      // Both chunks should be about process/thread and memory management
      expect(payload.userPrompt, isNot(contains('目录结构用于组织文件')));
    });

    test('saveDrafts inserts local cards and source links', () async {
      final sourceId = await sourceRepo.importTextSource(
        title: '操作系统笔记',
        type: 'markdown',
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
        content: '进程是资源分配单位，线程是 CPU 调度单位。',
      );
      final result = (await sourceRepo.searchChunks(query: '进程 线程')).single;

      final ids = await service.saveDrafts(
        result: result,
        drafts: const [
          KnowledgeCardAiDraft(
            title: '进程与线程',
            question: '进程和线程分别是什么单位？',
            answer: '进程是资源分配单位，线程是 CPU 调度单位。',
            tags: ['操作系统'],
          ),
        ],
      );

      final cards = await db.select(db.knowledgeCards).get();
      final links = await db.select(db.knowledgeCardSourceLinks).get();

      expect(ids, hasLength(1));
      expect(cards.single.id, ids.single);
      expect(cards.single.goalKey, 'kaoyan_computer');
      expect(cards.single.moduleKey, 'operating_system');
      expect(jsonDecode(cards.single.tags!), ['操作系统']);
      expect(links.single.cardId, ids.single);
      expect(links.single.sourceId, sourceId);
      expect(links.single.chunkId, result.chunk.id);
      expect(links.single.quote, contains('进程是资源分配单位'));
    });
  });

  group('checkDraftQuality', () {
    test('flags answer that is too short', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Test',
          question: 'What is Flutter?',
          answer: 'UI',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('答案过短'));
    });

    test('flags question and answer being the same', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Test',
          question: '进程是操作系统中的基本概念',
          answer: '进程是操作系统中的基本概念',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('问题和答案内容相同'));
    });

    test('flags question that is too short', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Test',
          question: 'SQL',
          answer: 'Structured Query Language is used for databases.',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('问题过短'));
    });

    test('returns null for good quality drafts', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: '进程与线程',
          question: '进程和线程的主要区别是什么？',
          answer: '进程是资源分配的基本单位，线程是CPU调度的基本单位。一个进程可以包含多个线程。',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, isNull);
    });

    test('handles multiple drafts independently', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Good',
          question: 'What is a database index?',
          answer: 'A data structure that speeds up lookup operations at the cost of additional storage.',
        ),
        KnowledgeCardAiDraft(
          title: 'Bad',
          question: 'Q',
          answer: 'A',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(2));
      expect(warnings[0], isNull);
      expect(warnings[1], isNotNull);
    });
  });
}
