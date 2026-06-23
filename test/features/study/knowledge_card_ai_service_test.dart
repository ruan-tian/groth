import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/ai/repositories/ai_config_repository.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_card_repository.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_source_repository.dart';
import 'package:growth_os/core/services/ai_service.dart';
import 'package:growth_os/core/services/encryption_service.dart';
import 'package:growth_os/features/knowledge/services/knowledge_card_ai_service.dart';

class _StubAiService extends AiService {
  _StubAiService(this.response);

  final String response;

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
    return response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('KnowledgeCardAiService', () {
    late AppDatabase db;
    late Directory keyDir;
    late KnowledgeSourceRepository sourceRepo;
    late KnowledgeCardAiService service;

    setUp(() {
      keyDir = Directory.systemTemp.createTempSync('growth_os_ai_test_');
      KeyMaterialService.resetForTests(directory: keyDir);
      db = AppDatabase(NativeDatabase.memory());
      sourceRepo = KnowledgeSourceRepository(db);
      service = KnowledgeCardAiService(
        aiConfigRepository: AiConfigRepository(db),
        cardRepository: KnowledgeCardRepository(db),
        sourceRepository: sourceRepo,
        aiService: AiService(),
      );
    });

    tearDown(() async {
      await db.close();
      KeyMaterialService.resetForTests();
      if (keyDir.existsSync()) {
        keyDir.deleteSync(recursive: true);
      }
    });

    test('buildPayload sends only the selected chunk', () async {
      await sourceRepo.importTextSource(
        title: '鎿嶄綔绯荤粺绗旇',
        type: 'markdown',
        content: '''
# 杩涚▼绠＄悊

杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?
# 鍐呭瓨绠＄悊

鍒嗛〉鏈哄埗鎶婇€昏緫鍦板潃鍒嗘垚椤靛彿鍜岄〉鍐呭亸绉汇€?''',
      );

      final result = (await sourceRepo.searchChunks(query: '绾跨▼ 璋冨害')).single;
      final payload = service.buildPayload(result);

      expect(payload.userPrompt, contains('绾跨▼鏄?CPU 璋冨害鍗曚綅'));
      expect(payload.userPrompt, isNot(contains('椤靛彿鍜岄〉鍐呭亸绉?)));
      expect(payload.userPrompt, contains('杩斿洖涓ユ牸 JSON'));
    });

    test('buildPayloadForResults sends only selected top chunks', () async {
      await sourceRepo.importTextSource(
        title: '鎿嶄綔绯荤粺绗旇',
        type: 'markdown',
        content: '''
# 杩涚▼绠＄悊

杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?
# 鍐呭瓨绠＄悊

鍒嗛〉鏈哄埗鎶婇€昏緫鍦板潃鍒嗘垚椤靛彿鍜岄〉鍐呭亸绉汇€?
# 鏂囦欢绠＄悊

鐩綍缁撴瀯鐢ㄤ簬缁勭粐鏂囦欢銆?''',
      );

      final results = await sourceRepo.searchChunks(query: '绾跨▼ 椤靛彿');
      // With dictionary-based tokenizer, both '绾跨▼' and '椤靛彿' are recognized terms
      expect(results.length, greaterThanOrEqualTo(2));
      final payload = service.buildPayloadForResults(
        results.take(2).toList(growable: false),
        topic: '鎿嶄綔绯荤粺閲嶇偣',
      );

      expect(payload.userPrompt, contains('鎿嶄綔绯荤粺閲嶇偣'));
      expect(payload.userPrompt, contains('璧勬枡鐗囨 1 寮€濮?));
      expect(payload.userPrompt, contains('璧勬枡鐗囨 2 寮€濮?));
      // Both chunks should be about process/thread and memory management
      expect(payload.userPrompt, isNot(contains('鐩綍缁撴瀯鐢ㄤ簬缁勭粐鏂囦欢')));
    });

    test('saveDrafts inserts local cards and source links', () async {
      final sourceId = await sourceRepo.importTextSource(
        title: '鎿嶄綔绯荤粺绗旇',
        type: 'markdown',
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
        content: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
      );
      final result = (await sourceRepo.searchChunks(query: '杩涚▼ 绾跨▼')).single;

      final ids = await service.saveDrafts(
        result: result,
        drafts: const [
          KnowledgeCardAiDraft(
            title: '杩涚▼涓庣嚎绋?,
            question: '杩涚▼鍜岀嚎绋嬪垎鍒槸浠€涔堝崟浣嶏紵',
            answer: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
            tags: ['鎿嶄綔绯荤粺'],
          ),
        ],
      );

      final cards = await db.select(db.knowledgeCards).get();
      final links = await db.select(db.knowledgeCardSourceLinks).get();

      expect(ids, hasLength(1));
      expect(cards.single.id, ids.single);
      expect(cards.single.goalKey, 'kaoyan_computer');
      expect(cards.single.moduleKey, 'operating_system');
      expect(jsonDecode(cards.single.tags!), ['鎿嶄綔绯荤粺']);
      expect(links.single.cardId, ids.single);
      expect(links.single.sourceId, sourceId);
      expect(links.single.chunkId, result.chunk.id);
      expect(links.single.quote, contains('杩涚▼鏄祫婧愬垎閰嶅崟浣?));
    });

    test('answerSpaceQuestion uses local chunks and returns answer', () async {
      await sourceRepo.importTextSource(
        title: '鎿嶄綔绯荤粺绗旇',
        type: 'markdown',
        goalKey: 'kaoyan_computer',
        moduleKey: 'operating_system',
        content: '杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?,
      );
      service = KnowledgeCardAiService(
        aiConfigRepository: AiConfigRepository(db),
        cardRepository: KnowledgeCardRepository(db),
        sourceRepository: sourceRepo,
        aiService: _StubAiService('杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆俒鐗囨1]'),
      );
      await _insertAiConfig(AiConfigRepository(db));

      final result = (await sourceRepo.searchChunks(query: '杩涚▼ 绾跨▼')).single;
      final answer = await service.answerSpaceQuestion(
        results: [result],
        question: '杩涚▼鍜岀嚎绋嬪垎鍒槸浠€涔堬紵',
      );

      expect(answer.question, '杩涚▼鍜岀嚎绋嬪垎鍒槸浠€涔堬紵');
      expect(answer.answer, contains('[鐗囨1]'));
      expect(answer.results, hasLength(1));
      expect(answer.results.single.chunk.id, result.chunk.id);
    });
  });

  group('checkDraftQuality', () {
    test('flags answer that is too short', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Test',
          question: 'What is Flutter?',
          answer: 'UI',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('绛旀杩囩煭'));
    });

    test('flags question and answer being the same', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Test',
          question: '杩涚▼鏄搷浣滅郴缁熶腑鐨勫熀鏈蹇?,
          answer: '杩涚▼鏄搷浣滅郴缁熶腑鐨勫熀鏈蹇?,
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('闂鍜岀瓟妗堝唴瀹圭浉鍚?));
    });

    test('flags question that is too short', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Test',
          question: 'SQL',
          answer: 'Structured Query Language is used for databases.',
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('闂杩囩煭'));
    });

    test('returns null for good quality drafts', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: '杩涚▼涓庣嚎绋?,
          question: '杩涚▼鍜岀嚎绋嬬殑涓昏鍖哄埆鏄粈涔堬紵',
          answer: '杩涚▼鏄祫婧愬垎閰嶇殑鍩烘湰鍗曚綅锛岀嚎绋嬫槸CPU璋冨害鐨勫熀鏈崟浣嶃€備竴涓繘绋嬪彲浠ュ寘鍚涓嚎绋嬨€?,
        ),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(1));
      expect(warnings.first, isNull);
    });

    test('handles multiple drafts independently', () {
      final drafts = [
        KnowledgeCardAiDraft(
          title: 'Good',
          question: 'What is a database index?',
          answer:
              'A data structure that speeds up lookup operations at the cost of additional storage.',
        ),
        KnowledgeCardAiDraft(title: 'Bad', question: 'Q', answer: 'A'),
      ];
      final warnings = KnowledgeCardAiService.checkDraftQuality(drafts);
      expect(warnings, hasLength(2));
      expect(warnings[0], isNull);
      expect(warnings[1], isNotNull);
    });
  });
}

Future<void> _insertAiConfig(AiConfigRepository repo) {
  final nowMs = DateTime(2026, 6, 8, 6).millisecondsSinceEpoch;
  return repo
      .insertAiConfig(
        AiConfigsCompanion.insert(
          provider: 'test',
          baseUrl: 'https://example.com/v1',
          apiKey: 'sk-test',
          modelName: 'test-model',
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      )
      .then((_) {});
}

