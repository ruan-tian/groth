import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/study/pages/bulk_import_knowledge_cards_page.dart';
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
    dueAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildPage(AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(
      home: BulkImportKnowledgeCardsPage(
        initialGoalKey: 'kaoyan_computer',
        initialModuleKey: 'operating_system',
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

  testWidgets('preview marks existing duplicate questions as skipped', (
    tester,
  ) async {
    await db.into(db.knowledgeCards).insert(_card());
    await tester.pumpWidget(_buildPage(db));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(TextField),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '''
进程和线程有什么区别？|新的答案|操作系统
分页机制是什么？|把内存划分为固定大小的页框。|操作系统
''');
    await tester.scrollUntilVisible(
      find.text('解析预览'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('解析预览'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('已存在相同问题'), findsOneWidget);
    expect(find.textContaining('将导入 1 张'), findsOneWidget);
    expect(find.text('导入 1 张'), findsOneWidget);
  });
}
