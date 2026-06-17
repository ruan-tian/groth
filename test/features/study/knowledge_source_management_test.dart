import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/study/pages/knowledge_source_detail_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

Widget _buildDetailPage(AppDatabase db, int sourceId) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(home: KnowledgeSourceDetailPage(sourceId: sourceId)),
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

  testWidgets('detail page can delete an unlinked source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = KnowledgeSourceRepository(db);
    final sourceId = await repo.importTextSource(
      title: 'Old OS Note',
      content: 'A process owns resources and a thread is scheduled by the CPU.',
    );

    await tester.pumpWidget(_buildDetailPage(db, sourceId));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('knowledge-source-detail-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('删除资料'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('删除'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Old OS Note'), findsNothing);
    expect(await db.select(db.knowledgeSources).get(), isEmpty);
  });

  testWidgets('detail page can edit source metadata from app bar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = KnowledgeSourceRepository(db);
    final sourceId = await repo.importTextSource(
      title: 'Detail Source',
      content: 'This source is opened from the detail page.',
    );

    await tester.pumpWidget(_buildDetailPage(db, sourceId));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('knowledge-source-detail-edit-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('knowledge-source-edit-title-field')),
      'Detail Source Updated',
    );
    await tester.ensureVisible(
      find.byKey(const Key('knowledge-source-edit-save-button')),
    );
    await tester.tap(
      find.byKey(const Key('knowledge-source-edit-save-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Source Updated'), findsOneWidget);
    final updated = (await db.select(db.knowledgeSources).get()).single;
    expect(updated.title, 'Detail Source Updated');
  });
}
