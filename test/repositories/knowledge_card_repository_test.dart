import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_card_repository.dart';

KnowledgeCardsCompanion _card({
  String deckKey = 'computer',
  String goalKey = 'kaoyan_computer',
  String? goalName,
  String moduleKey = 'operating_system',
  String? moduleName,
  String title = '进程与线程',
  String question = '进程和线程有什么区别？',
  String answer = '进程是资源分配单位，线程是 CPU 调度单位。',
  int masteryLevel = 0,
  int reviewCount = 0,
  int correctStreak = 0,
  int? dueAt,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return KnowledgeCardsCompanion.insert(
    deckKey: Value(deckKey),
    goalKey: Value(goalKey),
    goalName: Value(goalName),
    moduleKey: Value(moduleKey),
    moduleName: Value(moduleName),
    subject: const Value('操作系统'),
    title: title,
    question: question,
    answer: answer,
    masteryLevel: Value(masteryLevel),
    reviewCount: Value(reviewCount),
    correctStreak: Value(correctStreak),
    dueAt: dueAt ?? now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late KnowledgeCardRepository repo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = KnowledgeCardRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('inserted card appears in due review queue', () async {
    final id = await repo.insertCard(_card());

    expect(id, greaterThan(0));
    expect(await repo.getTotalCount(), 1);
    expect(await repo.getDueCount(), 1);

    final queue = await repo.getReviewQueue(deckKey: 'computer');
    expect(queue, hasLength(1));
    expect(queue.first.title, '进程与线程');

    final goalQueue = await repo.getReviewQueue(
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
    );
    expect(goalQueue, hasLength(1));
  });

  test('insertCards writes multiple cards in one batch', () async {
    await repo.insertCards([
      _card(title: '进程与线程'),
      _card(title: '内存分页', question: '分页机制是什么？', answer: '把内存划分为固定大小的页框。'),
    ]);

    expect(await repo.getTotalCount(), 2);
    final queue = await repo.getReviewQueue(
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
    );
    expect(queue, hasLength(2));
  });

  test('reviewCard updates scheduling fields and writes a log', () async {
    final id = await repo.insertCard(_card());
    final card = await repo.getCardById(id);

    await repo.reviewCard(card: card!, quality: 3);

    final updated = await repo.getCardById(id);
    expect(updated!.masteryLevel, greaterThan(card.masteryLevel));
    expect(updated.reviewCount, 1);
    expect(updated.correctStreak, 1);
    expect(updated.lastReviewedAt, isNotNull);
    expect(updated.dueAt, greaterThan(DateTime.now().millisecondsSinceEpoch));

    final logs = await db.select(db.knowledgeReviewLogs).get();
    expect(logs, hasLength(1));
    expect(logs.first.cardId, id);
    expect(logs.first.quality, 3);
  });

  test(
    'updateCardContent edits text without resetting review progress',
    () async {
      final id = await repo.insertCard(_card());
      final card = await repo.getCardById(id);
      await repo.reviewCard(card: card!, quality: 2);
      final reviewed = await repo.getCardById(id);

      await repo.updateCardContent(
        id: id,
        deckKey: 'math',
        goalKey: 'college',
        moduleKey: 'advanced_math',
        subject: '高数',
        title: '极限',
        question: '极限的定义是什么？',
        answer: '描述函数趋近某点时的变化趋势。',
        explanation: '保留复习进度，只修改内容。',
        tags: '["数学"]',
      );

      final updated = await repo.getCardById(id);
      expect(updated!.deckKey, 'math');
      expect(updated.goalKey, 'college');
      expect(updated.moduleKey, 'advanced_math');
      expect(updated.title, '极限');
      expect(updated.reviewCount, reviewed!.reviewCount);
      expect(updated.masteryLevel, reviewed.masteryLevel);
      expect(updated.dueAt, reviewed.dueAt);
    },
  );

  test('archived card is hidden from counts and queues', () async {
    final id = await repo.insertCard(_card());

    await repo.archiveCard(id);

    expect(await repo.getTotalCount(), 0);
    expect(await repo.getDueCount(), 0);
    expect(await repo.getReviewQueue(deckKey: 'computer'), isEmpty);
  });

  test('archived card can be listed and restored', () async {
    final id = await repo.insertCard(_card(title: '可恢复卡片'));

    await repo.archiveCard(id);
    var archived = await repo.getArchivedCards();
    expect(archived, hasLength(1));
    expect(archived.single.title, '可恢复卡片');
    expect(await repo.getAllCards(), isEmpty);

    await repo.restoreCard(id);
    archived = await repo.getArchivedCards();
    expect(archived, isEmpty);
    final active = await repo.getAllCards();
    expect(active, hasLength(1));
    expect(active.single.title, '可恢复卡片');
  });

  test('archiveCards archives only selected cards', () async {
    final firstId = await repo.insertCard(_card(title: '批量卡 A'));
    final secondId = await repo.insertCard(_card(title: '批量卡 B'));
    final thirdId = await repo.insertCard(_card(title: '保留卡'));

    await repo.archiveCards([firstId, secondId]);

    final active = await repo.getAllCards();
    expect(active, hasLength(1));
    expect(active.single.id, thirdId);

    final archived = await repo.getArchivedCards();
    expect(archived.map((card) => card.id), containsAll([firstId, secondId]));
  });

  test('updateCardsSubject edits selected cards only', () async {
    final firstId = await repo.insertCard(_card(title: '章节卡 A'));
    final secondId = await repo.insertCard(_card(title: '章节卡 B'));
    final untouchedId = await repo.insertCard(_card(title: '不改卡'));

    await repo.updateCardsSubject([firstId, secondId], '第 3 章');

    final first = await repo.getCardById(firstId);
    final second = await repo.getCardById(secondId);
    final untouched = await repo.getCardById(untouchedId);
    expect(first!.subject, '第 3 章');
    expect(second!.subject, '第 3 章');
    expect(untouched!.subject, '操作系统');

    await repo.updateCardsSubject([firstId], null);
    expect((await repo.getCardById(firstId))!.subject, isNull);
    expect((await repo.getCardById(secondId))!.subject, '第 3 章');
  });

  test(
    'moveCardsToModule updates target fields without resetting review',
    () async {
      final firstId = await repo.insertCard(_card(title: '移动卡 A'));
      final secondId = await repo.insertCard(_card(title: '移动卡 B'));
      final untouchedId = await repo.insertCard(_card(title: '留在原处'));
      final first = await repo.getCardById(firstId);
      await repo.reviewCard(card: first!, quality: 2);
      final reviewed = await repo.getCardById(firstId);

      await repo.moveCardsToModule(
        [firstId, secondId],
        deckKey: 'math',
        goalKey: 'college',
        moduleKey: 'advanced_math',
      );

      final movedFirst = await repo.getCardById(firstId);
      final movedSecond = await repo.getCardById(secondId);
      final untouched = await repo.getCardById(untouchedId);
      expect(movedFirst!.deckKey, 'math');
      expect(movedFirst.goalKey, 'college');
      expect(movedFirst.goalName, isNull);
      expect(movedFirst.moduleKey, 'advanced_math');
      expect(movedFirst.moduleName, isNull);
      expect(movedFirst.reviewCount, reviewed!.reviewCount);
      expect(movedFirst.masteryLevel, reviewed.masteryLevel);
      expect(movedFirst.dueAt, reviewed.dueAt);
      expect(movedSecond!.goalKey, 'college');
      expect(untouched!.goalKey, 'kaoyan_computer');
    },
  );

  test('review queue can filter custom goal modules by module name', () async {
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '软考高级',
        moduleKey: 'custom',
        moduleName: '案例分析',
        title: '案例题方法',
      ),
    );
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '软考高级',
        moduleKey: 'custom',
        moduleName: '论文写作',
        title: '论文结构',
      ),
    );

    final queue = await repo.getReviewQueue(
      goalKey: 'custom',
      goalName: '软考高级',
      moduleKey: 'custom',
      moduleName: '案例分析',
    );

    expect(queue, hasLength(1));
    expect(queue.single.title, '案例题方法');
  });

  test(
    'weak cards queue returns low mastery or recently missed cards',
    () async {
      await repo.insertCard(
        _card(title: '低掌握', masteryLevel: 1, reviewCount: 2),
      );
      await repo.insertCard(
        _card(title: '最近答错', masteryLevel: 4, reviewCount: 3, correctStreak: 0),
      );
      await repo.insertCard(
        _card(title: '已掌握', masteryLevel: 4, reviewCount: 3, correctStreak: 3),
      );
      await repo.insertCard(
        _card(
          goalKey: 'college',
          moduleKey: 'advanced_math',
          title: '其他目标低掌握',
          masteryLevel: 1,
        ),
      );

      final weakCards = await repo.getWeakCards(
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
      );

      expect(weakCards.map((card) => card.title), contains('低掌握'));
      expect(weakCards.map((card) => card.title), contains('最近答错'));
      expect(weakCards.map((card) => card.title), isNot(contains('已掌握')));
      expect(weakCards.map((card) => card.title), isNot(contains('其他目标低掌握')));
    },
  );

  test('import scope filters existing cards by custom module name', () async {
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '软考高级',
        moduleKey: 'custom',
        moduleName: '案例分析',
        title: '案例题方法',
      ),
    );
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '软考高级',
        moduleKey: 'custom',
        moduleName: '论文写作',
        title: '论文结构',
      ),
    );

    final cards = await repo.getCardsForImportScope(
      deckKey: 'computer',
      goalKey: 'custom',
      goalName: '软考高级',
      moduleKey: 'custom',
      moduleName: '案例分析',
    );

    expect(cards, hasLength(1));
    expect(cards.single.title, '案例题方法');
  });

  test('custom templates and modules can be managed', () async {
    final templateId = await repo.createCustomTemplate(
      name: '软考高级',
      description: '案例分析和论文复习',
    );
    final moduleId = await repo.createCustomTemplateModule(
      templateId: templateId,
      name: '案例分析',
      deckKey: 'computer',
    );

    var bundles = await repo.getCustomTemplatesWithModules();
    expect(bundles, hasLength(1));
    expect(bundles.first.template.name, '软考高级');
    expect(bundles.first.modules.single.name, '案例分析');
    expect(bundles.first.modules.single.deckKey, 'computer');

    await repo.updateCustomTemplateModule(
      id: moduleId,
      name: '论文写作',
      deckKey: 'chinese_writing',
    );
    bundles = await repo.getCustomTemplatesWithModules();
    expect(bundles.first.modules.single.name, '论文写作');
    expect(bundles.first.modules.single.deckKey, 'chinese_writing');

    await repo.archiveCustomTemplate(templateId);
    expect(await repo.getCustomTemplatesWithModules(), isEmpty);
  });
}
