import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_card_repository.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/study/pages/knowledge_source_detail_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

Widget _buildPage(AppDatabase db, int sourceId) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: KnowledgeSourceDetailPage(sourceId: sourceId)),
  );
}

Future<int> _seedSource(
  KnowledgeSourceRepository repo, {
  String title = 'OS Notes',
}) {
  return repo.importTextSource(
    title: title,
    content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.

# Memory

Paging maps virtual pages to physical frames.
''',
  );
}

void main() {
  late AppDatabase db;
  late KnowledgeSourceRepository sourceRepo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sourceRepo = KnowledgeSourceRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('detail page shows chunks, filter, and generated cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);
    final chunks = await sourceRepo.getChunksForSource(sourceId);
    final cardRepo = KnowledgeCardRepository(db);
    final cardId = await cardRepo.insertCard(
      KnowledgeCardsCompanion.insert(
        title: 'Process card',
        question: 'What does a process own?',
        answer: 'A process owns resources.',
        dueAt: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await sourceRepo.linkCardToChunk(
      cardId: cardId,
      sourceId: sourceId,
      chunkId: chunks.first.id,
      quote: 'A process owns resources.',
    );

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    expect(find.text('OS Notes'), findsOneWidget);
    expect(
      find.byKey(const Key('knowledge-source-detail-generate-source-button')),
      findsOneWidget,
    );
    expect(find.text('Processes'), findsOneWidget);
    expect(find.text('Threads'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Process card'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('knowledge-source-detail-unconverted-filter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Processes'), findsNothing);
    expect(find.text('Threads'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);
  });

  testWidgets('source preview prioritizes unconverted chunks', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);
    final chunks = await sourceRepo.getChunksForSource(sourceId);
    final cardRepo = KnowledgeCardRepository(db);
    final cardId = await cardRepo.insertCard(
      KnowledgeCardsCompanion.insert(
        title: 'Process card',
        question: 'What does a process own?',
        answer: 'A process owns resources.',
        dueAt: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await sourceRepo.linkCardToChunk(
      cardId: cardId,
      sourceId: sourceId,
      chunkId: chunks.first.id,
      quote: 'A process owns resources.',
    );

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('knowledge-source-detail-generate-source-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('确认发送多个片段给 AI'), findsOneWidget);
    expect(find.text('1. OS Notes · Threads'), findsOneWidget);
    expect(find.text('2. OS Notes · Memory'), findsOneWidget);
    expect(find.text('1. OS Notes · Processes'), findsNothing);
  });

  testWidgets('detail page shows related duplicate sources', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);
    await sourceRepo.importTextSource(
      title: 'OS Notes Copy',
      sourcePath: 'Chapter 1 copy',
      content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.

# Memory

Paging maps virtual pages to physical frames.
''',
    );

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    expect(find.text('可能重复的资料'), findsOneWidget);
    expect(find.text('OS Notes Copy'), findsOneWidget);
    expect(find.text('正文完全一致'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('knowledge-source-detail-duplicate-2')),
      findsOneWidget,
    );
  });

  testWidgets('detail page can archive a related duplicate source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);
    final duplicateId = await sourceRepo.importTextSource(
      title: 'OS Notes Copy',
      sourcePath: 'Chapter 1 copy',
      content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.

# Memory

Paging maps virtual pages to physical frames.
''',
    );

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey('knowledge-source-detail-duplicate-archive-$duplicateId'),
      ),
    );
    await tester.pumpAndSettle();

    final dialogButtons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextButton),
    );
    await tester.tap(dialogButtons.last);
    await tester.pumpAndSettle();

    final duplicate = await sourceRepo.getSourceById(duplicateId);
    expect(duplicate, isNotNull);
    expect(duplicate!.archived, isTrue);
  });

  testWidgets('detail page can keep multiple versions for a duplicate source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);
    final duplicateId = await sourceRepo.importTextSource(
      title: 'OS Notes Copy',
      sourcePath: 'Chapter 1 copy',
      content: '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.

# Memory

Paging maps virtual pages to physical frames.
''',
    );

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('knowledge-source-detail-duplicate-$duplicateId')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        ValueKey('knowledge-source-detail-duplicate-keep-$duplicateId'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('knowledge-source-detail-duplicate-$duplicateId')),
      findsNothing,
    );
    expect(find.text('可能重复的资料'), findsNothing);
  });

  testWidgets('chunk preview opens from chunk action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);
    final chunks = await sourceRepo.getChunksForSource(sourceId);

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey('knowledge-source-detail-generate-chunk-${chunks[1].id}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('确认发送给 AI 的片段'), findsOneWidget);
    expect(find.text('Threads'), findsWidgets);
  });

  testWidgets('detail page can rebuild chunks for an unlinked source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);

    await tester.pumpWidget(_buildPage(db, sourceId));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('knowledge-source-detail-rechunk-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('knowledge-source-detail-rechunk-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('knowledge-source-rechunk-content-field')),
      '''
# Deadlock

Deadlock requires mutual exclusion.

# Scheduling

Round robin uses a time slice.
''',
    );
    await tester.ensureVisible(
      find.byKey(const Key('knowledge-source-rechunk-save-button')),
    );
    await tester.tap(
      find.byKey(const Key('knowledge-source-rechunk-save-button')),
    );
    await tester.pumpAndSettle();

    final updatedChunks = await sourceRepo.getChunksForSource(sourceId);
    expect(updatedChunks, hasLength(2));
    expect(updatedChunks.first.heading, 'Deadlock');
    expect(updatedChunks.last.heading, 'Scheduling');
    expect(find.text('Deadlock'), findsOneWidget);
    expect(find.text('Scheduling'), findsOneWidget);
    expect(find.text('Processes'), findsNothing);
  });
}
