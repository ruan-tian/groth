import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/study/pages/knowledge_archive_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

KnowledgeCardsCompanion _archivedCard() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return KnowledgeCardsCompanion.insert(
    deckKey: const Value('computer'),
    goalKey: const Value('kaoyan_computer'),
    moduleKey: const Value('operating_system'),
    subject: const Value('操作系统'),
    title: '归档卡片',
    question: '问题',
    answer: '答案',
    archived: const Value(true),
    dueAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildPage(AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: KnowledgeArchivePage()),
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

  testWidgets('archived card can be restored from archive page', (
    tester,
  ) async {
    await db.into(db.knowledgeCards).insert(_archivedCard());
    await tester.pumpWidget(_buildPage(db));
    await tester.pumpAndSettle();

    expect(find.text('归档卡片'), findsOneWidget);
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();

    final activeCards = await (db.select(
      db.knowledgeCards,
    )..where((t) => t.archived.equals(false))).get();
    expect(activeCards, hasLength(1));
    expect(activeCards.single.title, '归档卡片');
  });
}
