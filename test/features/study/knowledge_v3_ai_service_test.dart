import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/ai_config_repository.dart';
import 'package:growth_os/core/repositories/knowledge_v3_repository.dart';
import 'package:growth_os/core/services/ai_service.dart';
import 'package:growth_os/core/services/encryption_service.dart';
import 'package:growth_os/features/knowledge/services/knowledge_v3_ai_service.dart';

class _SequenceAiService extends AiService {
  _SequenceAiService(this.responses);

  final List<String> responses;
  final prompts = <String>[];
  int calls = 0;

  @override
  Future<String> callApi({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    prompts.add(userPrompt);
    final index = calls++;
    if (index >= responses.length) return responses.last;
    return responses[index];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('card draft parser accepts fenced JSON', () {
    final drafts = KnowledgeV3CardDraftParser.parseSafely('''
```json
{
  "cards": [
    {
      "question": "线程和进程在操作系统中的核心区别是什么？",
      "answer": "进程是资源分配的基本单位，线程是 CPU 调度的基本单位。",
      "explanation": "区分二者时先看资源归属，再看调度执行。",
      "cardType": "comparison",
      "importance": 5,
      "difficulty": 3,
      "sourceExcerpt": "进程是资源分配的基本单位，线程是 CPU 调度的基本单位。",
      "tags": ["操作系统"]
    }
  ]
}
```
''');

    expect(drafts, hasLength(1));
    expect(drafts.single.question, contains('线程和进程'));
    expect(KnowledgeV3CardDraftParser.isHighQuality(drafts.single), isTrue);
  });

  test('card draft parser turns truncated JSON into friendly exception', () {
    expect(
      () => KnowledgeV3CardDraftParser.parseSafely('{"cards": ['),
      throwsA(
        isA<KnowledgeV3AiException>().having(
          (error) => error.message,
          'message',
          contains('AI 输出不完整'),
        ),
      ),
    );
  });

  test('quality filter rejects prompt-like useless cards', () {
    const draft = KnowledgeV3CardDraft(
      question: '请总结这个空间',
      answer: '这是资料总结。',
      explanation: '无',
      cardType: 'recall',
      importance: 1,
      difficulty: 1,
      sourceExcerpt: '总结资料',
    );

    expect(KnowledgeV3CardDraftParser.isHighQuality(draft), isFalse);
  });

  test('quality filter rejects cards without grounded source excerpt', () {
    const draft = KnowledgeV3CardDraft(
      question: '行政处罚追诉时效通常从什么时候起算？',
      answer: '从违法行为发生之日起计算；违法行为有连续或者继续状态的，从行为终了之日起计算。',
      explanation: '这类卡片要能回忆起起算点和连续状态例外。',
      cardType: 'recall',
      importance: 4,
      difficulty: 3,
    );

    expect(KnowledgeV3CardDraftParser.isHighQuality(draft), isFalse);
  });

  test(
    'quality filter rejects outline headings and answers too short to review',
    () {
      const headingDraft = KnowledgeV3CardDraft(
        question: '一、行政处罚追诉时效',
        answer: '行政处罚追诉时效通常从违法行为发生之日起计算。',
        explanation: '标题不能直接作为抽卡问题。',
        cardType: 'recall',
        importance: 4,
        difficulty: 2,
        sourceExcerpt: '行政处罚追诉时效通常从违法行为发生之日起计算。',
      );
      const shortAnswerDraft = KnowledgeV3CardDraft(
        question: '行政处罚追诉时效的一般起算点是什么？',
        answer: '发生日',
        explanation: '答案太短，缺少可独立复习的信息。',
        cardType: 'recall',
        importance: 4,
        difficulty: 2,
        sourceExcerpt: '行政处罚追诉时效通常从违法行为发生之日起计算。',
      );

      expect(KnowledgeV3CardDraftParser.isHighQuality(headingDraft), isFalse);
      expect(
        KnowledgeV3CardDraftParser.isHighQuality(shortAnswerDraft),
        isFalse,
      );
    },
  );

  test('generation plan scales with material density', () {
    const sparse = KnowledgeMaterial(
      id: 1,
      spaceId: 1,
      title: '短资料',
      content: '进程是资源分配的基本单位。',
      sourceType: 'text',
      orderIndex: 0,
      status: 'ready',
      isArchived: false,
      createdAt: 1,
      updatedAt: 1,
    );
    final denseText = List.generate(
      30,
      (index) => '${index + 1}. 行政处罚规则 $index：包含条件、例外和易错点？',
    ).join('\n');
    final dense = KnowledgeMaterial(
      id: 2,
      spaceId: 1,
      title: '密集资料',
      content: denseText,
      sourceType: 'text',
      orderIndex: 1,
      status: 'ready',
      isArchived: false,
      createdAt: 1,
      updatedAt: 1,
    );

    final sparsePlan = KnowledgeV3GenerationPlan.fromMaterial(sparse, 1);
    final densePlan = KnowledgeV3GenerationPlan.fromMaterial(dense, 3);

    expect(sparsePlan.totalTarget, greaterThanOrEqualTo(4));
    expect(densePlan.totalTarget, greaterThan(sparsePlan.totalTarget));
    expect(densePlan.targetForPart(0), greaterThanOrEqualTo(3));
  });

  test(
    'generation plan scales for very dense materials and backfills earlier',
    () {
      final denseText = List.generate(
        100,
        (index) => '${index + 1}. 高频考点 $index：包含适用条件、例外、判断依据和常见误区？',
      ).join('\n');
      final material = KnowledgeMaterial(
        id: 3,
        spaceId: 1,
        title: '百题考点清单',
        content: denseText,
        sourceType: 'text',
        orderIndex: 1,
        status: 'ready',
        isArchived: false,
        createdAt: 1,
        updatedAt: 1,
      );

      final plan = KnowledgeV3GenerationPlan.fromMaterial(material, 5);

      expect(plan.totalTarget, greaterThanOrEqualTo(90));
      expect(plan.targetForPart(0), greaterThanOrEqualTo(18));
      expect(plan.shouldBackfill(50), isTrue);
      expect(plan.backfillTarget(50), greaterThanOrEqualTo(24));
    },
  );

  test('Tiantian answer prompt includes recent conversation history', () {
    const space = KnowledgeSpaceV3(
      id: 1,
      name: '操作系统',
      type: 'exam',
      sortOrder: 0,
      isArchived: false,
      createdAt: 1,
      updatedAt: 1,
    );
    const material = KnowledgeMaterial(
      id: 7,
      spaceId: 1,
      title: '进程线程笔记',
      content: '进程是资源分配的基本单位，线程是 CPU 调度的基本单位。',
      sourceType: 'text',
      orderIndex: 0,
      status: 'ready',
      isArchived: false,
      createdAt: 1,
      updatedAt: 1,
    );
    const history = [
      TiantianQaMessage(
        id: 1,
        sessionId: 3,
        role: 'user',
        content: '进程和线程有什么区别？',
        savedAsCard: false,
        createdAt: 1,
      ),
      TiantianQaMessage(
        id: 2,
        sessionId: 3,
        role: 'assistant',
        content: '进程偏资源，线程偏调度。',
        savedAsCard: false,
        createdAt: 2,
      ),
    ];

    final payload = KnowledgeV3PromptBuilder.buildTiantianAnswerPrompt(
      space: space,
      question: '能举个判断例子吗？',
      materials: const [material],
      history: history,
    );

    expect(payload.userPrompt, contains('本次对话历史'));
    expect(payload.userPrompt, contains('[用户] 进程和线程有什么区别？'));
    expect(payload.userPrompt, contains('[甜甜] 进程偏资源，线程偏调度。'));
    expect(payload.userPrompt, contains('进程线程笔记'));
  });

  test(
    'Tiantian prompt retrieves relevant later content from long materials',
    () {
      const space = KnowledgeSpaceV3(
        id: 1,
        name: '行政法',
        type: 'exam',
        sortOrder: 0,
        isArchived: false,
        createdAt: 1,
        updatedAt: 1,
      );
      final filler = List.generate(
        260,
        (index) => '普通背景材料 $index：这里讨论一般学习安排和无关说明。',
      ).join('\n\n');
      final material = KnowledgeMaterial(
        id: 8,
        spaceId: 1,
        title: '行政处罚笔记',
        content: '$filler\n\n行政处罚追诉时效通常从违法行为发生之日起计算；违法行为有连续或者继续状态的，从行为终了之日起计算。',
        sourceType: 'text',
        orderIndex: 0,
        status: 'ready',
        isArchived: false,
        createdAt: 1,
        updatedAt: 1,
      );

      final payload = KnowledgeV3PromptBuilder.buildTiantianAnswerPrompt(
        space: space,
        question: '行政处罚追诉时效从什么时候起算？',
        materials: [material],
      );

      expect(payload.userPrompt, contains('从违法行为发生之日起计算'));
      expect(payload.userPrompt, isNot(contains('token')));
      expect(payload.userPrompt, isNot(contains('切片')));
    },
  );

  test(
    'generateCards uses outline plan cards pipeline with source metadata',
    () async {
      final keyDir = Directory.systemTemp.createTempSync(
        'growth_os_v3_ai_test_',
      );
      KeyMaterialService.resetForTests(directory: keyDir);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        KeyMaterialService.resetForTests();
        if (keyDir.existsSync()) keyDir.deleteSync(recursive: true);
      });

      final repo = KnowledgeV3Repository(db);
      final aiConfigRepository = AiConfigRepository(db);
      await aiConfigRepository.insertAiConfig(
        AiConfigsCompanion.insert(
          provider: 'test',
          baseUrl: 'https://example.com/v1',
          apiKey: 'sk-test',
          modelName: 'test-model',
          maxTokens: const Value(4096),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
      final space = await repo.ensureDefaultSpace();
      final content = [
        '进程是资源分配的基本单位，线程是 CPU 调度的基本单位。',
        List.generate(
          520,
          (index) => '内存管理补充材料 $index：分页、分段和置换算法说明。',
        ).join('\n'),
      ].join('\n\n');
      final materialId = await repo.importMaterial(
        spaceId: space.id,
        title: '操作系统长资料',
        content: content,
      );
      final material = (await repo.getMaterial(materialId))!;
      final ai = _SequenceAiService([
        '''
{"summary":"操作系统基础","coreConcepts":["进程","线程"],"rules":[],"mistakes":[],"procedures":[],"comparisons":["进程和线程"],"examPoints":[],"cardablePoints":[{"concept":"进程与线程","knowledgePoint":"进程和线程的核心区别","reason":"高频基础概念","sourceChunkIds":["m$materialId-c1"]}]}
''',
        '''
{"cardPlan":[{"concept":"进程与线程","knowledgePoint":"进程和线程的核心区别","reason":"高频基础概念","cardType":"comparison","targetCount":1,"evidenceChunkIds":["m$materialId-c1"],"examScene":"操作系统复习","commonMistake":"把资源分配和调度单位混为一谈"}]}
''',
        '''
{
  "cards": [
    {
      "question": "进程和线程在操作系统中的核心区别是什么？",
      "answer": "进程是资源分配的基本单位，线程是 CPU 调度的基本单位。",
      "explanation": "区分二者时先看资源归属，再看 CPU 调度执行。",
      "cardType": "comparison",
      "importance": 5,
      "difficulty": 3,
      "sourceExcerpt": "进程是资源分配的基本单位，线程是 CPU 调度的基本单位。",
      "sourceChunkId": "m$materialId-c1",
      "concept": "进程与线程",
      "knowledgePoint": "进程和线程的核心区别",
      "grounded": true,
      "status": "auto_approved",
      "tags": ["操作系统"]
    }
  ]
}
''',
      ]);
      final service = KnowledgeV3AiService(
        aiConfigRepository: aiConfigRepository,
        repository: repo,
        aiService: ai,
      );

      final ids = await service.generateCards(
        space: space,
        materials: [material],
      );
      final cards = await repo.getCards(space.id);

      expect(ids, hasLength(1));
      expect(cards, hasLength(1));
      expect(cards.single.question, contains('进程和线程'));
      expect(cards.single.sourceChunkId, 'm$materialId-c1');
      expect(cards.single.grounded, isTrue);
      expect(cards.single.status, 'auto_approved');
      final reviewQueue = await repo.getReviewQueue(
        space.id,
        mode: KnowledgeReviewModeV3.all,
      );
      expect(reviewQueue.map((card) => card.id), contains(cards.single.id));
      expect(ai.calls, 3);
      expect(ai.prompts[0], contains('请先分析资料结构'));
      expect(ai.prompts[1], contains('资料 outline JSON'));
      expect(ai.prompts[2], contains('cardPlan JSON'));
    },
  );

  test(
    'generateCards backfills when dense material is under-covered',
    () async {
      final keyDir = Directory.systemTemp.createTempSync(
        'growth_os_v3_ai_backfill_test_',
      );
      KeyMaterialService.resetForTests(directory: keyDir);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        KeyMaterialService.resetForTests();
        if (keyDir.existsSync()) keyDir.deleteSync(recursive: true);
      });

      final repo = KnowledgeV3Repository(db);
      final aiConfigRepository = AiConfigRepository(db);
      await aiConfigRepository.insertAiConfig(
        AiConfigsCompanion.insert(
          provider: 'test',
          baseUrl: 'https://example.com/v1',
          apiKey: 'sk-test',
          modelName: 'test-model',
          maxTokens: const Value(4096),
          createdAt: 1,
          updatedAt: 1,
        ),
      );
      final space = await repo.ensureDefaultSpace();
      final denseRules = List.generate(
        36,
        (index) => '${index + 1}. 行政处罚规则$index：违法行为发生之日起计算，连续状态从终了之日起计算，注意例外。',
      ).join('\n');
      final materialId = await repo.importMaterial(
        spaceId: space.id,
        title: '行政处罚密集资料',
        content: denseRules,
      );
      final material = (await repo.getMaterial(materialId))!;
      final ai = _SequenceAiService([
        '{"broken": true}',
        '''
{
  "cards": [
    {
      "question": "行政处罚追诉时效的一般起算点是什么？",
      "answer": "通常从违法行为发生之日起计算。",
      "explanation": "先判断违法行为是否已经发生，普通情形按发生日开始计算。",
      "cardType": "recall",
      "importance": 5,
      "difficulty": 2,
      "sourceExcerpt": "违法行为发生之日起计算",
      "tags": ["行政处罚"]
    }
  ]
}
''',
        '''
{
  "cards": [
    {
      "question": "违法行为存在连续状态时追诉时效从什么时候起算？",
      "answer": "从连续状态终了之日起计算。",
      "explanation": "连续状态不是按最初发生日，而是按行为终了日作为起算点。",
      "cardType": "trap",
      "importance": 5,
      "difficulty": 3,
      "sourceExcerpt": "连续状态从终了之日起计算",
      "tags": ["行政处罚", "易错点"]
    }
  ]
}
''',
      ]);
      final service = KnowledgeV3AiService(
        aiConfigRepository: aiConfigRepository,
        repository: repo,
        aiService: ai,
      );

      final ids = await service.generateCards(
        space: space,
        materials: [material],
      );

      expect(ids, hasLength(2));
      expect(ai.calls, 3);
      expect(ai.prompts.last, contains('查漏补卡请求'));
      final cards = await repo.getCards(space.id);
      expect(cards.map((card) => card.question), contains(contains('连续状态')));
    },
  );

  test('saveAnswerAsCard keeps source trace and marks answer saved', () async {
    final keyDir = Directory.systemTemp.createTempSync(
      'growth_os_v3_ai_save_answer_test_',
    );
    KeyMaterialService.resetForTests(directory: keyDir);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      KeyMaterialService.resetForTests();
      if (keyDir.existsSync()) keyDir.deleteSync(recursive: true);
    });

    final repo = KnowledgeV3Repository(db);
    final aiConfigRepository = AiConfigRepository(db);
    final space = await repo.ensureDefaultSpace();
    final materialId = await repo.importMaterial(
      spaceId: space.id,
      title: '?????',
      content: '???????????????????????',
    );
    final material = (await repo.getMaterial(materialId))!;
    final sessionId = await repo.createQaSession(
      spaceId: space.id,
      title: '????????',
      referencedMaterialIds: [material.id],
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'user',
      content: '????????????????',
      sources: [material],
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'assistant',
      content: '???????????????',
      sources: [material],
    );
    final service = KnowledgeV3AiService(
      aiConfigRepository: aiConfigRepository,
      repository: repo,
      aiService: _SequenceAiService(const []),
    );

    final id = await service.saveAnswerAsCard(
      space: space,
      answer: TiantianAnswer(
        sessionId: sessionId,
        question: '????????????????',
        answer: '???????????????',
        sources: [material],
      ),
    );

    final card = await repo.getCard(id);
    final messages = await repo.getQaMessages(sessionId);

    expect(card, isNotNull);
    expect(card!.materialId, material.id);
    expect(card.sourceTitle, '?????');
    expect(card.sourceExcerpt, contains('???????????'));
    expect(messages.last.savedAsCard, isTrue);
  });

  test('saveAnswerAsCard compacts long answers for review cards', () async {
    final keyDir = Directory.systemTemp.createTempSync(
      'growth_os_v3_ai_save_long_answer_test_',
    );
    KeyMaterialService.resetForTests(directory: keyDir);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      KeyMaterialService.resetForTests();
      if (keyDir.existsSync()) keyDir.deleteSync(recursive: true);
    });

    final repo = KnowledgeV3Repository(db);
    final aiConfigRepository = AiConfigRepository(db);
    final space = await repo.ensureDefaultSpace();
    final materialId = await repo.importMaterial(
      spaceId: space.id,
      title: '行政处罚资料',
      content: '行政处罚追诉时效通常从违法行为发生之日起计算；违法行为有连续或者继续状态的，从行为终了之日起计算。',
    );
    final material = (await repo.getMaterial(materialId))!;
    final sessionId = await repo.createQaSession(
      spaceId: space.id,
      title: '追诉时效',
      referencedMaterialIds: [material.id],
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'assistant',
      content: '长回答',
      sources: [material],
    );
    final longAnswer = List.generate(
      16,
      (index) => '第$index点：行政处罚追诉时效要先看违法行为发生日，再判断是否存在连续或者继续状态。',
    ).join(' ');
    final service = KnowledgeV3AiService(
      aiConfigRepository: aiConfigRepository,
      repository: repo,
      aiService: _SequenceAiService(const []),
    );

    final id = await service.saveAnswerAsCard(
      space: space,
      answer: TiantianAnswer(
        sessionId: sessionId,
        question: '行政处罚追诉时效怎么起算？',
        answer: longAnswer,
        sources: [material],
      ),
    );

    final card = await repo.getCard(id);

    expect(card, isNotNull);
    expect(card!.answer.length, lessThanOrEqualTo(380));
    expect(card.answer, endsWith('...'));
    expect(card.explanation, contains('完整回答仍保留在甜甜问答记录中'));
  });

  test('saveAnswerAsCard uses first source only when multiple exist', () async {
    final keyDir = Directory.systemTemp.createTempSync(
      'growth_os_v3_ai_multi_source_test_',
    );
    KeyMaterialService.resetForTests(directory: keyDir);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      KeyMaterialService.resetForTests();
      if (keyDir.existsSync()) keyDir.deleteSync(recursive: true);
    });

    final repo = KnowledgeV3Repository(db);
    final aiConfigRepository = AiConfigRepository(db);
    final space = await repo.ensureDefaultSpace();
    final material1 = (await repo.getMaterial(
      await repo.importMaterial(
        spaceId: space.id,
        title: '资料A',
        content: '内容A',
      ),
    ))!;
    final material2 = (await repo.getMaterial(
      await repo.importMaterial(
        spaceId: space.id,
        title: '资料B',
        content: '内容B',
      ),
    ))!;

    final service = KnowledgeV3AiService(
      aiConfigRepository: aiConfigRepository,
      repository: repo,
      aiService: _SequenceAiService(const []),
    );

    final id = await service.saveAnswerAsCard(
      space: space,
      answer: TiantianAnswer(
        sessionId: 0,
        question: '问题',
        answer: '答案',
        sources: [material1, material2],
      ),
    );

    final card = await repo.getCard(id);
    expect(card, isNotNull);
    expect(card!.materialId, material1.id);
    expect(card.sourceTitle, '资料A');
  });

  test('saveAnswerAsCard writes fixed cardType and tags', () async {
    final keyDir = Directory.systemTemp.createTempSync(
      'growth_os_v3_ai_card_type_test_',
    );
    KeyMaterialService.resetForTests(directory: keyDir);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      KeyMaterialService.resetForTests();
      if (keyDir.existsSync()) keyDir.deleteSync(recursive: true);
    });

    final repo = KnowledgeV3Repository(db);
    final aiConfigRepository = AiConfigRepository(db);
    final space = await repo.ensureDefaultSpace();

    final service = KnowledgeV3AiService(
      aiConfigRepository: aiConfigRepository,
      repository: repo,
      aiService: _SequenceAiService(const []),
    );

    final id = await service.saveAnswerAsCard(
      space: space,
      answer: TiantianAnswer(
        sessionId: 0,
        question: '问题',
        answer: '答案',
        sources: [],
      ),
    );

    final card = await repo.getCard(id);
    expect(card, isNotNull);
    expect(card!.cardType, 'qa');
    expect(card.importance, 3);
    expect(card.difficulty, 3);
    expect(card.tagsJson, contains('甜甜问答'));
  });
}
