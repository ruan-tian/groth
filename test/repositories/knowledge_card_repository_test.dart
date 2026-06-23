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
  String title = '杩涚▼涓庣嚎绋?,
  String question = '杩涚▼鍜岀嚎绋嬫湁浠€涔堝尯鍒紵',
  String answer = '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
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
    subject: const Value('鎿嶄綔绯荤粺'),
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
    expect(queue.first.title, '杩涚▼涓庣嚎绋?);

    final goalQueue = await repo.getReviewQueue(
      goalKey: 'kaoyan_computer',
      moduleKey: 'operating_system',
    );
    expect(goalQueue, hasLength(1));
  });

  test('insertCards writes multiple cards in one batch', () async {
    await repo.insertCards([
      _card(title: '杩涚▼涓庣嚎绋?),
      _card(title: '鍐呭瓨鍒嗛〉', question: '鍒嗛〉鏈哄埗鏄粈涔堬紵', answer: '鎶婂唴瀛樺垝鍒嗕负鍥哄畾澶у皬鐨勯〉妗嗐€?),
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
        subject: '楂樻暟',
        title: '鏋侀檺',
        question: '鏋侀檺鐨勫畾涔夋槸浠€涔堬紵',
        answer: '鎻忚堪鍑芥暟瓒嬭繎鏌愮偣鏃剁殑鍙樺寲瓒嬪娍銆?,
        explanation: '淇濈暀澶嶄範杩涘害锛屽彧淇敼鍐呭銆?,
        tags: '["鏁板"]',
      );

      final updated = await repo.getCardById(id);
      expect(updated!.deckKey, 'math');
      expect(updated.goalKey, 'college');
      expect(updated.moduleKey, 'advanced_math');
      expect(updated.title, '鏋侀檺');
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
    final id = await repo.insertCard(_card(title: '鍙仮澶嶅崱鐗?));

    await repo.archiveCard(id);
    var archived = await repo.getArchivedCards();
    expect(archived, hasLength(1));
    expect(archived.single.title, '鍙仮澶嶅崱鐗?);
    expect(await repo.getAllCards(), isEmpty);

    await repo.restoreCard(id);
    archived = await repo.getArchivedCards();
    expect(archived, isEmpty);
    final active = await repo.getAllCards();
    expect(active, hasLength(1));
    expect(active.single.title, '鍙仮澶嶅崱鐗?);
  });

  test('archiveCards archives only selected cards', () async {
    final firstId = await repo.insertCard(_card(title: '鎵归噺鍗?A'));
    final secondId = await repo.insertCard(_card(title: '鎵归噺鍗?B'));
    final thirdId = await repo.insertCard(_card(title: '淇濈暀鍗?));

    await repo.archiveCards([firstId, secondId]);

    final active = await repo.getAllCards();
    expect(active, hasLength(1));
    expect(active.single.id, thirdId);

    final archived = await repo.getArchivedCards();
    expect(archived.map((card) => card.id), containsAll([firstId, secondId]));
  });

  test('updateCardsSubject edits selected cards only', () async {
    final firstId = await repo.insertCard(_card(title: '绔犺妭鍗?A'));
    final secondId = await repo.insertCard(_card(title: '绔犺妭鍗?B'));
    final untouchedId = await repo.insertCard(_card(title: '涓嶆敼鍗?));

    await repo.updateCardsSubject([firstId, secondId], '绗?3 绔?);

    final first = await repo.getCardById(firstId);
    final second = await repo.getCardById(secondId);
    final untouched = await repo.getCardById(untouchedId);
    expect(first!.subject, '绗?3 绔?);
    expect(second!.subject, '绗?3 绔?);
    expect(untouched!.subject, '鎿嶄綔绯荤粺');

    await repo.updateCardsSubject([firstId], null);
    expect((await repo.getCardById(firstId))!.subject, isNull);
    expect((await repo.getCardById(secondId))!.subject, '绗?3 绔?);
  });

  test(
    'moveCardsToModule updates target fields without resetting review',
    () async {
      final firstId = await repo.insertCard(_card(title: '绉诲姩鍗?A'));
      final secondId = await repo.insertCard(_card(title: '绉诲姩鍗?B'));
      final untouchedId = await repo.insertCard(_card(title: '鐣欏湪鍘熷'));
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
        goalName: '杞€冮珮绾?,
        moduleKey: 'custom',
        moduleName: '妗堜緥鍒嗘瀽',
        title: '妗堜緥棰樻柟娉?,
      ),
    );
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '杞€冮珮绾?,
        moduleKey: 'custom',
        moduleName: '璁烘枃鍐欎綔',
        title: '璁烘枃缁撴瀯',
      ),
    );

    final queue = await repo.getReviewQueue(
      goalKey: 'custom',
      goalName: '杞€冮珮绾?,
      moduleKey: 'custom',
      moduleName: '妗堜緥鍒嗘瀽',
    );

    expect(queue, hasLength(1));
    expect(queue.single.title, '妗堜緥棰樻柟娉?);
  });

  test(
    'weak cards queue returns low mastery or recently missed cards',
    () async {
      await repo.insertCard(
        _card(title: '浣庢帉鎻?, masteryLevel: 1, reviewCount: 2),
      );
      await repo.insertCard(
        _card(title: '鏈€杩戠瓟閿?, masteryLevel: 4, reviewCount: 3, correctStreak: 0),
      );
      await repo.insertCard(
        _card(title: '宸叉帉鎻?, masteryLevel: 4, reviewCount: 3, correctStreak: 3),
      );
      await repo.insertCard(
        _card(
          goalKey: 'college',
          moduleKey: 'advanced_math',
          title: '鍏朵粬鐩爣浣庢帉鎻?,
          masteryLevel: 1,
        ),
      );

      final weakCards = await repo.getWeakCards(
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
      );

      expect(weakCards.map((card) => card.title), contains('浣庢帉鎻?));
      expect(weakCards.map((card) => card.title), contains('鏈€杩戠瓟閿?));
      expect(weakCards.map((card) => card.title), isNot(contains('宸叉帉鎻?)));
      expect(weakCards.map((card) => card.title), isNot(contains('鍏朵粬鐩爣浣庢帉鎻?)));
    },
  );

  test('import scope filters existing cards by custom module name', () async {
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '杞€冮珮绾?,
        moduleKey: 'custom',
        moduleName: '妗堜緥鍒嗘瀽',
        title: '妗堜緥棰樻柟娉?,
      ),
    );
    await repo.insertCard(
      _card(
        goalKey: 'custom',
        goalName: '杞€冮珮绾?,
        moduleKey: 'custom',
        moduleName: '璁烘枃鍐欎綔',
        title: '璁烘枃缁撴瀯',
      ),
    );

    final cards = await repo.getCardsForImportScope(
      deckKey: 'computer',
      goalKey: 'custom',
      goalName: '杞€冮珮绾?,
      moduleKey: 'custom',
      moduleName: '妗堜緥鍒嗘瀽',
    );

    expect(cards, hasLength(1));
    expect(cards.single.title, '妗堜緥棰樻柟娉?);
  });

  test('custom templates and modules can be managed', () async {
    final templateId = await repo.createCustomTemplate(
      name: '杞€冮珮绾?,
      description: '妗堜緥鍒嗘瀽鍜岃鏂囧涔?,
    );
    final moduleId = await repo.createCustomTemplateModule(
      templateId: templateId,
      name: '妗堜緥鍒嗘瀽',
      deckKey: 'computer',
    );

    var bundles = await repo.getCustomTemplatesWithModules();
    expect(bundles, hasLength(1));
    expect(bundles.first.template.name, '杞€冮珮绾?);
    expect(bundles.first.modules.single.name, '妗堜緥鍒嗘瀽');
    expect(bundles.first.modules.single.deckKey, 'computer');

    await repo.updateCustomTemplateModule(
      id: moduleId,
      name: '璁烘枃鍐欎綔',
      deckKey: 'chinese_writing',
    );
    bundles = await repo.getCustomTemplatesWithModules();
    expect(bundles.first.modules.single.name, '璁烘枃鍐欎綔');
    expect(bundles.first.modules.single.deckKey, 'chinese_writing');

    await repo.archiveCustomTemplate(templateId);
    expect(await repo.getCustomTemplatesWithModules(), isEmpty);
  });
}

