import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/knowledge_v3_repository.dart';
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

final knowledgeGenerationControllerProvider =
    StateNotifierProvider<
      KnowledgeGenerationController,
      KnowledgeGenerationJobState?
    >((ref) {
      return KnowledgeGenerationController(ref);
    });

class KnowledgeGenerationController
    extends StateNotifier<KnowledgeGenerationJobState?> {
  KnowledgeGenerationController(this._ref) : super(null);

  final Ref _ref;
  int _jobSerial = 0;

  Future<List<int>> start({
    required KnowledgeSpaceV3 space,
    required List<KnowledgeMaterial> materials,
  }) {
    final current = state;
    if (current != null &&
        current.isRunning &&
        current.spaceId == space.id &&
        _sameMaterials(current.materialIds, materials)) {
      return current.future;
    }

    late final Future<List<int>> future;
    final jobId = ++_jobSerial;
    state = KnowledgeGenerationJobState(
      jobId: jobId,
      spaceId: space.id,
      materialIds: materials.map((item) => item.id).toList(growable: false),
      materialTitles: materials
          .map((item) => item.title)
          .toList(growable: false),
      progress: const KnowledgeGenerationProgress(
        stage: 'prepare',
        message: '正在准备生成任务',
        completedUnits: 0,
        totalUnits: 1,
        savedCount: 0,
      ),
      future: Future<List<int>>.value(const []),
      isRunning: true,
    );

    future = _ref
        .read(knowledgeV3AiServiceProvider)
        .generateCards(
          space: space,
          materials: materials,
          onProgress: (progress) {
            final current = state;
            if (current == null ||
                !current.isRunning ||
                current.jobId != jobId) {
              return;
            }
            state = current.copyWith(progress: progress);
          },
        )
        .then((ids) {
          final current = state;
          if (current != null && current.jobId == jobId) {
            state = current.copyWith(
              isRunning: false,
              resultIds: ids,
              progress: KnowledgeGenerationProgress(
                stage: 'done',
                message: '生成完成',
                completedUnits: current.progress.totalUnits,
                totalUnits: current.progress.totalUnits,
                savedCount: ids.length,
              ),
            );
          }
          return ids;
        })
        .catchError((Object error) {
          final current = state;
          if (current != null && current.jobId == jobId) {
            state = current.copyWith(isRunning: false, error: error);
          }
          throw error;
        });

    state = state!.copyWith(future: future);
    return future;
  }

  void clearCompleted() {
    final current = state;
    if (current != null && !current.isRunning) state = null;
  }

  bool _sameMaterials(List<int> current, List<KnowledgeMaterial> materials) {
    final incoming = materials.map((item) => item.id).toList(growable: false);
    if (current.length != incoming.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != incoming[i]) return false;
    }
    return true;
  }
}

class KnowledgeGenerationJobState {
  const KnowledgeGenerationJobState({
    required this.jobId,
    required this.spaceId,
    required this.materialIds,
    required this.materialTitles,
    required this.progress,
    required this.future,
    this.isRunning = false,
    this.resultIds,
    this.error,
  });

  final int jobId;
  final int spaceId;
  final List<int> materialIds;
  final List<String> materialTitles;
  final KnowledgeGenerationProgress progress;
  final Future<List<int>> future;
  final bool isRunning;
  final List<int>? resultIds;
  final Object? error;

  KnowledgeGenerationJobState copyWith({
    KnowledgeGenerationProgress? progress,
    Future<List<int>>? future,
    bool? isRunning,
    List<int>? resultIds,
    Object? error,
  }) {
    return KnowledgeGenerationJobState(
      spaceId: spaceId,
      jobId: jobId,
      materialIds: materialIds,
      materialTitles: materialTitles,
      progress: progress ?? this.progress,
      future: future ?? this.future,
      isRunning: isRunning ?? this.isRunning,
      resultIds: resultIds ?? this.resultIds,
      error: error ?? this.error,
    );
  }
}
