import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/study/pages/knowledge_sources_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

Widget _buildPage(AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: KnowledgeSourcesPage()),
  );
}

Widget _buildRoutedPage(AppDatabase db) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const KnowledgeSourcesPage(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/sources/:id',
        builder: (context, state) =>
            Text('detail-${state.pathParameters['id']}'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: router),
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

  testWidgets('source card routes to detail page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo);

    await tester.pumpWidget(_buildRoutedPage(db));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(ValueKey('knowledge-source-card-$sourceId')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(ValueKey('knowledge-source-card-$sourceId')));
    await tester.pumpAndSettle();

    expect(find.text('detail-$sourceId'), findsOneWidget);
  });

  testWidgets('search results expose multi-chunk generation entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _seedSource(sourceRepo);

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('knowledge-source-search-field')),
      'os',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('knowledge-source-generate-from-results-button')),
      findsOneWidget,
    );
  });

  testWidgets('duplicate import shows warning before continuing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _seedSource(sourceRepo);

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('knowledge-source-title-field')),
      'OS Notes',
    );
    await tester.enterText(
      find.byKey(const Key('knowledge-source-content-field')),
      '''
# Processes

A process owns resources.

# Threads

A thread is scheduled by the CPU.
''',
    );
    // Scroll down to make the save button visible (quick import section pushes it down)
    final sheetFinder = find.byType(DraggableScrollableSheet).last;
    await tester.drag(sheetFinder, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('knowledge-source-import-save-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('knowledge-source-duplicate-dialog')),
      findsOneWidget,
    );
    expect(await db.select(db.knowledgeSources).get(), hasLength(1));

    await tester.tap(
      find.byKey(const Key('knowledge-source-duplicate-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(await db.select(db.knowledgeSources).get(), hasLength(2));
  });

  testWidgets('duplicate filter keeps only suspected duplicate sources', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _seedSource(sourceRepo, title: 'OS Notes');
    await _seedSource(sourceRepo, title: 'OS Notes Copy');
    await sourceRepo.importTextSource(
      title: 'Linear Algebra',
      content: '''
# Matrix

Matrices and determinants are covered here.
''',
    );

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    expect(find.text('OS Notes'), findsOneWidget);
    expect(find.text('OS Notes Copy'), findsOneWidget);
    expect(find.text('Linear Algebra'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('knowledge-source-duplicate-filter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('OS Notes'), findsOneWidget);
    expect(find.text('OS Notes Copy'), findsOneWidget);
    expect(find.text('Linear Algebra'), findsNothing);
  });

  testWidgets('duplicate filter ignores archived duplicate candidates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo, title: 'OS Notes');
    final duplicateId = await _seedSource(sourceRepo, title: 'OS Notes Copy');
    await sourceRepo.archiveSource(duplicateId);

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    expect(find.text('OS Notes'), findsOneWidget);
    expect(find.text('OS Notes Copy'), findsNothing);

    await tester.tap(
      find.byKey(const Key('knowledge-source-duplicate-filter')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('knowledge-source-card-$sourceId')),
      findsNothing,
    );
  });

  testWidgets('duplicate filter ignores kept duplicate pairs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sourceId = await _seedSource(sourceRepo, title: 'OS Notes');
    final duplicateId = await _seedSource(sourceRepo, title: 'OS Notes Copy');
    await sourceRepo.markDuplicatePairKept(
      sourceId: sourceId,
      candidateSourceId: duplicateId,
    );

    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    expect(find.text('OS Notes'), findsOneWidget);
    expect(find.text('OS Notes Copy'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('knowledge-source-duplicate-filter')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('knowledge-source-card-$sourceId')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('knowledge-source-card-$duplicateId')),
      findsNothing,
    );
  });
}
