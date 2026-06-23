import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_v3_repository.dart';
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
        builder: (context, state) => const Scaffold(body: Text('AI 閰嶇疆')),
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

    expect(find.text('鐭ヨ瘑绌洪棿'), findsOneWidget);
    expect(find.text('閫夋嫨涓€涓┖闂达紝寮€濮嬩綘鐨勫涔犱箣鏃?), findsOneWidget);
    expect(find.text('榛樿鐭ヨ瘑绌洪棿'), findsWidgets);
    expect(find.text('AI 瀵煎叆'), findsNothing);
    expect(find.text('鍏ㄩ儴澶嶄範'), findsNothing);
    expect(find.text('鐩爣妯℃澘'), findsNothing);
  });

  testWidgets('space card enters the new workspace', (tester) async {
    await _pump(tester, db);

    await tester.tap(find.text('榛樿鐭ヨ瘑绌洪棿').first);
    await tester.pumpAndSettle();

    expect(find.text('浣犲ソ锛屾垜鏄敎鐢?), findsOneWidget);
    expect(find.text('鎼滅储鎴栭棶鐢滅敎杩欎釜绌洪棿閲岀殑璧勬枡...'), findsOneWidget);
    expect(find.text('闂敎鐢?), findsWidgets);
    expect(find.text('鍏堟斁杩涗竴浠藉涔犺祫鏂?), findsOneWidget);
  });

  testWidgets('space card actions use the system bottom action menu', (
    tester,
  ) async {
    await _pump(tester, db);

    await tester.tap(find.byTooltip('绌洪棿鎿嶄綔').first);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.text('榛樿鐭ヨ瘑绌洪棿'), findsWidgets);
    expect(find.text('閲嶅懡鍚?), findsOneWidget);
    expect(find.text('褰掓。'), findsOneWidget);
    expect(find.text('鍙栨秷'), findsOneWidget);
  });

  testWidgets('creating a space from selector enters it immediately', (
    tester,
  ) async {
    await _pump(tester, db);

    await tester.tap(find.widgetWithText(FilledButton, '鏂板缓绌洪棿'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '绌洪棿鍚嶇О'), '娉曡€?);
    await tester.tap(find.widgetWithText(FilledButton, '鍒涘缓骞惰繘鍏?));
    await tester.pumpAndSettle();

    expect(find.text('浣犲ソ锛屾垜鏄敎鐢?), findsOneWidget);
    expect(find.text('娉曡€?), findsWidgets);
    expect(find.text('閫夋嫨涓€涓┖闂达紝寮€濮嬩綘鐨勫涔犱箣鏃?), findsNothing);
  });

  testWidgets('import flow is one simple composer', (tester) async {
    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡').first);
    await tester.pumpAndSettle();

    expect(find.text('瀵煎叆璧勬枡'), findsWidgets);
    expect(find.text('瀵煎叆鍒扮┖闂?), findsOneWidget);
    expect(find.text('绮樿创鏂囨湰鎴栧唴瀹?), findsOneWidget);
    expect(find.text('鏇村璁剧疆'), findsNothing);
    expect(find.text('璧勬枡鏍囬锛堝彲閫夛級'), findsNothing);
    expect(find.text('鏂囦欢'), findsOneWidget);
    expect(find.text('缃戦〉'), findsOneWidget);
    expect(find.text('鍥剧墖'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);
    expect(find.textContaining('鍒囩墖'), findsNothing);
    expect(find.text('绋嶅悗澶勭悊'), findsNothing);

    final importButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '寮€濮嬪鍏?),
    );
    expect(importButton.onPressed, isNull);
  });

  testWidgets('web import uses the unified sheet style', (tester) async {
    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('缃戦〉'));
    await tester.pumpAndSettle();

    expect(find.text('瀵煎叆缃戦〉'), findsOneWidget);
    expect(find.text('鎶撳彇缃戦〉'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text import auto names material without asking for a title', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '绮樿创鏂囨湰鎴栧唴瀹?),
      '琛屾斂澶勭綒杩借瘔鏃舵晥\n閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );
    await tester.pump();
    final importButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '寮€濮嬪鍏?),
    );
    expect(importButton.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, '寮€濮嬪鍏?));
    await tester.pumpAndSettle();

    expect(find.text('璧勬枡宸插鍏ワ紝鍙敓鎴愮煡璇嗗崱'), findsOneWidget);
    final materials = await repo.getMaterials(space.id);
    expect(materials, hasLength(1));
    expect(materials.single.title, '琛屾斂澶勭綒杩借瘔鏃舵晥');
  });

  testWidgets('review page shows actionable empty state without crashing', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/review?spaceId=1');

    expect(find.text('杩樻病鏈夊彲澶嶄範鐨勭煡璇嗗崱'), findsOneWidget);
    expect(find.text('瀵煎叆璧勬枡'), findsWidgets);
    expect(find.text('鐢熸垚鐭ヨ瘑鍗?), findsWidgets);
    expect(find.textContaining('娓叉煋澶辫触'), findsNothing);
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

    await tester.tap(find.widgetWithText(FilledButton, '寮€濮嬫娊鍗?).first);
    await tester.pumpAndSettle();

    expect(find.text('閫夋嫨澶嶄範鏂瑰紡'), findsOneWidget);
    expect(find.text('浠婃棩鍒版湡'), findsOneWidget);
    expect(find.text('鍏ㄩ儴闅忔満'), findsOneWidget);
    expect(find.text('钖勫急浼樺厛'), findsNothing);
  });

  testWidgets('review completion shows a clear finish card', (tester) async {
    final space = await repo.ensureDefaultSpace();
    await repo.createCard(
      spaceId: space.id,
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥浠庝粈涔堟椂鍊欒捣绠楋紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=${space.id}',
    );

    await tester.tap(find.widgetWithText(FilledButton, '寮€濮嬫娊鍗?).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '缈诲紑绛旀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('鍩烘湰璁板緱'));
    await tester.pumpAndSettle();

    expect(find.text('鏈粍鎶藉崱瀹屾垚'), findsOneWidget);
    expect(find.text('鍒氬垰澶嶄範浜?1 寮犲崱銆傜敎鐢滃凡缁忔牴鎹綘鐨勫弽棣堝畨鎺掍笅娆″嚭鐜版椂闂淬€?), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '鍐嶆娊涓€缁?), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '鍥炲埌绌洪棿'), findsOneWidget);
  });

  testWidgets('review back returns to the same space when opened directly', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();
    final spaceId = await repo.createSpace(name: '鑰冨叕', type: 'exam');
    await repo.createCard(
      spaceId: spaceId,
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥浠庝粈涔堟椂鍊欒捣绠楋紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=$spaceId',
    );

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('浣犲ソ锛屾垜鏄敎鐢?), findsOneWidget);
    expect(find.text('鑰冨叕'), findsWidgets);
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

    await tester.tap(find.byTooltip('澶嶄範瑙勫垯'));
    await tester.pumpAndSettle();

    expect(find.text('澶嶄範瑙勫垯'), findsWidgets);
    expect(find.text('榛樿鎺掑簭'), findsOneWidget);
    expect(find.text('瀹屽叏蹇樹簡'), findsOneWidget);
    expect(find.text('寰堢啛缁?), findsOneWidget);
  });

  testWidgets(
    'ask Tiantian opens the space chat without requiring references',
    (tester) async {
      final space = await repo.ensureDefaultSpace();
      await repo.importMaterial(
        spaceId: space.id,
        title: '鎿嶄綔绯荤粺绗旇',
        content: '杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
      );

      await _pump(tester, db, location: '/plan/study/knowledge/space');

      await tester.tap(find.text('闂敎鐢?).last);
      await tester.pumpAndSettle();

      expect(find.byType(TiantianChatSheet), findsOneWidget);
      expect(find.text('鏈変粈涔堟兂闂敎鐢滅殑锛?), findsOneWidget);
      expect(find.text('鍙互鐩存帴鎻愰棶锛屼篃鍙互鐐瑰嚮鍙充笂瑙掗€夋嫨鍙傝€冭祫鏂?), findsOneWidget);
      expect(find.text('浣犳兂闂粈涔堬紵'), findsNothing);
      expect(find.text('纭骞舵彁闂?), findsNothing);

      await tester.tap(find.byIcon(Icons.library_books_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('閫夋嫨鍙傝€冭祫鏂?), findsOneWidget);
      expect(find.text('鎿嶄綔绯荤粺绗旇'), findsWidgets);
      expect(find.text('纭'), findsOneWidget);
    },
  );

  testWidgets('submitting a question in the ask box opens the space chat', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '琛屾斂娉曠瑪璁?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.enterText(find.byType(TextField).first, '琛屾斂澶勭綒杩借瘔鏃舵晥浠庝粈涔堟椂鍊欒捣绠楋紵');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byType(TiantianChatSheet), findsOneWidget);
    expect(find.text('琛屾斂澶勭綒杩借瘔鏃舵晥浠庝粈涔堟椂鍊欒捣绠楋紵'), findsOneWidget);
    expect(find.text('浣犳兂闂粈涔堬紵'), findsNothing);
    expect(find.text('纭骞舵彁闂?), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ask Tiantian opens for an empty space', (tester) async {
    await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.text('闂敎鐢?).last);
    await tester.pumpAndSettle();

    expect(find.byType(TiantianChatSheet), findsOneWidget);
    expect(find.text('鏈変粈涔堟兂闂敎鐢滅殑锛?), findsOneWidget);
    expect(find.widgetWithText(TextField, '闂敎鐢滀换浣曢棶棰?..'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace search result opens material detail', (tester) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '琛屾斂娉曡祫鏂?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.enterText(find.byType(TextField).first, '杩借瘔鏃舵晥');
    await tester.pumpAndSettle();

    expect(find.text('鎼滅储缁撴灉'), findsOneWidget);
    expect(find.text('琛屾斂娉曡祫鏂?), findsWidgets);
    await tester.tap(find.text('琛屾斂娉曡祫鏂?).last);
    await tester.pumpAndSettle();

    expect(find.text('璧勬枡璇︽儏'), findsOneWidget);
    expect(find.text('琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?), findsOneWidget);
  });

  testWidgets('summary quick action confirms references in one sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '琛屾斂娉曡祫鏂?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.ensureVisible(find.text('鎬荤粨璧勬枡').first);
    await tester.tap(find.text('鎬荤粨璧勬枡'));
    await tester.pumpAndSettle();

    expect(find.text('閫夋嫨瑕佹€荤粨鐨勮祫鏂?), findsOneWidget);
    expect(find.text('鍙戦€佸墠纭鍙傝€冭祫鏂欙紝鐢滅敎鍙細浣跨敤鍕鹃€夊唴瀹广€?), findsOneWidget);
    expect(find.text('琛屾斂娉曡祫鏂?), findsWidgets);
    expect(find.widgetWithText(FilledButton, '纭鎬荤粨 路 1 浠借祫鏂?), findsOneWidget);
    expect(find.text('纭鎬荤粨璧勬枡'), findsNothing);
  });

  testWidgets(
    'workspace avoids duplicate generate actions before cards exist',
    (tester) async {
      final space = await repo.ensureDefaultSpace();
      await repo.importMaterial(
        spaceId: space.id,
        title: '鍒戞硶璧勬枡',
        content: '鐘姜鏋勬垚鍖呭惈涓讳綋銆佷富瑙傛柟闈€佸浣撳拰瀹㈣鏂归潰銆?,
      );

      await _pump(tester, db, location: '/plan/study/knowledge/space');

      expect(find.widgetWithText(FilledButton, '鐢熸垚鐭ヨ瘑鍗?), findsOneWidget);
      expect(find.text('琛ュ厖鐭ヨ瘑鍗?), findsNothing);
    },
  );

  testWidgets(
    'generate flow without AI config gives an actionable setup entry',
    (tester) async {
      final space = await repo.ensureDefaultSpace();
      await repo.importMaterial(
        spaceId: space.id,
        title: '琛屾斂娉曡祫鏂?,
        content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
      );

      await _pump(tester, db, location: '/plan/study/knowledge/space');

      await tester.tap(find.widgetWithText(FilledButton, '鐢熸垚鐭ヨ瘑鍗?));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '纭鐢熸垚 路 1 浠借祫鏂?));
      await tester.pumpAndSettle();

      expect(find.text('杩樻病鏈夐厤缃?AI锛岃鍏堝湪璁剧疆閲屾坊鍔?API Key銆?), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '鍘婚厤缃?AI'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '鍘婚厤缃?AI'));
      await tester.pumpAndSettle();

      expect(find.text('AI 閰嶇疆'), findsOneWidget);
    },
  );

  testWidgets('workspace shows supplement card action only after cards exist', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '鍒戞硶璧勬枡',
      content: '鐘姜鏋勬垚鍖呭惈涓讳綋銆佷富瑙傛柟闈€佸浣撳拰瀹㈣鏂归潰銆?,
    );
    await repo.createCard(
      spaceId: space.id,
      question: '鐘姜鏋勬垚鍖呮嫭鍝簺鏂归潰锛?,
      answer: '涓讳綋銆佷富瑙傛柟闈€佸浣撳拰瀹㈣鏂归潰銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.text('鐢熸垚鐭ヨ瘑鍗?), findsWidgets);
    expect(find.text('鎬荤粨璧勬枡'), findsOneWidget);
  });

  testWidgets('importing into another space switches workspace to that space', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();
    await repo.createSpace(name: '鑰冨叕', type: 'exam', note: '鍏姟鍛樿€冭瘯澶囪€?);

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('鑰冨叕').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '绮樿创鏂囨湰鎴栧唴瀹?),
      '琛屾祴瑷€璇悊瑙ｉ渶瑕佸厛鎵句富棰樺彞锛屽啀鍒嗘瀽杞姌鍜岄€掕繘鍏崇郴銆?,
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '寮€濮嬪鍏?));
    await tester.pumpAndSettle();

    expect(find.text('璧勬枡宸插鍏ワ紝鍙敓鎴愮煡璇嗗崱'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '鍥炲埌绌洪棿'));
    await tester.pumpAndSettle();

    expect(find.text('鑰冨叕'), findsWidgets);
    final materials = await repo.getMaterials(2);
    expect(materials, hasLength(1));
    expect(materials.single.title, contains('琛屾祴瑷€璇悊瑙?));
  });

  testWidgets('import sheet can create a space without leaving the flow', (
    tester,
  ) async {
    await repo.ensureDefaultSpace();

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '绮樿创鏂囨湰鎴栧唴瀹?),
      '璧勬枡鍐呭浼氫繚鐣欙紝鍒涘缓绌洪棿鍚庣户缁鍏ャ€?,
    );
    await tester.tap(find.widgetWithText(TextButton, '鏂板缓绌洪棿'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '绌洪棿鍚嶇О'), '娉曡€?);
    await tester.tap(find.widgetWithText(FilledButton, '鍒涘缓骞惰繘鍏?));
    await tester.pumpAndSettle();

    expect(find.text('瀵煎叆璧勬枡'), findsWidgets);
    expect(find.text('娉曡€?), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '寮€濮嬪鍏?));
    await tester.pumpAndSettle();

    expect(find.text('璧勬枡宸插鍏ワ紝鍙敓鎴愮煡璇嗗崱'), findsOneWidget);
    final materials = await repo.getMaterials(2);
    expect(materials, hasLength(1));
    expect(materials.single.content, contains('璧勬枡鍐呭浼氫繚鐣?));
  });

  testWidgets('recent material row opens material detail directly', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '琛屾斂娉曡祫鏂?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.ensureVisible(find.text('琛屾斂娉曡祫鏂?).first);
    await tester.tap(find.text('琛屾斂娉曡祫鏂?).first);
    await tester.pumpAndSettle();

    expect(find.text('璧勬枡璇︽儏'), findsOneWidget);
    expect(find.text('琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?), findsOneWidget);
  });

  testWidgets('recent card row opens paper-style card detail sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.createCard(
      spaceId: space.id,
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
      explanation: '濡傛灉杩濇硶琛屼负鏈夎繛缁垨缁х画鐘舵€侊紝鍒欎粠琛屼负缁堜簡涔嬫棩璧疯绠椼€?,
      sourceTitle: '琛屾斂娉曡祫鏂?,
      sourceExcerpt: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('鐭ヨ瘑搴?));
    await tester.pumpAndSettle();
    await tester.tap(find.text('鐭ヨ瘑鍗?));
    await tester.pumpAndSettle();
    await tester.tap(find.text('琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵').first);
    await tester.pumpAndSettle();

    expect(find.text('鐭ヨ瘑鍗¤鎯?), findsOneWidget);
    expect(find.text('绛旀'), findsOneWidget);
    expect(find.text('鏉ユ簮鎽樺綍'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '缂栬緫'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '鍒犻櫎'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '鍏抽棴'), findsOneWidget);
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
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
      explanation: '濡傛灉杩濇硶琛屼负鏈夎繛缁垨缁х画鐘舵€侊紝鍒欎粠琛屼负缁堜簡涔嬫棩璧疯绠椼€?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('鐭ヨ瘑搴?));
    await tester.pumpAndSettle();
    await tester.tap(find.text('鐭ヨ瘑鍗?));
    await tester.pumpAndSettle();
    await tester.tap(find.text('琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵').first);
    await tester.pumpAndSettle();

    expect(find.text('鐭ヨ瘑鍗¤鎯?), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '鍏抽棴'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card detail delete asks for confirmation in a sheet', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    final cardId = await repo.createCard(
      spaceId: space.id,
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('鐭ヨ瘑搴?));
    await tester.pumpAndSettle();
    await tester.tap(find.text('鐭ヨ瘑鍗?));
    await tester.pumpAndSettle();
    await tester.tap(find.text('琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '鍒犻櫎'));
    await tester.pumpAndSettle();

    expect(find.text('鍒犻櫎鐭ヨ瘑鍗?), findsOneWidget);
    expect(find.text('杩欏紶鐭ヨ瘑鍗′細浠庡綋鍓嶇┖闂寸Щ闄わ紝澶嶄範璁板綍淇濈暀鍦ㄦ湰鍦版棩蹇椾腑銆?), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '鍙栨秷').last);
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
      title: '琛屾斂娉曡祫鏂?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );
    await repo.createCard(
      spaceId: space.id,
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');
    await tester.tap(find.byTooltip('鐭ヨ瘑搴?));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('璧勬枡鎿嶄綔').first);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.text('鏌ョ湅'), findsOneWidget);
    expect(find.text('缁紪'), findsOneWidget);
    expect(find.text('缂栬緫'), findsOneWidget);
    expect(find.text('鍒犻櫎'), findsOneWidget);
    expect(find.text('涓嬬Щ'), findsNothing);

    await tester.tap(find.text('鍙栨秷'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('鐭ヨ瘑鍗?));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('鐭ヨ瘑鍗℃搷浣?).first);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);
    expect(find.text('鐭ヨ瘑鍗℃搷浣?), findsWidgets);
    expect(find.text('鏌ョ湅'), findsOneWidget);
    expect(find.text('缂栬緫'), findsOneWidget);
    expect(find.text('鍒犻櫎'), findsOneWidget);
    expect(find.text('涓嬬Щ'), findsNothing);
  });

  testWidgets('library card tab offers generation instead of adding material', (
    tester,
  ) async {
    final space = await repo.ensureDefaultSpace();
    await repo.importMaterial(
      spaceId: space.id,
      title: '琛屾斂娉曡祫鏂?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.byTooltip('鐭ヨ瘑搴?));
    await tester.pumpAndSettle();
    expect(find.text('鐭ヨ瘑搴?), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '娣诲姞璧勬枡'), findsOneWidget);

    await tester.tap(find.text('鐭ヨ瘑鍗?));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '鐢熸垚鐭ヨ瘑鍗?), findsWidgets);
    expect(find.widgetWithText(FilledButton, '娣诲姞璧勬枡'), findsNothing);
  });

  testWidgets('workspace primary task adapts on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.text('鍏堟斁杩涗竴浠藉涔犺祫鏂?), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡'), findsOneWidget);
    expect(find.byTooltip('鐭ヨ瘑搴?), findsOneWidget);
    expect(find.text('鎶藉崱'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace top bar does not duplicate primary actions', (
    tester,
  ) async {
    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '瀵煎叆璧勬枡'), findsNothing);
    expect(find.widgetWithText(FilledButton, '寮€濮嬫娊鍗?), findsNothing);
    expect(find.byTooltip('鐭ヨ瘑搴?), findsOneWidget);
    expect(find.byTooltip('绠＄悊绌洪棿'), findsOneWidget);
  });

  testWidgets('import sheet stays usable on compact screens', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    await tester.tap(find.widgetWithText(FilledButton, '瀵煎叆璧勬枡').first);
    await tester.pumpAndSettle();

    expect(find.text('瀵煎叆璧勬枡'), findsWidgets);
    expect(find.text('绮樿创鏂囨湰鎴栧唴瀹?), findsOneWidget);
    expect(find.text('寮€濮嬪鍏?), findsOneWidget);
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
      title: '琛屾斂娉曡祫鏂?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆傝繛缁姸鎬佷粠琛屼负缁堜簡涔嬫棩璧疯绠椼€?,
    );
    await repo.createCard(
      spaceId: space.id,
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵',
      answer: '閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
      sourceTitle: '琛屾斂娉曡祫鏂?,
    );

    await _pump(tester, db, location: '/plan/study/knowledge/space');

    expect(find.text('浣犲ソ锛屾垜鏄敎鐢?), findsOneWidget);
    expect(find.text('鏈€杩戣祫鏂?), findsOneWidget);
    expect(find.text('鏈€杩戠煡璇嗗崱'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('鐭ヨ瘑搴?));
    await tester.pumpAndSettle();

    expect(find.text('鐭ヨ瘑搴?), findsOneWidget);
    expect(find.text('琛屾斂娉曡祫鏂?), findsWidgets);
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
      question: List.filled(8, '琛屾斂澶勭綒杩借瘔鏃舵晥鍦ㄨ繛缁繚娉曘€佺户缁繚娉曞拰涓€鑸繚娉曚箣闂村簲濡備綍鍒ゆ柇璧风畻鐐癸紵').join(' '),
      answer: List.filled(8, '涓€鑸繚娉曚粠杩濇硶琛屼负鍙戠敓涔嬫棩璧风畻锛涜繛缁垨缁х画鐘舵€佷粠琛屼负缁堜簡涔嬫棩璧风畻銆?).join(' '),
      explanation: List.filled(
        8,
        '澶嶄範鏃跺厛鍒ゆ柇杩濇硶琛屼负鏄惁宸茬粡缁堜簡锛屽啀鍒ゆ柇鏄惁瀛樺湪杩炵画鎴栫户缁姸鎬侊紝閬垮厤鏈烘濂楃敤鍙戠敓鏃ャ€?,
      ).join(' '),
      sourceTitle: '琛屾斂娉曡祫鏂?,
    );

    await _pump(
      tester,
      db,
      location: '/plan/study/knowledge/review?spaceId=${space.id}',
    );

    await tester.tap(find.widgetWithText(FilledButton, '寮€濮嬫娊鍗?).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('琛屾斂澶勭綒杩借瘔鏃舵晥'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '缈诲紑绛旀'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(FilledButton, '缈诲紑绛旀'));
    await tester.pumpAndSettle();

    expect(find.text('绛旀'), findsOneWidget);
    expect(find.text('瀹屽叏蹇樹簡'), findsOneWidget);
    expect(find.text('寰堢啛缁?), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}


