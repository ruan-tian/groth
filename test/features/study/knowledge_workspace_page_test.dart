import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_v3_repository.dart';
import 'package:growth_os/features/study/pages/knowledge_workspace_page.dart';
import 'package:growth_os/features/study/widgets/tiantian_chat_sheet.dart';
import 'package:growth_os/shared/providers/database_provider.dart';

Widget _buildPage(
  AppDatabase db, {
  String initialLocation = '/plan/study/flash-review',
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/plan/study/flash-review',
        builder: (context, state) => const KnowledgeSpaceSelectPage(),
      ),
      GoRoute(
        path: '/plan/study/knowledge',
        builder: (context, state) => const KnowledgeSpaceSelectPage(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/space',
        builder: (context, state) => const KnowledgeWorkspacePage(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/spaces',
        builder: (context, state) => const KnowledgeSpaceSelectPage(),
      ),
      GoRoute(
        path: '/plan/study/knowledge/review',
        builder: (context, state) => KnowledgeFlashReviewPage(
          spaceId:
              int.tryParse(state.uri.queryParameters['spaceId'] ?? '') ?? 1,
        ),
      ),
      GoRoute(
        path: '/ai-config',
        builder: (context, state) => const Scaffold(body: Text('AI 配置')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db, {
  String? location,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    _buildPage(
      db,
      initialLocation: location ?? '/plan/study/flash-review',
      overrides: overrides,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late KnowledgeV3Repository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = KnowledgeV3Repository(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('flash review route opens the space selector first', (
    tester,
  ) async {
    await _pump(tester, db);

    expect(find.text('知识空间'), findsOneWidget);
    expect(find.text('选择一个空间，开始你的学习之旅'), findsOneWidget);
    expect(find.text('默认知识空间'), findsWidgets);
    expect(find.text('AI 导入'), findsNothing);
    expect(find.text('全部复习'), findsNothing);
    expect(find.text('目标模板'), findsNothing);
  });

  testWidgets('space card enters the new workspace', (tester) async {
    await _pump(tester, db);

    await tester.tap(find.text('默认知识空间').first);
    await tester.pumpAndSettle();

    expect(find.text('你好，我是甜甜'), findsOneWidget);
    expect(find.text('搜索或问甜甜这个空间里的资料...'), findsOneWidget);
    expect(find.text('问甜甜'), findsWidgets);
    expect(find.text('先放进一份学习资料'), findsOneWidget);
  });

  testWidgets('space card actions use the system bottom action menu', (
    tester,
  ) async {
    await _pump(tester, db);

    await tester.tap(find.byTooltip('空间操作').first);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.text('默认知识空间'), findsWidgets);
    expect(find.text('重命名'), findsOneWidget);
    expect(find.text('归档'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('creating a space from selector enters it immediately', (
    tester,
  ) async {
    await _pump(tester, db);

    await tester.tap(find.widgetWithText(FilledButton, '新建空间'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '空间名称'), '法考');
    await tester.tap(find.widgetWithText(FilledButton, '创建并进入'));
    await tester.pumpAndSettle();

    expect(find.text('你好，我是甜甜'), findsOneWidget);
    expect(find.text('法考'), findsWidgets);
    expect(find.text('选择一个空间，开始你的学习之旅'), findsNothing);
  });

  testWidgets('import flow is one simple composer', (tester) async {
    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '导入资料').first);
    await tester.pumpAndSettle();

    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('导入到空间'), findsOneWidget);
    expect(find.text('粘贴文本或内容'), findsOneWidget);
    expect(find.text('更多设置'), findsNothing);
    expect(find.text('资料标题（可选）'), findsNothing);
    expect(find.text('文件'), findsOneWidget);
    expect(find.text('网页'), findsOneWidget);
    expect(find.text('图片'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);
    expect(find.textContaining('切片'), findsNothing);
    expect(find.text('稍后处理'), findsNothing);

    final importButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始导入'),
    );
    expect(importButton.onPressed, isNull);
  });

  testWidgets('web import uses the unified sheet style', (tester) async {
    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '导入资料').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('网页'));
    await tester.pumpAndSettle();

    expect(find.text('导入网页'), findsOneWidget);
    expect(find.text('抓取网页'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text import auto names material without asking for a title', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '导入资料').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '粘贴文本或内容'),
      '行政处罚追诉时效\n通常从违法行为发生之日起计算。',
    );
    await tester.pump();
    final importButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始导入'),
    );
    expect(importButton.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, '开始导入'));
    await tester.pumpAndSettle();

    expect(find.text('资料已导入，可生成知识卡'), findsOneWidget);
    final materials = await repo.getMaterials(space.id);
    expect(materials, hasLength(1));
    expect(materials.single.title, '行政处罚追诉时效');
  });

  testWidgets('review page shows actionable empty state without crashing', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/review?spaceId=1');

    expect(find.text('还没有可复习的知识卡'), findsOneWidget);
    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('生成知识卡'), findsWidgets);
    expect(find.textContaining('渲染失败'), findsNothing);
  });

  testWidgets('review mode hides weak option when there are no weak cards', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    final firstId = await repo.createCard(
      spaceId: space.id,
      question: 'What is a process?',
      answer: 'A process owns resources.',
    );
    final secondId = await repo.createCard(
      spaceId: space.id,
      question: 'What is a thread?',
      answer: 'A thread is the scheduling unit.',
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final id in [firstId, secondId]) {
      await db.customUpdate(
        '''
        UPDATE knowledge_cards_v3
        SET mastery_level = 5, review_count = 2, correct_streak = 2, due_at = ?
        WHERE id = ?
        ''',
        variables: [Variable<int>(now), Variable<int>(id)],
      );
    }

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=${space.id}',
    );

    await tester.tap(find.widgetWithText(FilledButton, '开始抽卡').first);
    await tester.pumpAndSettle();

    expect(find.text('选择复习方式'), findsOneWidget);
    expect(find.text('今日到期'), findsOneWidget);
    expect(find.text('全部随机'), findsOneWidget);
    expect(find.text('薄弱优先'), findsNothing);
  });

  testWidgets('review completion shows a clear finish card', (tester) async {
    final space = await repo.ensureDefaultSpace();
    await repo.createCard(
      spaceId: space.id,
      question: '行政处罚追诉时效从什么时候起算？',
      answer: '通常从违法行为发生之日起计算。',
    );

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=${space.id}',
    );

    await tester.tap(find.widgetWithText(FilledButton, '开始抽卡').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '翻开答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('基本记得'));
    await tester.pumpAndSettle();

    expect(find.text('本组抽卡完成'), findsOneWidget);
    expect(find.text('刚刚复习了 1 张卡。甜甜已经根据你的反馈安排下次出现时间。'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '再抽一组'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '回到空间'), findsOneWidget);
  });

  testWidgets('review back returns to the same space when opened directly', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();
    final spaceId = await repo.createSpace(name: '考公', type: 'exam');
    await repo.createCard(
      spaceId: spaceId,
      question: '行政处罚追诉时效从什么时候起算？',
      answer: '通常从违法行为发生之日起计算。',
    );

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=$spaceId',
    );

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('你好，我是甜甜'), findsOneWidget);
    expect(find.text('考公'), findsWidgets);
  });

  testWidgets('review settings opens the scheduling rule sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=${space.id}',
    );

    await tester.tap(find.byTooltip('复习规则'));
    await tester.pumpAndSettle();

    expect(find.text('复习规则'), findsWidgets);
    expect(find.text('默认排序'), findsOneWidget);
    expect(find.text('完全忘了'), findsOneWidget);
    expect(find.text('很熟练'), findsOneWidget);
  });

  testWidgets(
    'ask Tiantian opens the space chat without requiring references',
    (tester) async {
      final space = await repo.ensureDefaultSpace();
      await repo.importMaterial(
        spaceId: space.id,
        title: '操作系统笔记',
        content: '进程是资源分配的基本单位，线程是 CPU 调度的基本单位。',
      );

      await _pump(tester, db, location: '/plan/study/knowledge/space');

      await tester.tap(find.text('问甜甜').last);
      await tester.pumpAndSettle();

      expect(find.byType(TiantianChatSheet), findsOneWidget);
      expect(find.text('有什么想问甜甜的？'), findsOneWidget);
      expect(find.text('可以直接提问，也可以点击右上角选择参考资料'), findsOneWidget);
      expect(find.text('你想问什么？'), findsNothing);
      expect(find.text('确认并提问'), findsNothing);

      await tester.tap(find.byIcon(Icons.library_books_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('选择参考资料'), findsOneWidget);
      expect(find.text('操作系统笔记'), findsWidgets);
      expect(find.text('确认'), findsOneWidget);
    },
  );

  testWidgets('submitting a question in the ask box opens the space chat', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法笔记',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.enterText(find.byType(TextField).first, '行政处罚追诉时效从什么时候起算？');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byType(TiantianChatSheet), findsOneWidget);
    expect(find.text('行政处罚追诉时效从什么时候起算？'), findsOneWidget);
    expect(find.text('你想问什么？'), findsNothing);
    expect(find.text('确认并提问'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ask Tiantian opens for an empty space', (tester) async {
    await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.text('问甜甜').last);
    await tester.pumpAndSettle();

    expect(find.byType(TiantianChatSheet), findsOneWidget);
    expect(find.text('有什么想问甜甜的？'), findsOneWidget);
    expect(find.widgetWithText(TextField, '问甜甜任何问题...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace search result opens material detail', (tester) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.enterText(find.byType(TextField).first, '追诉时效');
    await tester.pumpAndSettle();

    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.text('行政法资料'), findsWidgets);
    await tester.tap(find.text('行政法资料').last);
    await tester.pumpAndSettle();

    expect(find.text('资料详情'), findsOneWidget);
    expect(find.text('行政处罚追诉时效通常从违法行为发生之日起计算。'), findsOneWidget);
  });

  testWidgets('summary quick action confirms references in one sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.ensureVisible(find.text('总结资料').first);
    await tester.tap(find.text('总结资料'));
    await tester.pumpAndSettle();

    expect(find.text('选择要总结的资料'), findsOneWidget);
    expect(find.text('发送前确认参考资料，甜甜只会使用勾选内容。'), findsOneWidget);
    expect(find.text('行政法资料'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '确认总结 · 1 份资料'), findsOneWidget);
    expect(find.text('确认总结资料'), findsNothing);
  });

  testWidgets(
    'workspace avoids duplicate generate actions before cards exist',
    (tester) async {
      final space = await repo.ensureDefaultSpace();
      await repo.importMaterial(
        spaceId: space.id,
        title: '刑法资料',
        content: '犯罪构成包含主体、主观方面、客体和客观方面。',
      );

      await _pump(tester, db, location: '/plan/study/knowledge/space');

      expect(find.widgetWithText(FilledButton, '生成知识卡'), findsOneWidget);
      expect(find.text('补充知识卡'), findsNothing);
    },
  );

  testWidgets(
    'generate flow without AI config gives an actionable setup entry',
    (tester) async {
      final space = await repo.ensureDefaultSpace();
      await repo.importMaterial(
        spaceId: space.id,
        title: '行政法资料',
        content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
      );

      await _pump(tester, db, location: '/plan/study/knowledge/space');

      await tester.tap(find.widgetWithText(FilledButton, '生成知识卡'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认生成 · 1 份资料'));
      await tester.pumpAndSettle();

      expect(find.text('还没有配置 AI，请先在设置里添加 API Key。'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '去配置 AI'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '去配置 AI'));
      await tester.pumpAndSettle();

      expect(find.text('AI 配置'), findsOneWidget);
    },
  );

  testWidgets('workspace shows supplement card action only after cards exist', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '刑法资料',
      content: '犯罪构成包含主体、主观方面、客体和客观方面。',
    );
    await repo.createCard(
      spaceId: space.id,
      question: '犯罪构成包括哪些方面？',
      answer: '主体、主观方面、客体和客观方面。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.text('生成知识卡'), findsWidgets);
    expect(find.text('总结资料'), findsOneWidget);
  });

  testWidgets('importing into another space switches workspace to that space', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();
    await repo.createSpace(name: '考公', type: 'exam', note: '公务员考试备考');

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '导入资料').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('考公').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '粘贴文本或内容'),
      '行测言语理解需要先找主题句，再分析转折和递进关系。',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '开始导入'));
    await tester.pumpAndSettle();

    expect(find.text('资料已导入，可生成知识卡'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '回到空间'));
    await tester.pumpAndSettle();

    expect(find.text('考公'), findsWidgets);
    final materials = await repo.getMaterials(2);
    expect(materials, hasLength(1));
    expect(materials.single.title, contains('行测言语理解'));
  });

  testWidgets('import sheet can create a space without leaving the flow', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '导入资料').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '粘贴文本或内容'),
      '资料内容会保留，创建空间后继续导入。',
    );
    await tester.tap(find.widgetWithText(TextButton, '新建空间'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '空间名称'), '法考');
    await tester.tap(find.widgetWithText(FilledButton, '创建并进入'));
    await tester.pumpAndSettle();

    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('法考'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '开始导入'));
    await tester.pumpAndSettle();

    expect(find.text('资料已导入，可生成知识卡'), findsOneWidget);
    final materials = await repo.getMaterials(2);
    expect(materials, hasLength(1));
    expect(materials.single.content, contains('资料内容会保留'));
  });

  testWidgets('recent material row opens material detail directly', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.ensureVisible(find.text('行政法资料').first);
    await tester.tap(find.text('行政法资料').first);
    await tester.pumpAndSettle();

    expect(find.text('资料详情'), findsOneWidget);
    expect(find.text('行政处罚追诉时效通常从违法行为发生之日起计算。'), findsOneWidget);
  });

  testWidgets('recent card row opens paper-style card detail sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.createCard(
      spaceId: space.id,
      question: '行政处罚追诉时效的一般起算点是什么？',
      answer: '通常从违法行为发生之日起计算。',
      explanation: '如果违法行为有连续或继续状态，则从行为终了之日起计算。',
      sourceTitle: '行政法资料',
      sourceExcerpt: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('知识库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('知识卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('行政处罚追诉时效的一般起算点是什么？').first);
    await tester.pumpAndSettle();

    expect(find.text('知识卡详情'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('来源摘录'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '编辑'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '删除'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '关闭'), findsOneWidget);
  });

  testWidgets('card detail sheet stays usable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final space = await repo.ensureDefaultSpace();
    await repo.createCard(
      spaceId: space.id,
      question: '行政处罚追诉时效的一般起算点是什么？',
      answer: '通常从违法行为发生之日起计算。',
      explanation: '如果违法行为有连续或继续状态，则从行为终了之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('知识库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('知识卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('行政处罚追诉时效的一般起算点是什么？').first);
    await tester.pumpAndSettle();

    expect(find.text('知识卡详情'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '关闭'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card detail delete asks for confirmation in a sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    final cardId = await repo.createCard(
      spaceId: space.id,
      question: '行政处罚追诉时效的一般起算点是什么？',
      answer: '通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('知识库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('知识卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('行政处罚追诉时效的一般起算点是什么？').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除知识卡'), findsOneWidget);
    expect(find.text('这张知识卡会从当前空间移除，复习记录保留在本地日志中。'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '取消').last);
    await tester.pumpAndSettle();

    final card = await repo.getCard(cardId);
    expect(card?.isArchived, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library item actions use the system bottom action menu', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );
    await repo.createCard(
      spaceId: space.id,
      question: '行政处罚追诉时效的一般起算点是什么？',
      answer: '通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');
    await tester.tap(find.byTooltip('知识库'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('资料操作').first);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.text('查看'), findsOneWidget);
    expect(find.text('续编'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('下移'), findsNothing);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('知识卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('知识卡操作').first);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.text('知识卡操作'), findsWidgets);
    expect(find.text('查看'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('下移'), findsNothing);
  });

  testWidgets('library card tab offers generation instead of adding material', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('知识库'));
    await tester.pumpAndSettle();
    expect(find.text('知识库'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '添加资料'), findsOneWidget);

    await tester.tap(find.text('知识卡'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '生成知识卡'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '添加资料'), findsNothing);
  });

  testWidgets('workspace primary task adapts on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.text('先放进一份学习资料'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '导入资料'), findsOneWidget);
    expect(find.byTooltip('知识库'), findsOneWidget);
    expect(find.text('抽卡'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace top bar does not duplicate primary actions', (
    tester,
  ) async {
    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.widgetWithText(FilledButton, '导入资料'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '导入资料'), findsNothing);
    expect(find.widgetWithText(FilledButton, '开始抽卡'), findsNothing);
    expect(find.byTooltip('知识库'), findsOneWidget);
    expect(find.byTooltip('管理空间'), findsOneWidget);
  });

  testWidgets('import sheet stays usable on compact screens', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '导入资料').first);
    await tester.pumpAndSettle();

    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('粘贴文本或内容'), findsOneWidget);
    expect(find.text('开始导入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace and library stay stable on desktop width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '行政法资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算。连续状态从行为终了之日起计算。',
    );
    await repo.createCard(
      spaceId: space.id,
      question: '行政处罚追诉时效的一般起算点是什么？',
      answer: '通常从违法行为发生之日起计算。',
      sourceTitle: '行政法资料',
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.text('你好，我是甜甜'), findsOneWidget);
    expect(find.text('最近资料'), findsOneWidget);
    expect(find.text('最近知识卡'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('知识库'));
    await tester.pumpAndSettle();

    expect(find.text('知识库'), findsOneWidget);
    expect(find.text('行政法资料'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long review card content stays scrollable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final space = await repo.ensureDefaultSpace();
    await repo.createCard(
      spaceId: space.id,
      question: List.filled(8, '行政处罚追诉时效在连续违法、继续违法和一般违法之间应如何判断起算点？').join(' '),
      answer: List.filled(8, '一般违法从违法行为发生之日起算；连续或继续状态从行为终了之日起算。').join(' '),
      explanation: List.filled(
        8,
        '复习时先判断违法行为是否已经终了，再判断是否存在连续或继续状态，避免机械套用发生日。',
      ).join(' '),
      sourceTitle: '行政法资料',
    );

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=${space.id}',
    );

    await tester.tap(find.widgetWithText(FilledButton, '开始抽卡').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('行政处罚追诉时效'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '翻开答案'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(FilledButton, '翻开答案'));
    await tester.pumpAndSettle();

    expect(find.text('答案'), findsOneWidget);
    expect(find.text('完全忘了'), findsOneWidget);
    expect(find.text('很熟练'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
