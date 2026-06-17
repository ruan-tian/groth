import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_source_repository.dart';

class SourceBatchSavedFeedback {
  const SourceBatchSavedFeedback({
    required this.message,
    required this.remainingCount,
    required this.hasNextBatch,
  });

  final String message;
  final int remainingCount;
  final bool hasNextBatch;
}

class KnowledgeSourceBatchContext {
  const KnowledgeSourceBatchContext({
    required this.source,
    required this.chunks,
    required this.references,
  });

  final KnowledgeSource source;
  final List<KnowledgeChunk> chunks;
  final List<KnowledgeSourceCardReference> references;
}

List<KnowledgeChunkSearchResult> buildKnowledgeSourceBatchResults({
  required KnowledgeSource source,
  required List<KnowledgeChunk> chunks,
  required List<KnowledgeSourceCardReference> references,
}) {
  final convertedChunkIds = references
      .map((reference) => reference.chunk.id)
      .toSet();
  final pendingChunks = chunks
      .where((chunk) => !convertedChunkIds.contains(chunk.id))
      .toList(growable: false);
  final candidates = pendingChunks.isEmpty ? chunks : pendingChunks;
  return candidates
      .take(5)
      .map(
        (chunk) =>
            KnowledgeChunkSearchResult(source: source, chunk: chunk, score: 0),
      )
      .toList(growable: false);
}

List<KnowledgeChunkSearchResult> buildKnowledgeSourceRangeBatchResults({
  required List<KnowledgeSourceBatchContext> contexts,
  int limit = 5,
}) {
  final selected = <KnowledgeChunkSearchResult>[];
  final selectedChunkIds = <int>{};

  for (final context in contexts) {
    final convertedChunkIds = context.references
        .map((reference) => reference.chunk.id)
        .toSet();
    for (final chunk in context.chunks) {
      if (convertedChunkIds.contains(chunk.id)) continue;
      if (selectedChunkIds.add(chunk.id)) {
        selected.add(
          KnowledgeChunkSearchResult(
            source: context.source,
            chunk: chunk,
            score: 0,
          ),
        );
      }
      if (selected.length >= limit) return selected;
    }
  }

  return selected;
}

int countPendingKnowledgeSourceChunks(
  List<KnowledgeChunk> chunks,
  List<KnowledgeSourceCardReference> references,
) {
  final convertedChunkIds = references
      .map((reference) => reference.chunk.id)
      .toSet();
  return chunks.where((chunk) => !convertedChunkIds.contains(chunk.id)).length;
}

SourceBatchSavedFeedback buildKnowledgeSourceBatchSavedFeedback({
  required int savedCardCount,
  required List<KnowledgeChunk> allChunks,
  required List<KnowledgeSourceCardReference> existingReferences,
  required List<KnowledgeChunkSearchResult> selectedResults,
}) {
  final convertedChunkIds = existingReferences
      .map((reference) => reference.chunk.id)
      .toSet();
  final newlyConvertedChunkIds = selectedResults
      .map((result) => result.chunk.id)
      .where((chunkId) => !convertedChunkIds.contains(chunkId))
      .toSet();
  final remainingCount =
      allChunks.length -
      convertedChunkIds.length -
      newlyConvertedChunkIds.length;

  if (newlyConvertedChunkIds.isEmpty) {
    return SourceBatchSavedFeedback(
      message: '已保存 $savedCardCount 张知识卡，这批是重新生成内容。',
      remainingCount: remainingCount.clamp(0, allChunks.length),
      hasNextBatch: false,
    );
  }
  if (remainingCount <= 0) {
    return SourceBatchSavedFeedback(
      message: '已保存 $savedCardCount 张知识卡，这份资料已全部沉淀完成。',
      remainingCount: 0,
      hasNextBatch: false,
    );
  }
  return SourceBatchSavedFeedback(
    message:
        '已保存 $savedCardCount 张知识卡，本批沉淀 ${newlyConvertedChunkIds.length} 个片段，还剩 $remainingCount 个片段。',
    remainingCount: remainingCount,
    hasNextBatch: true,
  );
}

SourceBatchSavedFeedback buildKnowledgeSourceRangeBatchSavedFeedback({
  required int savedCardCount,
  required List<KnowledgeSourceBatchContext> contexts,
  required List<KnowledgeChunkSearchResult> selectedResults,
}) {
  final allChunks = contexts
      .expand((context) => context.chunks)
      .toList(growable: false);
  final existingReferences = contexts
      .expand((context) => context.references)
      .toList(growable: false);
  final convertedChunkIds = existingReferences
      .map((reference) => reference.chunk.id)
      .toSet();
  final newlyConvertedChunkIds = selectedResults
      .map((result) => result.chunk.id)
      .where((chunkId) => !convertedChunkIds.contains(chunkId))
      .toSet();
  final remainingCount =
      allChunks.length -
      convertedChunkIds.length -
      newlyConvertedChunkIds.length;

  if (newlyConvertedChunkIds.isEmpty) {
    return SourceBatchSavedFeedback(
      message: '已保存 $savedCardCount 张知识卡，这批是重新生成内容。',
      remainingCount: remainingCount.clamp(0, allChunks.length),
      hasNextBatch: false,
    );
  }
  if (remainingCount <= 0) {
    return SourceBatchSavedFeedback(
      message: '已保存 $savedCardCount 张知识卡，当前范围已全部沉淀完成。',
      remainingCount: 0,
      hasNextBatch: false,
    );
  }
  return SourceBatchSavedFeedback(
    message:
        '已保存 $savedCardCount 张知识卡，本批沉淀 ${newlyConvertedChunkIds.length} 个片段，当前范围还剩 $remainingCount 个片段。',
    remainingCount: remainingCount,
    hasNextBatch: true,
  );
}
