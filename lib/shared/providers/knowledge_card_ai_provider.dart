import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/study/services/knowledge_card_ai_service.dart';
import '../../features/study/services/knowledge_v3_ai_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final knowledgeCardAiServiceProvider = Provider<KnowledgeCardAiService>((ref) {
  return KnowledgeCardAiService(
    aiConfigRepository: ref.watch(aiConfigRepositoryProvider),
    cardRepository: ref.watch(knowledgeCardRepositoryProvider),
    sourceRepository: ref.watch(knowledgeSourceRepositoryProvider),
    aiService: ref.watch(aiServiceProvider),
  );
});

final knowledgeV3AiServiceProvider = Provider<KnowledgeV3AiService>((ref) {
  return KnowledgeV3AiService(
    aiConfigRepository: ref.watch(aiConfigRepositoryProvider),
    repository: ref.watch(knowledgeV3RepositoryProvider),
    aiService: ref.watch(aiServiceProvider),
  );
});
