import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/ai/pages/ai_analysis_page.dart';
import 'package:growth_os/features/ai/services/knowledge_context_service.dart';

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

  testWidgets('knowledge context confirmation sheet supports skipping chunks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '操作系统笔记',
      type: 'markdown',
      content: '进程是资源分配单位，线程是 CPU 调度单位。',
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('操作系统 进程 线程');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showKnowledgeContextConfirmSheet(
                    context: context,
                    bundle: bundle,
                  ),
                  child: const Text('打开确认'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('打开确认'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('确认发送知识库片段'), findsOneWidget);
    expect(find.text('不发送知识库片段，继续分析'), findsOneWidget);
    expect(find.byKey(const Key('ai-context-keep-top1')), findsOneWidget);
    expect(find.byKey(const Key('ai-context-keep-top3')), findsOneWidget);
    expect(find.textContaining('已选'), findsOneWidget);
  });

  test('analysis state keeps selected knowledge references after success', () async {
    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '操作系统笔记',
      type: 'markdown',
      content: '进程是资源分配单位，线程是 CPU 调度单位。',
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('操作系统 进程 线程');

    final notifier = AiAnalysisNotifier();
    await notifier.runAnalysis(() async => '分析结果', referenceContext: bundle);

    expect(notifier.state.result, '分析结果');
    expect(notifier.state.referenceContext, isNotNull);
    expect(
      notifier.state.referenceContext!.results,
      hasLength(bundle.results.length),
    );
  });

  testWidgets('analysis result card exposes convert-to-card action when references exist', (
    tester,
  ) async {
    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '操作系统笔记',
      type: 'markdown',
      content: '进程是资源分配单位，线程是 CPU 调度单位。',
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('操作系统 进程 线程');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiAnalysisResultCard(
              result: '建议：优先复习进程和线程。',
              referenceContext: bundle,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('ai-analysis-save-card-button')),
      findsOneWidget,
    );
  });

  testWidgets('analysis result card shows cited local chunk indexes', (
    tester,
  ) async {
    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '操作系统笔记',
      type: 'markdown',
      content: '''
# 进程管理

进程是资源分配单位，线程是 CPU 调度单位。

# 内存管理

分页机制把逻辑地址分成页号和页内偏移。
''',
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('操作系统 进程 内存');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiAnalysisResultCard(
              result: '建议优先复习进程和线程区别【片段 1】。',
              referenceContext: bundle,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ai-analysis-citation-status')), findsOneWidget);
    expect(find.textContaining('已引用：片段 1'), findsOneWidget);
  });

  testWidgets('analysis result card warns when no local chunk citation is found', (
    tester,
  ) async {
    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '操作系统笔记',
      type: 'markdown',
      content: '进程是资源分配单位，线程是 CPU 调度单位。',
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('操作系统 进程 线程');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiAnalysisResultCard(
              result: '建议优先复习进程和线程区别。',
              referenceContext: bundle,
            ),
          ),
        ),
      ),
    );

    expect(find.text('未检测到片段编号'), findsOneWidget);
  });
}
