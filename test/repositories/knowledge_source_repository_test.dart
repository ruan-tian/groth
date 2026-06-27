import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_source_repository.dart';

void main() {
  late AppDatabase db;
  late KnowledgeSourceRepository repo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = KnowledgeSourceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('importTextSource creates source and searchable chunks', () async {
    final sourceId = await repo.importTextSource(
      title: '操作系统笔记',
      type: 'markdown',
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
      content: '''
# 进程管理

进程是资源分配的基本单位，线程是 CPU 调度的基本单位。

# 内存管理

分页机制把逻辑地址分成页号和页内偏移。
''',
    );

    final sources = await repo.getSources();
    final chunks = await repo.getChunksForSource(sourceId);
    expect(sources, hasLength(1));
    expect(sources.single.title, '操作系统笔记');
    expect(chunks, hasLength(2));
    expect(chunks.first.heading, '进程管理');

    final results = await repo.searchChunks(
      query: '线程 CPU 调度',
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
    );
    expect(results, isNotEmpty);
    expect(results.first.source.id, sourceId);
    expect(results.first.chunk.content, contains('线程'));
  });

  test('searchChunks respects scope and hides archived sources', () async {
    final osSourceId = await repo.importTextSource(
      title: '操作系统',
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
      content: '进程和线程都属于操作系统重点。',
    );
    await repo.importTextSource(
      title: '数学',
      goalKey: 'college',
      moduleKey: 'advanced_math',
      content: '极限和连续属于高数重点。',
    );

    final scoped = await repo.searchChunks(
      query: '重点',
      goalKey: 'college',
      moduleKey: 'advanced_math',
    );
    expect(scoped, hasLength(1));
    expect(scoped.single.source.title, '数学');

    await repo.archiveSource(osSourceId);
    final hidden = await repo.searchChunks(query: '进程');
    expect(hidden, isEmpty);
  });

  test('searchChunks ranks heading matches before body-only matches', () async {
    await repo.importTextSource(
      title: '操作系统笔记',
      content: '''
# 文件管理

这里提到线程调度，线程调度，线程调度，但主题不是这一节。

# 线程调度

时间片轮转用于说明调度策略。
''',
    );

    final results = await repo.searchChunks(query: '线程调度');

    expect(results, isNotEmpty);
    expect(results.first.chunk.heading, '线程调度');
    expect(results.first.score, greaterThan(results.last.score));
  });

  test('updateSourceMetadata refreshes source scope and labels', () async {
    final sourceId = await repo.importTextSource(
      title: 'Old OS Note',
      type: 'markdown',
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
      content: 'Processes and threads are OS basics.',
    );

    await repo.updateSourceMetadata(
      id: sourceId,
      title: 'Updated OS Note',
      type: 'text',
      goalKey: 'custom',
      goalName: 'Final Review',
      moduleKey: 'custom',
      moduleName: 'Wrong Answers',
      sourcePath: 'Chapter 2',
      tags: '408, high-frequency',
    );

    final updated = await repo.getSourceById(sourceId);
    expect(updated, isNotNull);
    expect(updated!.title, 'Updated OS Note');
    expect(updated.type, 'text');
    expect(updated.goalKey, 'custom');
    expect(updated.goalName, 'Final Review');
    expect(updated.moduleKey, 'custom');
    expect(updated.moduleName, 'Wrong Answers');
    expect(updated.sourcePath, 'Chapter 2');
    expect(updated.tags, '408, high-frequency');
  });

  test('deleteSource removes source graph and preserves cards', () async {
    final sourceId = await repo.importTextSource(
      title: 'OS Note',
      content: 'A process owns resources; a thread is scheduled by the CPU.',
    );
    final chunk = (await repo.getChunksForSource(sourceId)).single;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cardId = await db
        .into(db.knowledgeCards)
        .insert(
          KnowledgeCardsCompanion.insert(
            title: 'Process vs Thread',
            question: 'What is the difference between a process and a thread?',
            answer:
                'A process owns resources; a thread is scheduled by the CPU.',
            dueAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await repo.linkCardToChunk(
      cardId: cardId,
      sourceId: sourceId,
      chunkId: chunk.id,
      quote: 'A process owns resources.',
    );

    await repo.deleteSource(sourceId);

    expect(await repo.getSourceById(sourceId), isNull);
    expect(await repo.getChunksForSource(sourceId), isEmpty);
    expect(await repo.getReferencesForCard(cardId), isEmpty);
    final card = await (db.select(
      db.knowledgeCards,
    )..where((t) => t.id.equals(cardId))).getSingleOrNull();
    expect(card, isNotNull);
    expect(card!.title, 'Process vs Thread');
  });

  test('replaceSourceContent rebuilds chunks for unlinked source', () async {
    final sourceId = await repo.importTextSource(
      title: 'OS Notes',
      content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
    );

    await repo.replaceSourceContent(
      id: sourceId,
      content: '''
# Memory

Paging maps virtual pages to physical frames.

# Deadlock

Deadlock requires mutual exclusion, hold and wait, no preemption, and circular wait.
''',
    );

    final chunks = await repo.getChunksForSource(sourceId);
    expect(chunks, hasLength(2));
    expect(chunks.first.heading, 'Memory');
    expect(chunks.last.heading, 'Deadlock');
    expect(chunks.first.content, contains('Paging maps virtual pages'));
  });

  test('replaceSourceContent blocks sources with linked cards', () async {
    final sourceId = await repo.importTextSource(
      title: 'OS Notes',
      content: 'A process owns resources and a thread is scheduled by the CPU.',
    );
    final chunk = (await repo.getChunksForSource(sourceId)).single;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cardId = await db
        .into(db.knowledgeCards)
        .insert(
          KnowledgeCardsCompanion.insert(
            title: 'Process vs Thread',
            question: 'What is the difference between a process and a thread?',
            answer:
                'A process owns resources; a thread is scheduled by the CPU.',
            dueAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await repo.linkCardToChunk(
      cardId: cardId,
      sourceId: sourceId,
      chunkId: chunk.id,
      quote: 'A process owns resources.',
    );

    expect(
      () => repo.replaceSourceContent(
        id: sourceId,
        content: 'Rewritten source content.',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'findImportDuplicateCandidates surfaces exact duplicate sources',
    () async {
      final sourceId = await repo.importTextSource(
        title: 'OS Notes',
        sourcePath: 'Chapter 1',
        content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
      );

      final candidates = await repo.findImportDuplicateCandidates(
        title: 'OS Notes',
        sourcePath: 'Chapter 1',
        content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.source.id, sourceId);
      expect(candidates.single.exactContentMatch, isTrue);
      expect(candidates.single.sameTitle, isTrue);
      expect(candidates.single.sameSourcePath, isTrue);
      expect(candidates.single.chunkCount, 2);
    },
  );

  test('findImportDuplicateCandidates ignores unrelated sources', () async {
    await repo.importTextSource(
      title: 'Linear Algebra',
      sourcePath: 'Chapter 4',
      content: 'Matrices and determinants are covered here.',
    );

    final candidates = await repo.findImportDuplicateCandidates(
      title: 'OS Notes',
      sourcePath: 'Chapter 1',
      content: 'Processes and threads are operating system basics.',
    );

    expect(candidates, isEmpty);
  });

  test(
    'findRelatedDuplicateSources excludes the current source and surfaces neighbors',
    () async {
      final sourceId = await repo.importTextSource(
        title: 'OS Notes',
        sourcePath: 'Chapter 1',
        content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
      );
      final duplicateId = await repo.importTextSource(
        title: 'OS Notes Copy',
        sourcePath: 'Chapter 1 copy',
        content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
      );
      await repo.importTextSource(
        title: 'Linear Algebra',
        sourcePath: 'Chapter 4',
        content: 'Matrices and determinants are covered here.',
      );

      final candidates = await repo.findRelatedDuplicateSources(
        sourceId: sourceId,
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.source.id, duplicateId);
      expect(candidates.single.exactContentMatch, isTrue);
      expect(candidates.single.source.id, isNot(sourceId));
    },
  );

  test(
    'markDuplicatePairKept hides duplicate candidates for both sources',
    () async {
      final sourceId = await repo.importTextSource(
        title: 'OS Notes',
        sourcePath: 'Chapter 1',
        content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
      );
      final duplicateId = await repo.importTextSource(
        title: 'OS Notes Copy',
        sourcePath: 'Chapter 1 copy',
        content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
      );

      expect(
        await repo.findRelatedDuplicateSources(sourceId: sourceId),
        isNotEmpty,
      );
      expect(
        await repo.findRelatedDuplicateSources(sourceId: duplicateId),
        isNotEmpty,
      );

      await repo.markDuplicatePairKept(
        sourceId: sourceId,
        candidateSourceId: duplicateId,
      );

      expect(
        await repo.findRelatedDuplicateSources(sourceId: sourceId),
        isEmpty,
      );
      expect(
        await repo.findRelatedDuplicateSources(sourceId: duplicateId),
        isEmpty,
      );
    },
  );

  test('getReferencesForCard returns linked source and chunk', () async {
    final sourceId = await repo.importTextSource(
      title: '操作系统笔记',
      content: '进程是资源分配单位，线程是 CPU 调度单位。',
    );
    final chunk = (await repo.getChunksForSource(sourceId)).single;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cardId = await db
        .into(db.knowledgeCards)
        .insert(
          KnowledgeCardsCompanion.insert(
            title: '进程与线程',
            question: '进程和线程分别是什么单位？',
            answer: '进程是资源分配单位，线程是 CPU 调度单位。',
            dueAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await repo.linkCardToChunk(
      cardId: cardId,
      sourceId: sourceId,
      chunkId: chunk.id,
      quote: '进程是资源分配单位',
    );

    final references = await repo.getReferencesForCard(cardId);
    expect(references, hasLength(1));
    expect(references.single.source.title, '操作系统笔记');
    expect(references.single.chunk.id, chunk.id);
    expect(references.single.link.quote, '进程是资源分配单位');

    final source = await repo.getSourceById(sourceId);
    final sourceReferences = await repo.getCardReferencesForSource(sourceId);
    expect(source?.title, '操作系统笔记');
    expect(sourceReferences, hasLength(1));
    expect(sourceReferences.single.card.id, cardId);
    expect(sourceReferences.single.chunk.id, chunk.id);
  });

  group('checkHealth', () {
    test('returns empty list for healthy knowledge base', () async {
      await repo.importTextSource(
        title: 'Test Source',
        content: 'Some content for testing.',
        goalKey: 'test_goal',
        moduleKey: 'test_module',
      );
      final issues = await repo.checkHealth();
      expect(issues, isEmpty);
    });

    test('detects duplicate source titles', () async {
      await repo.importTextSource(
        title: 'Same Title',
        content: 'First version.',
      );
      await repo.importTextSource(
        title: 'Same Title',
        content: 'Second version.',
      );
      final issues = await repo.checkHealth();
      expect(issues, anyElement(contains('同名资料')));
    });
  });

}
