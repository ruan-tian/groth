import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/knowledge_v3_repository.dart';
import '../../../shared/providers/repository_providers.dart';
import 'knowledge_card_ai_provider.dart';
import '../services/knowledge_v3_ai_service.dart';

/// 知识卡生成任务状态
class KnowledgeGenerationJobState {
  const KnowledgeGenerationJobState({
    required this.isRunning,
    this.progress = const KnowledgeGenerationProgress(
      stage: 'prepare',
      message: '准备中',
      completedUnits: 0,
      totalUnits: 1,
      savedCount: 0,
    ),
    this.resultIds,
    this.error,
  });

  final bool isRunning;
  final KnowledgeGenerationProgress progress;
  final List<int>? resultIds;
  final String? error;

  KnowledgeGenerationJobState copyWith({
    bool? isRunning,
    KnowledgeGenerationProgress? progress,
    List<int>? resultIds,
    String? error,
  }) {
    return KnowledgeGenerationJobState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      resultIds: resultIds ?? this.resultIds,
      error: error,
    );
  }
}

/// 知识卡生成控制器
class KnowledgeGenerationController
    extends StateNotifier<KnowledgeGenerationJobState> {
  KnowledgeGenerationController({
    required KnowledgeV3AiService aiService,
    required KnowledgeV3Repository repository,
  })  : _aiService = aiService,
        _repository = repository,
        super(const KnowledgeGenerationJobState(isRunning: false));

  final KnowledgeV3AiService _aiService;
  final KnowledgeV3Repository _repository;

  Future<void> start({
    required KnowledgeSpaceV3 space,
    required List<KnowledgeMaterial> materials,
  }) async {
    state = const KnowledgeGenerationJobState(isRunning: true);

    try {
      final resultIds = await _aiService.generateCards(
        space: space,
        materials: materials,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = KnowledgeGenerationJobState(
        isRunning: false,
        progress: state.progress,
        resultIds: resultIds,
      );
    } catch (e) {
      state = KnowledgeGenerationJobState(
        isRunning: false,
        error: e.toString(),
      );
    }
  }

  void clearCompleted() {
    state = const KnowledgeGenerationJobState(isRunning: false);
  }
}

/// 知识卡生成控制器 Provider
final knowledgeGenerationControllerProvider =
    StateNotifierProvider<KnowledgeGenerationController,
        KnowledgeGenerationJobState>((ref) {
  return KnowledgeGenerationController(
    aiService: ref.watch(knowledgeV3AiServiceProvider),
    repository: ref.watch(knowledgeV3RepositoryProvider),
  );
});
