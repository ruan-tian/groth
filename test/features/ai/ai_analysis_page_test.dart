import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/ai/pages/ai_analysis_page.dart';
import 'package:growth_os/features/knowledge/services/knowledge_context_service.dart';

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
      title: '鎿嶄綔绯荤粺绗旇',
      type: 'markdown',
      content: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('鎿嶄綔绯荤粺 杩涚▼ 绾跨▼');

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
                  child: const Text('鎵撳紑纭'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('鎵撳紑纭'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('纭鍙戦€佺煡璇嗗簱鐗囨'), findsOneWidget);
    expect(find.text('涓嶅彂閫佺煡璇嗗簱鐗囨锛岀户缁垎鏋?), findsOneWidget);
    expect(find.byKey(const Key('ai-context-keep-top1')), findsOneWidget);
    expect(find.byKey(const Key('ai-context-keep-top3')), findsOneWidget);
    expect(find.textContaining('宸查€?), findsOneWidget);
  });

  test('analysis state keeps selected knowledge references after success', () async {
    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '鎿嶄綔绯荤粺绗旇',
      type: 'markdown',
      content: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('鎿嶄綔绯荤粺 杩涚▼ 绾跨▼');

    final notifier = AiAnalysisNotifier();
    await notifier.runAnalysis(() async => '鍒嗘瀽缁撴灉', referenceContext: bundle);

    expect(notifier.state.result, '鍒嗘瀽缁撴灉');
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
      title: '鎿嶄綔绯荤粺绗旇',
      type: 'markdown',
      content: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('鎿嶄綔绯荤粺 杩涚▼ 绾跨▼');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiAnalysisResultCard(
              result: '寤鸿锛氫紭鍏堝涔犺繘绋嬪拰绾跨▼銆?,
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
      title: '鎿嶄綔绯荤粺绗旇',
      type: 'markdown',
      content: '''
# 杩涚▼绠＄悊

杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?
# 鍐呭瓨绠＄悊

鍒嗛〉鏈哄埗鎶婇€昏緫鍦板潃鍒嗘垚椤靛彿鍜岄〉鍐呭亸绉汇€?''',
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('鎿嶄綔绯荤粺 杩涚▼ 鍐呭瓨');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiAnalysisResultCard(
              result: '寤鸿浼樺厛澶嶄範杩涚▼鍜岀嚎绋嬪尯鍒€愮墖娈?1銆戙€?,
              referenceContext: bundle,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ai-analysis-citation-status')), findsOneWidget);
    expect(find.textContaining('宸插紩鐢細鐗囨 1'), findsOneWidget);
  });

  testWidgets('analysis result card warns when no local chunk citation is found', (
    tester,
  ) async {
    final repo = KnowledgeSourceRepository(db);
    await repo.importTextSource(
      title: '鎿嶄綔绯荤粺绗旇',
      type: 'markdown',
      content: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
    );
    final bundle = await KnowledgeContextService(
      repo,
    ).buildForQuery('鎿嶄綔绯荤粺 杩涚▼ 绾跨▼');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AiAnalysisResultCard(
              result: '寤鸿浼樺厛澶嶄範杩涚▼鍜岀嚎绋嬪尯鍒€?,
              referenceContext: bundle,
            ),
          ),
        ),
      ),
    );

    expect(find.text('鏈娴嬪埌鐗囨缂栧彿'), findsOneWidget);
  });
}

