import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_v3_repository.dart';

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

  test('searchQa finds Tiantian sessions and messages', () async {
    final space = await repo.ensureDefaultSpace();
    final sessionId = await repo.createQaSession(
      spaceId: space.id,
      title: '杩涚▼鍜岀嚎绋嬪尯鍒?,
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'user',
      content: '绾跨▼鍜岃繘绋嬫湁浠€涔堝尯鍒紵',
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'assistant',
      content: '绾跨▼鏄?CPU 璋冨害鐨勫熀鏈崟浣嶏紝杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅銆?,
    );

    final hits = await repo.searchQa(spaceId: space.id, query: '璋冨害');

    expect(hits, hasLength(1));
    expect(hits.single.sessionId, sessionId);
    expect(hits.single.excerpt, contains('CPU 璋冨害'));
  });

  test('getOrCreateSpaceSession reuses the latest space session', () async {
    final space = await repo.ensureDefaultSpace();

    final first = await repo.getOrCreateSpaceSession(space.id);
    final second = await repo.getOrCreateSpaceSession(space.id);

    expect(second.id, first.id);
    expect(second.spaceId, space.id);
    expect(second.title, '鐢滅敎闂瓟');
  });

  test(
    'updateSessionMaterials stores non-empty and empty selections',
    () async {
      final space = await repo.ensureDefaultSpace();
      final firstMaterialId = await repo.importMaterial(
        spaceId: space.id,
        title: '璧勬枡 A',
        content: 'A 鍐呭',
      );
      final secondMaterialId = await repo.importMaterial(
        spaceId: space.id,
        title: '璧勬枡 B',
        content: 'B 鍐呭',
      );
      final session = await repo.getOrCreateSpaceSession(space.id);

      await repo.updateSessionMaterials(session.id, [
        firstMaterialId,
        secondMaterialId,
      ]);
      final withMaterials = await repo.getQaSession(session.id);
      expect(
        withMaterials!.referencedMaterialIdsJson,
        '[$firstMaterialId,$secondMaterialId]',
      );

      await repo.updateSessionMaterials(session.id, const []);
      final emptyMaterials = await repo.getQaSession(session.id);
      expect(emptyMaterials!.referencedMaterialIdsJson, isNull);
    },
  );

  test('addQaMessage supports empty and selected sources', () async {
    final space = await repo.ensureDefaultSpace();
    final materialId = await repo.importMaterial(
      spaceId: space.id,
      title: '琛屾斂娉曠瑪璁?,
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
    );
    final material = await repo.getMaterial(materialId);
    final session = await repo.getOrCreateSpaceSession(space.id);

    await repo.addQaMessage(
      sessionId: session.id,
      role: 'user',
      content: '涓嶅甫璧勬枡鐨勯棶棰?,
    );
    await repo.addQaMessage(
      sessionId: session.id,
      role: 'user',
      content: '甯﹁祫鏂欑殑闂',
      sources: [material!],
    );

    final messages = await repo.getQaMessages(session.id);
    expect(messages, hasLength(2));
    expect(messages[0].sourcesJson, isNull);
    expect(messages[1].sourcesJson, contains('"id":$materialId'));
    expect(messages[1].sourcesJson, contains('"title":"琛屾斂娉曠瑪璁?'));
  });

  test('reviewCard ratings create meaningfully different schedules', () async {
    final space = await repo.ensureDefaultSpace();
    final ids = <int>[];
    for (var i = 0; i < 4; i++) {
      ids.add(
        await repo.createCard(
          spaceId: space.id,
          question: '闂 $i',
          answer: '绛旀 $i',
        ),
      );
    }

    final before = DateTime.now().millisecondsSinceEpoch;
    for (var rating = 0; rating < 4; rating++) {
      final card = await repo.getCard(ids[rating]);
      await repo.reviewCard(card: card!, rating: rating);
    }

    final reviewed = <KnowledgeCardV3>[];
    for (final id in ids) {
      reviewed.add((await repo.getCard(id))!);
    }

    final delays = reviewed
        .map((card) => card.dueAt - before)
        .toList(growable: false);
    expect(delays[0], lessThan(const Duration(hours: 1).inMilliseconds));
    expect(delays[1], greaterThan(const Duration(hours: 20).inMilliseconds));
    expect(delays[2], greaterThan(delays[1]));
    expect(delays[3], greaterThan(delays[2]));
    expect(reviewed[0].masteryLevel, 0);
    expect(reviewed[1].masteryLevel, 0);
    expect(reviewed[2].masteryLevel, 1);
    expect(reviewed[3].masteryLevel, 2);
  });

  test('reorderCard updates visible card order', () async {
    final space = await repo.ensureDefaultSpace();
    final first = await repo.createCard(
      spaceId: space.id,
      question: '绗竴寮犲崱',
      answer: '绛旀 1',
    );
    final second = await repo.createCard(
      spaceId: space.id,
      question: '绗簩寮犲崱',
      answer: '绛旀 2',
    );
    final third = await repo.createCard(
      spaceId: space.id,
      question: '绗笁寮犲崱',
      answer: '绛旀 3',
    );

    await repo.reorderCard(id: third, direction: -1);
    await repo.reorderCard(id: third, direction: -1);

    final cards = await repo.getCards(space.id);
    expect(cards.map((card) => card.id), [third, first, second]);
    expect(cards.first.orderIndex, 0);
  });

  test('importMaterial keeps web source url for traceability', () async {
    final space = await repo.ensureDefaultSpace();
    final id = await repo.importMaterial(
      spaceId: space.id,
      title: '缃戦〉璧勬枡',
      content: '琛屾斂澶勭綒鐨勮拷璇夋椂鏁堜粠杩濇硶琛屼负鍙戠敓涔嬫棩璧疯绠椼€?,
      sourceType: 'web',
      url: 'https://example.com/article',
    );

    final material = await repo.getMaterial(id);

    expect(material, isNotNull);
    expect(material!.url, 'https://example.com/article');
  });

  test('rememberSpace moves a space to the front of the recent list', () async {
    final first = await repo.ensureDefaultSpace();
    final secondId = await repo.createSpace(name: '鑰冨叕', type: 'exam');
    final thirdId = await repo.createSpace(name: '鑰冪爺鑻辫', type: 'language');

    await repo.rememberSpace(secondId);

    final spaces = await repo.getSpaces();
    expect(spaces.first.id, secondId);
    expect(spaces.map((space) => space.id), containsAll([first.id, thirdId]));
  });

  test(
    'markLatestAssistantMessageSavedAsCard updates latest assistant message',
    () async {
      final space = await repo.ensureDefaultSpace();
      final sessionId = await repo.createQaSession(
        spaceId: space.id,
        title: '杩涚▼鍜岀嚎绋嬪尯鍒?,
      );
      await repo.addQaMessage(
        sessionId: sessionId,
        role: 'assistant',
        content: '绗竴鏉″洖绛?,
      );
      await repo.addQaMessage(
        sessionId: sessionId,
        role: 'user',
        content: '缁х画瑙ｉ噴',
      );
      await repo.addQaMessage(
        sessionId: sessionId,
        role: 'assistant',
        content: '绗簩鏉″洖绛?,
      );

      await repo.markLatestAssistantMessageSavedAsCard(sessionId);

      final messages = await repo.getQaMessages(sessionId);
      expect(messages[0].savedAsCard, isFalse);
      expect(messages[1].savedAsCard, isFalse);
      expect(messages[2].savedAsCard, isTrue);
    },
  );

  test('archiveSpace hides space from default listing', () async {
    final space = await repo.ensureDefaultSpace();
    // Create a second space so getSpaces doesn't auto-create a new default
    await repo.createSpace(name: '澶囩敤绌洪棿');
    await repo.archiveSpace(space.id);

    final visible = await repo.getSpaces();
    expect(visible, hasLength(1));
    expect(visible.first.name, '澶囩敤绌洪棿');

    final all = await repo.getSpaces(includeArchived: true);
    expect(all, hasLength(2));
    expect(all.any((s) => s.id == space.id && s.isArchived), isTrue);
  });

  test('archiveMaterial hides material from space listing', () async {
    final space = await repo.ensureDefaultSpace();
    final id = await repo.importMaterial(
      spaceId: space.id,
      title: '璧勬枡',
      content: '鍐呭',
    );

    await repo.archiveMaterial(id);

    final materials = await repo.getMaterials(space.id);
    expect(materials, isEmpty);
  });

  test('archiveCard hides card from space listing', () async {
    final space = await repo.ensureDefaultSpace();
    final id = await repo.createCard(
      spaceId: space.id,
      question: '闂',
      answer: '绛旀',
    );

    await repo.archiveCard(id);

    final cards = await repo.getCards(space.id);
    expect(cards, isEmpty);
  });
}

