import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/study/pages/knowledge_cards_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

KnowledgeCardsCompanion _card({
  required String title,
  String subject = '操作系统',
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return KnowledgeCardsCompanion.insert(
    deckKey: const Value('computer'),
    goalKey: const Value('kaoyan_computer'),
    moduleKey: const Value('operating_system'),
    subject: Value(subject),
    title: title,
    question: '$title 的问题',
    answer: '$title 的答案',
    dueAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildPage(AppDatabase db) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const KnowledgeCardsPage(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/add',
        builder: (context, state) =>
            Text('add-${state.uri.queryParameters['editCardId'] ?? 'new'}'),
      ),
      GoRoute(
        path: '/plan/study/knowledge/review',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/templates',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/import',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/export',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/sources',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/archive',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/goal',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/onboarding',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: router),
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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Pre-set onboarding done to avoid navigation in tests
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: 'knowledge_onboarding_done',
            value: 'true',
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('bulk mode edits selected card subjects only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await db.into(db.knowledgeCards).insert(_card(title: '进程与线程'));
    await db.into(db.knowledgeCards).insert(_card(title: '分页机制'));

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('批量管理'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('批量管理'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('进程与线程'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      ),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('进程与线程'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('改章节/单元'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '内存管理');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final cards = await db.select(db.knowledgeCards).get();
    final edited = cards.singleWhere((card) => card.title == '进程与线程');
    final untouched = cards.singleWhere((card) => card.title == '分页机制');
    expect(edited.subject, '内存管理');
    expect(untouched.subject, '操作系统');
  });

  testWidgets('app bar exposes local knowledge library entry', (tester) async {
    await db.into(db.knowledgeCards).insert(_card(title: '进程与线程'));

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    expect(find.byTooltip('本地知识库'), findsOneWidget);
  });

  testWidgets('card preview shows linked knowledge source', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cardId = await db
        .into(db.knowledgeCards)
        .insert(_card(title: '进程与线程'));
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

    final cardTile = find.byKey(ValueKey('knowledge-card-manage-tile-$cardId'));
    await tester.scrollUntilVisible(
      cardTile,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(cardTile);
    await tester.pumpAndSettle();

    expect(find.text('知识来源'), findsOneWidget);
    expect(find.text('操作系统笔记'), findsOneWidget);
    expect(find.textContaining('进程是资源分配单位'), findsWidgets);
  });

  testWidgets('knowledge cards home stays stable on compact width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await db.into(db.knowledgeCards).insert(_card(title: '进程与线程'));
    await db.into(db.knowledgeCards).insert(_card(title: '分页机制'));

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    expect(find.text('知识抽卡'), findsWidgets);
    expect(find.textContaining('薄弱卡片'), findsOneWidget);
    expect(find.text('立即复习'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card tile exposes edit action from home page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cardId = await db
        .into(db.knowledgeCards)
        .insert(_card(title: '进程与线程'));

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    final cardTile = find.byKey(ValueKey('knowledge-card-manage-tile-$cardId'));
    await tester.scrollUntilVisible(
      cardTile,
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('编辑'), findsOneWidget);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.text('add-$cardId'), findsOneWidget);
  });

  testWidgets('bulk mode archives selected cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await db.into(db.knowledgeCards).insert(_card(title: '进程与线程'));
    await db.into(db.knowledgeCards).insert(_card(title: '分页机制'));

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('批量管理'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('批量管理'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('进程与线程'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      ),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('进程与线程'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('归档所选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('归档'));
    await tester.pumpAndSettle();

    final activeCards = await (db.select(
      db.knowledgeCards,
    )..where((t) => t.archived.equals(false))).get();
    final archivedCards = await (db.select(
      db.knowledgeCards,
    )..where((t) => t.archived.equals(true))).get();
    expect(activeCards.map((card) => card.title), contains('分页机制'));
    expect(archivedCards.map((card) => card.title), contains('进程与线程'));
  });

  testWidgets('bulk mode moves selected cards to another module', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await db.into(db.knowledgeCards).insert(_card(title: '进程与线程'));
    await db.into(db.knowledgeCards).insert(_card(title: '分页机制'));

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('批量管理'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('批量管理'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('进程与线程'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      ),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('进程与线程'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('移动目标/模块'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('考研通用').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('大学课程').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认移动'));
    await tester.pumpAndSettle();

    final cards = await db.select(db.knowledgeCards).get();
    final moved = cards.singleWhere((card) => card.title == '进程与线程');
    final untouched = cards.singleWhere((card) => card.title == '分页机制');
    expect(moved.goalKey, 'college');
    expect(moved.moduleKey, 'advanced_math');
    expect(moved.deckKey, 'math');
    expect(moved.goalName, isNull);
    expect(moved.moduleName, isNull);
    expect(untouched.goalKey, 'kaoyan_computer');
  });
}
