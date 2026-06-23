import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/knowledge_v3_repository.dart';
import 'repository_providers.dart';

final knowledgeSpacesV3Provider = FutureProvider<List<KnowledgeSpaceV3>>((ref) {
  final repo = ref.watch(knowledgeV3RepositoryProvider);
  return repo.getSpaces();
});

final knowledgeAllSpacesV3Provider = FutureProvider<List<KnowledgeSpaceV3>>((
  ref,
) {
  final repo = ref.watch(knowledgeV3RepositoryProvider);
  return repo.getSpaces(includeArchived: true);
});

final selectedKnowledgeSpaceIdProvider = StateProvider<int?>((ref) => null);

final currentKnowledgeSpaceV3Provider = FutureProvider<KnowledgeSpaceV3>((
  ref,
) async {
  final repo = ref.watch(knowledgeV3RepositoryProvider);
  final selectedId = ref.watch(selectedKnowledgeSpaceIdProvider);
  if (selectedId != null) {
    final selected = await repo.getSpace(selectedId);
    if (selected != null && !selected.isArchived) return selected;
  }
  final spaces = await ref.watch(knowledgeSpacesV3Provider.future);
  if (spaces.isNotEmpty) return spaces.first;
  return repo.ensureDefaultSpace();
});

final knowledgeMaterialsV3Provider =
    FutureProvider.family<List<KnowledgeMaterial>, int>((ref, spaceId) {
      final repo = ref.watch(knowledgeV3RepositoryProvider);
      return repo.getMaterials(spaceId);
    });

final knowledgeCardsV3Provider =
    FutureProvider.family<List<KnowledgeCardV3>, int>((ref, spaceId) {
      final repo = ref.watch(knowledgeV3RepositoryProvider);
      return repo.getCards(spaceId);
    });

final knowledgeSpaceStatsV3Provider =
    FutureProvider.family<KnowledgeSpaceStatsV3, int>((ref, spaceId) {
      final repo = ref.watch(knowledgeV3RepositoryProvider);
      return repo.getSpaceStats(spaceId);
    });

final knowledgeWorkspaceOverviewV3Provider =
    FutureProvider<KnowledgeWorkspaceOverviewV3>((ref) async {
      final spaces = await ref.watch(knowledgeSpacesV3Provider.future);
      var materialCount = 0;
      var cardCount = 0;
      var dueCount = 0;
      var weakCount = 0;
      for (final space in spaces) {
        final stats = await ref.watch(
          knowledgeSpaceStatsV3Provider(space.id).future,
        );
        materialCount += stats.materialCount;
        cardCount += stats.cardCount;
        dueCount += stats.dueCount;
        weakCount += stats.weakCount;
      }
      return KnowledgeWorkspaceOverviewV3(
        spaceCount: spaces.length,
        materialCount: materialCount,
        cardCount: cardCount,
        dueCount: dueCount,
        weakCount: weakCount,
      );
    });

final knowledgeReviewQueueV3Provider =
    FutureProvider.family<List<KnowledgeCardV3>, KnowledgeReviewQueueRequestV3>(
      (ref, request) {
        final repo = ref.watch(knowledgeV3RepositoryProvider);
        return repo.getReviewQueue(request.spaceId, mode: request.mode);
      },
    );

final knowledgeSearchV3Provider =
    FutureProvider.family<KnowledgeSearchResultV3, KnowledgeSearchRequestV3>((
      ref,
      request,
    ) async {
      final repo = ref.watch(knowledgeV3RepositoryProvider);
      final materials = await repo.searchMaterials(
        spaceId: request.spaceId,
        query: request.query,
      );
      final cards = await repo.searchCards(
        spaceId: request.spaceId,
        query: request.query,
      );
      final qaHits = await repo.searchQa(
        spaceId: request.spaceId,
        query: request.query,
      );
      return KnowledgeSearchResultV3(
        materials: materials,
        cards: cards,
        qaHits: qaHits,
      );
    });

final tiantianQaSessionsProvider =
    FutureProvider.family<List<TiantianQaSession>, int>((ref, spaceId) {
      final repo = ref.watch(knowledgeV3RepositoryProvider);
      return repo.getQaSessions(spaceId);
    });

final tiantianQaMessagesProvider =
    FutureProvider.family<List<TiantianQaMessage>, int>((ref, sessionId) {
      final repo = ref.watch(knowledgeV3RepositoryProvider);
      return repo.getQaMessages(sessionId);
    });

class KnowledgeReviewQueueRequestV3 {
  const KnowledgeReviewQueueRequestV3({
    required this.spaceId,
    this.mode = KnowledgeReviewModeV3.smart,
  });

  final int spaceId;
  final KnowledgeReviewModeV3 mode;

  @override
  bool operator ==(Object other) {
    return other is KnowledgeReviewQueueRequestV3 &&
        other.spaceId == spaceId &&
        other.mode == mode;
  }

  @override
  int get hashCode => Object.hash(spaceId, mode);
}

class KnowledgeSearchRequestV3 {
  const KnowledgeSearchRequestV3({required this.spaceId, required this.query});

  final int spaceId;
  final String query;

  @override
  bool operator ==(Object other) {
    return other is KnowledgeSearchRequestV3 &&
        other.spaceId == spaceId &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(spaceId, query);
}

class KnowledgeSearchResultV3 {
  const KnowledgeSearchResultV3({
    required this.materials,
    required this.cards,
    required this.qaHits,
  });

  final List<KnowledgeMaterial> materials;
  final List<KnowledgeCardV3> cards;
  final List<TiantianQaSearchHit> qaHits;

  bool get isEmpty => materials.isEmpty && cards.isEmpty && qaHits.isEmpty;
}

class KnowledgeWorkspaceOverviewV3 {
  const KnowledgeWorkspaceOverviewV3({
    required this.spaceCount,
    required this.materialCount,
    required this.cardCount,
    required this.dueCount,
    required this.weakCount,
  });

  final int spaceCount;
  final int materialCount;
  final int cardCount;
  final int dueCount;
  final int weakCount;
}

void invalidateKnowledgeV3(WidgetRef ref, {int? spaceId}) {
  // 延迟到下一帧执行，避免在弹窗关闭动画期间触发父组件重建导致渲染失败
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.invalidate(knowledgeSpacesV3Provider);
    ref.invalidate(knowledgeAllSpacesV3Provider);
    ref.invalidate(currentKnowledgeSpaceV3Provider);
    ref.invalidate(knowledgeWorkspaceOverviewV3Provider);
    if (spaceId != null) {
      ref.invalidate(knowledgeMaterialsV3Provider(spaceId));
      ref.invalidate(knowledgeCardsV3Provider(spaceId));
      ref.invalidate(knowledgeSpaceStatsV3Provider(spaceId));
      ref.invalidate(tiantianQaSessionsProvider(spaceId));
    }
    ref.invalidate(knowledgeReviewQueueV3Provider);
    ref.invalidate(knowledgeSearchV3Provider);
  });
}
