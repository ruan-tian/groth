import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/study/pages/knowledge_review_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

KnowledgeCardsCompanion _card() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return KnowledgeCardsCompanion.insert(
    deckKey: const Value('computer'),
    goalKey: const Value('kaoyan_computer'),
    moduleKey: const Value('operating_system'),
    subject: const Value('操作系统'),
    title: '进程与线程',
    question: '进程和线程有什么区别？',
    answer: '进程是资源分配单位，线程是 CPU 调度单位。',
    masteryLevel: const Value(1),
    dueAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildPage(AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(
      home: KnowledgeReviewPage(
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
        includeAll: true,
      ),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('complete panel shows session feedback summary', (tester) async {
    await db.into(db.knowledgeCards).insert(_card());
    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('翻开答案'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('翻开答案'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('不会'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('不会'));
    await tester.pumpAndSettle();

    expect(find.text('这组卡片复习完成'), findsOneWidget);
    expect(find.textContaining('本轮复习 1 张'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('不会'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('不会'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('24 小时内'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('24 小时内'), findsOneWidget);
  });

  testWidgets('answer side shows linked knowledge source', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cardId = await db.into(db.knowledgeCards).insert(_card());
    final sourceRepo = KnowledgeSourceRepository(db);
    final sourceId = await sourceRepo.importTextSource(
      title: '操作系统笔记',
      content: '进程是资源分配单位，线程是 CPU 调度单位。',
    );
    final chunk = (await sourceRepo.getChunksForSource(sourceId)).single;
    await sourceRepo.linkCardToChunk(
      cardId: cardId,
      sourceId: sourceId,
      chunkId: chunk.id,
      quote: '进程是资源分配单位',
    );

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('翻开答案'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('翻开答案'));
    await tester.pumpAndSettle();

    expect(find.textContaining('来源：操作系统笔记'), findsOneWidget);
    expect(find.textContaining('进程是资源分配单位'), findsWidgets);
  });
}
