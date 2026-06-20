import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_v3_repository.dart';

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
      title: '进程和线程区别',
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'user',
      content: '线程和进程有什么区别？',
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'assistant',
      content: '线程是 CPU 调度的基本单位，进程是资源分配的基本单位。',
    );

    final hits = await repo.searchQa(spaceId: space.id, query: '调度');

    expect(hits, hasLength(1));
    expect(hits.single.sessionId, sessionId);
    expect(hits.single.excerpt, contains('CPU 调度'));
  });

  test('reviewCard ratings create meaningfully different schedules', () async {
    final space = await repo.ensureDefaultSpace();
    final ids = <int>[];
    for (var i = 0; i < 4; i++) {
      ids.add(
        await repo.createCard(
          spaceId: space.id,
          question: '问题 $i',
          answer: '答案 $i',
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
      question: '第一张卡',
      answer: '答案 1',
    );
    final second = await repo.createCard(
      spaceId: space.id,
      question: '第二张卡',
      answer: '答案 2',
    );
    final third = await repo.createCard(
      spaceId: space.id,
      question: '第三张卡',
      answer: '答案 3',
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
      title: '网页资料',
      content: '行政处罚的追诉时效从违法行为发生之日起计算。',
      sourceType: 'web',
      url: 'https://example.com/article',
    );

    final material = await repo.getMaterial(id);

    expect(material, isNotNull);
    expect(material!.url, 'https://example.com/article');
  });

  test('rememberSpace moves a space to the front of the recent list', () async {
    final first = await repo.ensureDefaultSpace();
    final secondId = await repo.createSpace(name: '考公', type: 'exam');
    final thirdId = await repo.createSpace(name: '考研英语', type: 'language');

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
        title: '进程和线程区别',
      );
      await repo.addQaMessage(
        sessionId: sessionId,
        role: 'assistant',
        content: '第一条回答',
      );
      await repo.addQaMessage(
        sessionId: sessionId,
        role: 'user',
        content: '继续解释',
      );
      await repo.addQaMessage(
        sessionId: sessionId,
        role: 'assistant',
        content: '第二条回答',
      );

      await repo.markLatestAssistantMessageSavedAsCard(sessionId);

      final messages = await repo.getQaMessages(sessionId);
      expect(messages[0].savedAsCard, isFalse);
      expect(messages[1].savedAsCard, isFalse);
      expect(messages[2].savedAsCard, isTrue);
    },
  );
}
