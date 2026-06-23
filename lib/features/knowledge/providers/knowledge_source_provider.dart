import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../knowledge/repositories/knowledge_source_repository.dart';
import 'knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';

final knowledgeSourcesProvider = FutureProvider<List<KnowledgeSource>>((ref) {
  final repo = ref.watch(knowledgeSourceRepositoryProvider);
  return repo.getSources();
});

final knowledgeSourcesWithProgressProvider =
    FutureProvider<List<KnowledgeSourceWithProgress>>((ref) async {
      final sources = await ref.watch(knowledgeSourcesProvider.future);
      final sourceRepo = ref.watch(knowledgeSourceRepositoryProvider);
      final items = await Future.wait(
        sources.map((source) async {
          final chunks = await sourceRepo.getChunksForSource(source.id);
          final references = await sourceRepo.getCardReferencesForSource(
            source.id,
          );
          return KnowledgeSourceWithProgress(
            source: source,
            progress: KnowledgeSourceConversionProgress.fromChunksAndReferences(
              chunks: chunks,
              references: references,
            ),
          );
        }),
      );
      return items;
    });

final knowledgeBaseOverviewProvider = FutureProvider<KnowledgeBaseOverview>((
  ref,
) async {
  final sources = await ref.watch(knowledgeSourcesProvider.future);
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final sourceRepo = ref.watch(knowledgeSourceRepositoryProvider);
  final links = await sourceRepo.getAllCardSourceLinks();
  final sourceIdSet = sources.map((source) => source.id).toSet();
  final activeLinks = links
      .where((link) => sourceIdSet.contains(link.sourceId))
      .toList(growable: false);
  final linkedCardIds = activeLinks.map((link) => link.cardId).toSet();
  final linkedChunkIds = activeLinks.map((link) => link.chunkId).toSet();
  // Batch fetch all chunks in 1 query instead of N
  final sourceIds = sources.map((s) => s.id).toList();
  final chunksBySource = await sourceRepo.getChunksForSources(sourceIds);
  final chunkCount = chunksBySource.values.fold<int>(
    0,
    (sum, chunks) => sum + chunks.length,
  );
  final reviewStats = KnowledgeCardReviewStats.fromCards(
    cards,
    DateTime.now().millisecondsSinceEpoch,
  );

  return KnowledgeBaseOverview(
    sourceCount: sources.length,
    chunkCount: chunkCount,
    linkedCardCount: linkedCardIds.length,
    linkedChunkCount: linkedChunkIds.length,
    dueCardCount: reviewStats.dueCards,
    weakCardCount: reviewStats.weakCards,
    totalCardCount: cards.length,
  );
});

class KnowledgeBaseOverview {
  const KnowledgeBaseOverview({
    required this.sourceCount,
    required this.chunkCount,
    required this.linkedCardCount,
    required this.linkedChunkCount,
    required this.dueCardCount,
    required this.weakCardCount,
    required this.totalCardCount,
  });

  final int sourceCount;
  final int chunkCount;
  final int linkedCardCount;
  final int linkedChunkCount;
  final int dueCardCount;
  final int weakCardCount;
  final int totalCardCount;

  double get linkedChunkRatio {
    if (chunkCount == 0) return 0;
    return linkedChunkCount / chunkCount;
  }

  int get pendingChunkCount => chunkCount - linkedChunkCount;

  bool get hasPendingChunks => pendingChunkCount > 0;

  String get statusText {
    if (sourceCount == 0) return '先导入资料，让 AI 有本地依据';
    if (linkedCardCount == 0) return '已有资料，下一步生成知识卡';
    if (hasPendingChunks) return '还有资料片段待沉淀，适合继续生成知识卡';
    if (dueCardCount > 0 || weakCardCount > 0) {
      return '资料已入库，今天适合继续抽卡复习';
    }
    return '知识库运行健康，继续补充新资料';
  }
}

class KnowledgeSourceWithProgress {
  const KnowledgeSourceWithProgress({
    required this.source,
    required this.progress,
  });

  final KnowledgeSource source;
  final KnowledgeSourceConversionProgress progress;
}

final knowledgeSourceProvider = FutureProvider.family<KnowledgeSource?, int>((
  ref,
  sourceId,
) {
  final repo = ref.watch(knowledgeSourceRepositoryProvider);
  return repo.getSourceById(sourceId);
});

final knowledgeSourceDuplicateCandidatesProvider =
    FutureProvider.family<List<KnowledgeSourceImportDuplicateCandidate>, int>((
      ref,
      sourceId,
    ) {
      final repo = ref.watch(knowledgeSourceRepositoryProvider);
      return repo.findRelatedDuplicateSources(sourceId: sourceId);
    });

final knowledgeSourceDuplicateSummariesProvider =
    FutureProvider<Map<int, KnowledgeSourceDuplicateSummary>>((ref) async {
      final sources = await ref.watch(knowledgeSourcesProvider.future);
      final repo = ref.watch(knowledgeSourceRepositoryProvider);
      final summaries = await Future.wait(
        sources.map((source) async {
          final candidates = await repo.findRelatedDuplicateSources(
            sourceId: source.id,
          );
          return KnowledgeSourceDuplicateSummary(
            sourceId: source.id,
            candidates: candidates,
          );
        }),
      );
      return {for (final summary in summaries) summary.sourceId: summary};
    });

final knowledgeSourceChunksProvider =
    FutureProvider.family<List<KnowledgeChunk>, int>((ref, sourceId) {
      final repo = ref.watch(knowledgeSourceRepositoryProvider);
      return repo.getChunksForSource(sourceId);
    });

final knowledgeCardSourceReferencesProvider =
    FutureProvider.family<List<KnowledgeCardSourceReference>, int>((
      ref,
      cardId,
    ) {
      final repo = ref.watch(knowledgeSourceRepositoryProvider);
      return repo.getReferencesForCard(cardId);
    });

final knowledgeSourceCardReferencesProvider =
    FutureProvider.family<List<KnowledgeSourceCardReference>, int>((
      ref,
      sourceId,
    ) {
      final repo = ref.watch(knowledgeSourceRepositoryProvider);
      return repo.getCardReferencesForSource(sourceId);
    });

final knowledgeSourceConversionProgressProvider =
    FutureProvider.family<KnowledgeSourceConversionProgress, int>((
      ref,
      sourceId,
    ) async {
      final chunks = await ref.watch(
        knowledgeSourceChunksProvider(sourceId).future,
      );
      final references = await ref.watch(
        knowledgeSourceCardReferencesProvider(sourceId).future,
      );
      return KnowledgeSourceConversionProgress.fromChunksAndReferences(
        chunks: chunks,
        references: references,
      );
    });

class KnowledgeSourceConversionProgress {
  const KnowledgeSourceConversionProgress({
    required this.chunkCount,
    required this.convertedChunkCount,
    required this.linkedCardCount,
  });

  factory KnowledgeSourceConversionProgress.fromChunksAndReferences({
    required List<KnowledgeChunk> chunks,
    required List<KnowledgeSourceCardReference> references,
  }) {
    final convertedChunkIds = references
        .map((reference) => reference.chunk.id)
        .toSet();
    final convertedChunks = chunks
        .where((chunk) => convertedChunkIds.contains(chunk.id))
        .length;
    final distinctCards = references
        .map((reference) => reference.card.id)
        .toSet()
        .length;
    return KnowledgeSourceConversionProgress(
      chunkCount: chunks.length,
      convertedChunkCount: convertedChunks,
      linkedCardCount: distinctCards,
    );
  }

  final int chunkCount;
  final int convertedChunkCount;
  final int linkedCardCount;

  int get pendingChunkCount => chunkCount - convertedChunkCount;

  double get ratio {
    if (chunkCount == 0) return 0;
    return convertedChunkCount / chunkCount;
  }

  bool get hasPendingChunks => pendingChunkCount > 0;
}

class KnowledgeSourceDuplicateSummary {
  const KnowledgeSourceDuplicateSummary({
    required this.sourceId,
    required this.candidates,
  });

  final int sourceId;
  final List<KnowledgeSourceImportDuplicateCandidate> candidates;

  List<KnowledgeSourceImportDuplicateCandidate> get activeCandidates =>
      candidates
          .where((candidate) => !candidate.source.archived)
          .toList(growable: false);

  List<KnowledgeSourceImportDuplicateCandidate> get archivedCandidates =>
      candidates
          .where((candidate) => candidate.source.archived)
          .toList(growable: false);

  int get duplicateCount => activeCandidates.length;

  int get archivedDuplicateCount => archivedCandidates.length;

  bool get hasDuplicates => duplicateCount > 0;

  bool get hasArchivedDuplicates => archivedDuplicateCount > 0;
}

final knowledgeChunkSearchProvider =
    FutureProvider.family<
      List<KnowledgeChunkSearchResult>,
      KnowledgeChunkSearchQuery
    >((ref, request) {
      final repo = ref.watch(knowledgeSourceRepositoryProvider);
      return repo.searchChunks(
        query: request.query,
        goalKey: request.goalKey,
        goalName: request.goalName,
        moduleKey: request.moduleKey,
        moduleName: request.moduleName,
        limit: request.limit,
      );
    });

class KnowledgeChunkSearchQuery {
  const KnowledgeChunkSearchQuery({
    required this.query,
    this.goalKey,
    this.goalName,
    this.moduleKey,
    this.moduleName,
    this.limit = 8,
  });

  final String query;
  final String? goalKey;
  final String? goalName;
  final String? moduleKey;
  final String? moduleName;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is KnowledgeChunkSearchQuery &&
        other.query == query &&
        other.goalKey == goalKey &&
        other.goalName == goalName &&
        other.moduleKey == moduleKey &&
        other.moduleName == moduleName &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(query, goalKey, goalName, moduleKey, moduleName, limit);
}
