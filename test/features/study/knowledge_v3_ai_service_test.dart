import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/ai/repositories/ai_config_repository.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_v3_repository.dart';
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
      "question": "绾跨▼鍜岃繘绋嬪湪鎿嶄綔绯荤粺涓殑鏍稿績鍖哄埆鏄粈涔堬紵",
      "answer": "杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
      "explanation": "鍖哄垎浜岃€呮椂鍏堢湅璧勬簮褰掑睘锛屽啀鐪嬭皟搴︽墽琛屻€?,
      "cardType": "comparison",
      "importance": 5,
      "difficulty": 3,
      "sourceExcerpt": "杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
      "tags": ["鎿嶄綔绯荤粺"]
    }
  ]
}
```
''');

    expect(drafts, hasLength(1));
    expect(drafts.single.question, contains('绾跨▼鍜岃繘绋?));
    expect(KnowledgeV3CardDraftParser.isHighQuality(drafts.single), isTrue);
  });

  test('card draft parser turns truncated JSON into friendly exception', () {
    expect(
      () => KnowledgeV3CardDraftParser.parseSafely('{"cards": ['),
      throwsA(
        isA<KnowledgeV3AiException>().having(
          (error) => error.message,
          'message',
          contains('AI 杈撳嚭涓嶅畬鏁?),
        ),
      ),
    );
  });

  test('quality filter rejects prompt-like useless cards', () {
    const draft = KnowledgeV3CardDraft(
      question: '璇锋€荤粨杩欎釜绌洪棿',
      answer: '杩欐槸璧勬枡鎬荤粨銆?,
      explanation: '鏃?,
      cardType: 'recall',
      importance: 1,
      difficulty: 1,
      sourceExcerpt: '鎬荤粨璧勬枡',
    );

    expect(KnowledgeV3CardDraftParser.isHighQuality(draft), isFalse);
  });

  test('quality filter rejects cards without grounded source excerpt', () {
    const draft = KnowledgeV3CardDraft(
      question: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庝粈涔堟椂鍊欒捣绠楋紵',
      answer: '浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻锛涜繚娉曡涓烘湁杩炵画鎴栬€呯户缁姸鎬佺殑锛屼粠琛屼负缁堜簡涔嬫棩璧疯绠椼€?,
      explanation: '杩欑被鍗＄墖瑕佽兘鍥炲繂璧疯捣绠楃偣鍜岃繛缁姸鎬佷緥澶栥€?,
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
        question: '涓€銆佽鏀垮缃氳拷璇夋椂鏁?,
        answer: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
        explanation: '鏍囬涓嶈兘鐩存帴浣滀负鎶藉崱闂銆?,
        cardType: 'recall',
        importance: 4,
        difficulty: 2,
        sourceExcerpt: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
      );
      const shortAnswerDraft = KnowledgeV3CardDraft(
        question: '琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵',
        answer: '鍙戠敓鏃?,
        explanation: '绛旀澶煭锛岀己灏戝彲鐙珛澶嶄範鐨勪俊鎭€?,
        cardType: 'recall',
        importance: 4,
        difficulty: 2,
        sourceExcerpt: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
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
      title: '鐭祫鏂?,
      content: '杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅銆?,
      sourceType: 'text',
      orderIndex: 0,
      status: 'ready',
      isArchived: false,
      createdAt: 1,
      updatedAt: 1,
    );
    final denseText = List.generate(
      30,
      (index) => '${index + 1}. 琛屾斂澶勭綒瑙勫垯 $index锛氬寘鍚潯浠躲€佷緥澶栧拰鏄撻敊鐐癸紵',
    ).join('\n');
    final dense = KnowledgeMaterial(
      id: 2,
      spaceId: 1,
      title: '瀵嗛泦璧勬枡',
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
        (index) => '${index + 1}. 楂橀鑰冪偣 $index锛氬寘鍚€傜敤鏉′欢銆佷緥澶栥€佸垽鏂緷鎹拰甯歌璇尯锛?,
      ).join('\n');
      final material = KnowledgeMaterial(
        id: 3,
        spaceId: 1,
        title: '鐧鹃鑰冪偣娓呭崟',
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
      name: '鎿嶄綔绯荤粺',
      type: 'exam',
      sortOrder: 0,
      isArchived: false,
      createdAt: 1,
      updatedAt: 1,
    );
    const material = KnowledgeMaterial(
      id: 7,
      spaceId: 1,
      title: '杩涚▼绾跨▼绗旇',
      content: '杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
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
        content: '杩涚▼鍜岀嚎绋嬫湁浠€涔堝尯鍒紵',
        savedAsCard: false,
        createdAt: 1,
      ),
      TiantianQaMessage(
        id: 2,
        sessionId: 3,
        role: 'assistant',
        content: '杩涚▼鍋忚祫婧愶紝绾跨▼鍋忚皟搴︺€?,
        savedAsCard: false,
        createdAt: 2,
      ),
    ];

    final payload = KnowledgeV3PromptBuilder.buildTiantianAnswerPrompt(
      space: space,
      question: '鑳戒妇涓垽鏂緥瀛愬悧锛?,
      materials: const [material],
      history: history,
    );

    expect(payload.userPrompt, contains('鏈瀵硅瘽鍘嗗彶'));
    expect(payload.userPrompt, contains('[鐢ㄦ埛] 杩涚▼鍜岀嚎绋嬫湁浠€涔堝尯鍒紵'));
    expect(payload.userPrompt, contains('[鐢滅敎] 杩涚▼鍋忚祫婧愶紝绾跨▼鍋忚皟搴︺€?));
    expect(payload.userPrompt, contains('杩涚▼绾跨▼绗旇'));
  });

  test(
    'Tiantian prompt retrieves relevant later content from long materials',
    () {
      const space = KnowledgeSpaceV3(
        id: 1,
        name: '琛屾斂娉?,
        type: 'exam',
        sortOrder: 0,
        isArchived: false,
        createdAt: 1,
        updatedAt: 1,
      );
      final filler = List.generate(
        260,
        (index) => '鏅€氳儗鏅潗鏂?$index锛氳繖閲岃璁轰竴鑸涔犲畨鎺掑拰鏃犲叧璇存槑銆?,
      ).join('\n\n');
      final material = KnowledgeMaterial(
        id: 8,
        spaceId: 1,
        title: '琛屾斂澶勭綒绗旇',
        content: '$filler\n\n琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻锛涜繚娉曡涓烘湁杩炵画鎴栬€呯户缁姸鎬佺殑锛屼粠琛屼负缁堜簡涔嬫棩璧疯绠椼€?,
        sourceType: 'text',
        orderIndex: 0,
        status: 'ready',
        isArchived: false,
        createdAt: 1,
        updatedAt: 1,
      );

      final payload = KnowledgeV3PromptBuilder.buildTiantianAnswerPrompt(
        space: space,
        question: '琛屾斂澶勭綒杩借瘔鏃舵晥浠庝粈涔堟椂鍊欒捣绠楋紵',
        materials: [material],
      );

      expect(payload.userPrompt, contains('浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻'));
      expect(payload.userPrompt, isNot(contains('token')));
      expect(payload.userPrompt, isNot(contains('鍒囩墖')));
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
        '杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
        List.generate(
          520,
          (index) => '鍐呭瓨绠＄悊琛ュ厖鏉愭枡 $index锛氬垎椤点€佸垎娈靛拰缃崲绠楁硶璇存槑銆?,
        ).join('\n'),
      ].join('\n\n');
      final materialId = await repo.importMaterial(
        spaceId: space.id,
        title: '鎿嶄綔绯荤粺闀胯祫鏂?,
        content: content,
      );
      final material = (await repo.getMaterial(materialId))!;
      final ai = _SequenceAiService([
        '''
{"summary":"鎿嶄綔绯荤粺鍩虹","coreConcepts":["杩涚▼","绾跨▼"],"rules":[],"mistakes":[],"procedures":[],"comparisons":["杩涚▼鍜岀嚎绋?],"examPoints":[],"cardablePoints":[{"concept":"杩涚▼涓庣嚎绋?,"knowledgePoint":"杩涚▼鍜岀嚎绋嬬殑鏍稿績鍖哄埆","reason":"楂橀鍩虹姒傚康","sourceChunkIds":["m$materialId-c1"]}]}
''',
        '''
{"cardPlan":[{"concept":"杩涚▼涓庣嚎绋?,"knowledgePoint":"杩涚▼鍜岀嚎绋嬬殑鏍稿績鍖哄埆","reason":"楂橀鍩虹姒傚康","cardType":"comparison","targetCount":1,"evidenceChunkIds":["m$materialId-c1"],"examScene":"鎿嶄綔绯荤粺澶嶄範","commonMistake":"鎶婅祫婧愬垎閰嶅拰璋冨害鍗曚綅娣蜂负涓€璋?}]}
''',
        '''
{
  "cards": [
    {
      "question": "杩涚▼鍜岀嚎绋嬪湪鎿嶄綔绯荤粺涓殑鏍稿績鍖哄埆鏄粈涔堬紵",
      "answer": "杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
      "explanation": "鍖哄垎浜岃€呮椂鍏堢湅璧勬簮褰掑睘锛屽啀鐪?CPU 璋冨害鎵ц銆?,
      "cardType": "comparison",
      "importance": 5,
      "difficulty": 3,
      "sourceExcerpt": "杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸 CPU 璋冨害鐨勫熀鏈崟浣嶃€?,
      "sourceChunkId": "m$materialId-c1",
      "concept": "杩涚▼涓庣嚎绋?,
      "knowledgePoint": "杩涚▼鍜岀嚎绋嬬殑鏍稿績鍖哄埆",
      "grounded": true,
      "status": "auto_approved",
      "tags": ["鎿嶄綔绯荤粺"]
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
      expect(cards.single.question, contains('杩涚▼鍜岀嚎绋?));
      expect(cards.single.sourceChunkId, 'm$materialId-c1');
      expect(cards.single.grounded, isTrue);
      expect(cards.single.status, 'auto_approved');
      final reviewQueue = await repo.getReviewQueue(
        space.id,
        mode: KnowledgeReviewModeV3.all,
      );
      expect(reviewQueue.map((card) => card.id), contains(cards.single.id));
      expect(ai.calls, 3);
      expect(ai.prompts[0], contains('璇峰厛鍒嗘瀽璧勬枡缁撴瀯'));
      expect(ai.prompts[1], contains('璧勬枡 outline JSON'));
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
        (index) => '${index + 1}. 琛屾斂澶勭綒瑙勫垯$index锛氳繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻锛岃繛缁姸鎬佷粠缁堜簡涔嬫棩璧疯绠楋紝娉ㄦ剰渚嬪銆?,
      ).join('\n');
      final materialId = await repo.importMaterial(
        spaceId: space.id,
        title: '琛屾斂澶勭綒瀵嗛泦璧勬枡',
        content: denseRules,
      );
      final material = (await repo.getMaterial(materialId))!;
      final ai = _SequenceAiService([
        '{"broken": true}',
        '''
{
  "cards": [
    {
      "question": "琛屾斂澶勭綒杩借瘔鏃舵晥鐨勪竴鑸捣绠楃偣鏄粈涔堬紵",
      "answer": "閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻銆?,
      "explanation": "鍏堝垽鏂繚娉曡涓烘槸鍚﹀凡缁忓彂鐢燂紝鏅€氭儏褰㈡寜鍙戠敓鏃ュ紑濮嬭绠椼€?,
      "cardType": "recall",
      "importance": 5,
      "difficulty": 2,
      "sourceExcerpt": "杩濇硶琛屼负鍙戠敓涔嬫棩璧疯绠?,
      "tags": ["琛屾斂澶勭綒"]
    }
  ]
}
''',
        '''
{
  "cards": [
    {
      "question": "杩濇硶琛屼负瀛樺湪杩炵画鐘舵€佹椂杩借瘔鏃舵晥浠庝粈涔堟椂鍊欒捣绠楋紵",
      "answer": "浠庤繛缁姸鎬佺粓浜嗕箣鏃ヨ捣璁＄畻銆?,
      "explanation": "杩炵画鐘舵€佷笉鏄寜鏈€鍒濆彂鐢熸棩锛岃€屾槸鎸夎涓虹粓浜嗘棩浣滀负璧风畻鐐广€?,
      "cardType": "trap",
      "importance": 5,
      "difficulty": 3,
      "sourceExcerpt": "杩炵画鐘舵€佷粠缁堜簡涔嬫棩璧疯绠?,
      "tags": ["琛屾斂澶勭綒", "鏄撻敊鐐?]
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
      expect(ai.prompts.last, contains('鏌ユ紡琛ュ崱璇锋眰'));
      final cards = await repo.getCards(space.id);
      expect(cards.map((card) => card.question), contains(contains('杩炵画鐘舵€?)));
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
      title: '琛屾斂澶勭綒璧勬枡',
      content: '琛屾斂澶勭綒杩借瘔鏃舵晥閫氬父浠庤繚娉曡涓哄彂鐢熶箣鏃ヨ捣璁＄畻锛涜繚娉曡涓烘湁杩炵画鎴栬€呯户缁姸鎬佺殑锛屼粠琛屼负缁堜簡涔嬫棩璧疯绠椼€?,
    );
    final material = (await repo.getMaterial(materialId))!;
    final sessionId = await repo.createQaSession(
      spaceId: space.id,
      title: '杩借瘔鏃舵晥',
      referencedMaterialIds: [material.id],
    );
    await repo.addQaMessage(
      sessionId: sessionId,
      role: 'assistant',
      content: '闀垮洖绛?,
      sources: [material],
    );
    final longAnswer = List.generate(
      16,
      (index) => '绗?index鐐癸細琛屾斂澶勭綒杩借瘔鏃舵晥瑕佸厛鐪嬭繚娉曡涓哄彂鐢熸棩锛屽啀鍒ゆ柇鏄惁瀛樺湪杩炵画鎴栬€呯户缁姸鎬併€?,
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
        question: '琛屾斂澶勭綒杩借瘔鏃舵晥鎬庝箞璧风畻锛?,
        answer: longAnswer,
        sources: [material],
      ),
    );

    final card = await repo.getCard(id);

    expect(card, isNotNull);
    expect(card!.answer.length, lessThanOrEqualTo(380));
    expect(card.answer, endsWith('...'));
    expect(card.explanation, contains('瀹屾暣鍥炵瓟浠嶄繚鐣欏湪鐢滅敎闂瓟璁板綍涓?));
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
        title: '璧勬枡A',
        content: '鍐呭A',
      ),
    ))!;
    final material2 = (await repo.getMaterial(
      await repo.importMaterial(
        spaceId: space.id,
        title: '璧勬枡B',
        content: '鍐呭B',
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
        question: '闂',
        answer: '绛旀',
        sources: [material1, material2],
      ),
    );

    final card = await repo.getCard(id);
    expect(card, isNotNull);
    expect(card!.materialId, material1.id);
    expect(card.sourceTitle, '璧勬枡A');
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
        question: '闂',
        answer: '绛旀',
        sources: [],
      ),
    );

    final card = await repo.getCard(id);
    expect(card, isNotNull);
    expect(card!.cardType, 'qa');
    expect(card.importance, 3);
    expect(card.difficulty, 3);
    expect(card.tagsJson, contains('鐢滅敎闂瓟'));
  });
}

