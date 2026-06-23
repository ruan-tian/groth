import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_source_repository.dart';
import 'package:growth_os/features/knowledge/services/knowledge_context_service.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('KnowledgeContextService', () {
    late AppDatabase db;
    late KnowledgeSourceRepository sourceRepo;
    late KnowledgeContextService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sourceRepo = KnowledgeSourceRepository(db);
      service = KnowledgeContextService(sourceRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test('builds a bounded local context from recent study records', () async {
      await sourceRepo.importTextSource(
        title: '鎿嶄綔绯荤粺绗旇',
        type: 'markdown',
        content: '''
# 杩涚▼绠＄悊

杩涚▼鏄祫婧愬垎閰嶅崟浣嶏紝绾跨▼鏄?CPU 璋冨害鍗曚綅銆?
# 鍐呭瓨绠＄悊

鍒嗛〉鏈哄埗鎶婇€昏緫鍦板潃鍒嗘垚椤靛彿鍜岄〉鍐呭亸绉汇€?''',
      );
      await sourceRepo.importTextSource(
        title: '鑻辫闃呰绗旇',
        type: 'markdown',
        content: '闀块毦鍙ユ媶鍒嗛渶瑕佸厛鎵捐皳璇紝鍐嶇湅浠庡彞缁撴瀯銆?,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final bundle = await service.buildForStudyRecords([
        StudyRecord(
          id: 1,
          mode: 'professional',
          title: '杩涚▼鍜岀嚎绋嬪涔?,
          subject: '鎿嶄綔绯荤粺',
          startTime: now - 3600000,
          endTime: now,
          durationMinutes: 60,
          focusLevel: 4,
          difficultyLevel: 3,
          expGained: 8,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      expect(bundle.query, contains('鎿嶄綔绯荤粺'));
      expect(bundle.results, isNotEmpty);
      expect(
        bundle.results.length,
        lessThanOrEqualTo(KnowledgeContextService.maxChunks),
      );
      expect(
        bundle.tokenEstimate,
        lessThanOrEqualTo(KnowledgeContextService.maxTokens),
      );

      final prompt = bundle.toPromptSection();
      expect(prompt, contains('鏈湴鐭ヨ瘑搴撴绱㈢墖娈?));
      expect(prompt, contains('寮曠敤瑙勫垯'));
      expect(prompt, contains('銆愮墖娈?1銆?));
      expect(prompt, contains('鐗囨 1: 鎿嶄綔绯荤粺绗旇'));
      expect(prompt, contains('鎿嶄綔绯荤粺绗旇'));
      expect(prompt, contains('杩涚▼'));
    });

    test('buildForQuery returns empty context for blank query', () async {
      final bundle = await service.buildForQuery('   ');

      expect(bundle.isEmpty, isTrue);
      expect(bundle.query, isEmpty);
      expect(bundle.toPromptSection(), isEmpty);
    });
  });
}

