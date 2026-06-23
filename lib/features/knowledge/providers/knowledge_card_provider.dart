import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_card_repository.dart';
import '../../../core/repositories/knowledge_source_repository.dart';
import '../constants/knowledge_card_assets.dart';
import 'knowledge_source_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import 'dart:convert';

final knowledgeCardsProvider = FutureProvider<List<KnowledgeCard>>((ref) {
  final repo = ref.watch(knowledgeCardRepositoryProvider);
  return repo.getAllCards();
});

final archivedKnowledgeCardsProvider = FutureProvider<List<KnowledgeCard>>((
  ref,
) {
  final repo = ref.watch(knowledgeCardRepositoryProvider);
  return repo.getArchivedCards();
});

final knowledgeReviewStatsProvider = FutureProvider<KnowledgeCardReviewStats>((
  ref,
) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  return KnowledgeCardReviewStats.fromCards(
    cards,
    DateTime.now().millisecondsSinceEpoch,
  );
});

final knowledgeCustomTemplatesProvider =
    FutureProvider<List<KnowledgeCustomTemplateBundle>>((ref) {
      final repo = ref.watch(knowledgeCardRepositoryProvider);
      return repo.getCustomTemplatesWithModules();
    });

final knowledgeCardsByDeckProvider =
    FutureProvider.family<List<KnowledgeCard>, String>((ref, deckKey) {
      final repo = ref.watch(knowledgeCardRepositoryProvider);
      return repo.getCardsByDeck(deckKey);
    });

final knowledgeGoalSummariesProvider =
    FutureProvider<List<KnowledgeGoalSummary>>((ref) async {
      final cards = await ref.watch(knowledgeCardsProvider.future);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final summaries = <KnowledgeGoalSummary>[];

      for (final goal in KnowledgeCardAssets.goalTemplates) {
        if (goal.key == 'custom') continue;
        final goalCards = cards.where((card) => card.goalKey == goal.key);
        summaries.add(_goalSummaryFromCards(goal, goalCards, nowMs));
      }

      final customGoal = KnowledgeCardAssets.goalForKey('custom');
      final customCards = cards.where((card) => card.goalKey == 'custom');
      final customGroups = <String?, List<KnowledgeCard>>{};
      for (final card in customCards) {
        final name = _storedCustomGoalName(card.goalName);
        customGroups.putIfAbsent(name, () => <KnowledgeCard>[]).add(card);
      }

      if (customGroups.isEmpty) {
        summaries.add(
          KnowledgeGoalSummary(
            visual: customGoal,
            displayName: customGoal.name,
            customGoalName: null,
            totalCards: 0,
            dueCards: 0,
            reviewedCards: 0,
            averageMastery: 0,
            moduleCount: customGoal.modules.length,
          ),
        );
      } else {
        for (final entry in customGroups.entries) {
          summaries.add(
            _goalSummaryFromCards(
              customGoal,
              entry.value,
              nowMs,
              displayName: _customGoalName(entry.key),
              customGoalName: entry.key,
            ),
          );
        }
      }

      return summaries;
    });

final knowledgeDeckSummariesProvider =
    FutureProvider<List<KnowledgeDeckSummary>>((ref) async {
      final cards = await ref.watch(knowledgeCardsProvider.future);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      return KnowledgeCardAssets.decks
          .map((deck) {
            final deckCards = cards.where((card) => card.deckKey == deck.key);
            final total = deckCards.length;
            final due = deckCards.where((card) => card.dueAt <= nowMs).length;
            final reviewed = deckCards
                .where((card) => card.reviewCount > 0)
                .length;
            final masterySum = deckCards.fold<int>(
              0,
              (sum, card) => sum + card.masteryLevel,
            );
            return KnowledgeDeckSummary(
              visual: deck,
              totalCards: total,
              dueCards: due,
              reviewedCards: reviewed,
              averageMastery: total == 0 ? 0 : masterySum / total,
            );
          })
          .toList(growable: false);
    });

KnowledgeGoalSummary _goalSummaryFromCards(
  KnowledgeGoalVisual visual,
  Iterable<KnowledgeCard> cards,
  int nowMs, {
  String? displayName,
  String? customGoalName,
}) {
  final goalCards = cards.toList(growable: false);
  final total = goalCards.length;
  final due = goalCards.where((card) => card.dueAt <= nowMs).length;
  final reviewed = goalCards.where((card) => card.reviewCount > 0).length;
  final masterySum = goalCards.fold<int>(
    0,
    (sum, card) => sum + card.masteryLevel,
  );
  final moduleKeys = goalCards
      .map((card) => card.moduleKey)
      .where((key) => key.trim().isNotEmpty)
      .toSet();

  return KnowledgeGoalSummary(
    visual: visual,
    displayName: displayName ?? visual.name,
    customGoalName: customGoalName,
    totalCards: total,
    dueCards: due,
    reviewedCards: reviewed,
    averageMastery: total == 0 ? 0 : masterySum / total,
    moduleCount: moduleKeys.isEmpty ? visual.modules.length : moduleKeys.length,
  );
}

String _customGoalName(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '自定义目标' : trimmed;
}

String? _storedCustomGoalName(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

class KnowledgeGoalSummary {
  const KnowledgeGoalSummary({
    required this.visual,
    required this.displayName,
    required this.customGoalName,
    required this.totalCards,
    required this.dueCards,
    required this.reviewedCards,
    required this.averageMastery,
    required this.moduleCount,
  });

  final KnowledgeGoalVisual visual;
  final String displayName;
  final String? customGoalName;
  final int totalCards;
  final int dueCards;
  final int reviewedCards;
  final double averageMastery;
  final int moduleCount;
}

class KnowledgeDeckSummary {
  const KnowledgeDeckSummary({
    required this.visual,
    required this.totalCards,
    required this.dueCards,
    required this.reviewedCards,
    required this.averageMastery,
  });

  final KnowledgeDeckVisual visual;
  final int totalCards;
  final int dueCards;
  final int reviewedCards;
  final double averageMastery;
}

bool isWeakKnowledgeCard(KnowledgeCard card) {
  return card.masteryLevel <= 2 ||
      (card.reviewCount > 0 && card.correctStreak == 0);
}

bool isMasteredKnowledgeCard(KnowledgeCard card) {
  return card.masteryLevel >= 4 && card.correctStreak >= 1;
}

class KnowledgeCardReviewStats {
  const KnowledgeCardReviewStats({
    required this.totalCards,
    required this.dueCards,
    required this.weakCards,
    required this.masteredCards,
    required this.reviewedCards,
    required this.unreviewedCards,
    required this.recentlyReviewedCards,
    required this.averageMastery,
  });

  factory KnowledgeCardReviewStats.fromCards(
    Iterable<KnowledgeCard> cards,
    int nowMs,
  ) {
    final items = cards.toList(growable: false);
    final total = items.length;
    final recentThreshold = nowMs - const Duration(days: 7).inMilliseconds;
    final masterySum = items.fold<int>(
      0,
      (sum, card) => sum + card.masteryLevel,
    );

    return KnowledgeCardReviewStats(
      totalCards: total,
      dueCards: items.where((card) => card.dueAt <= nowMs).length,
      weakCards: items.where(isWeakKnowledgeCard).length,
      masteredCards: items.where(isMasteredKnowledgeCard).length,
      reviewedCards: items.where((card) => card.reviewCount > 0).length,
      unreviewedCards: items.where((card) => card.reviewCount == 0).length,
      recentlyReviewedCards: items
          .where(
            (card) =>
                card.lastReviewedAt != null &&
                card.lastReviewedAt! >= recentThreshold,
          )
          .length,
      averageMastery: total == 0 ? 0 : masterySum / total,
    );
  }

  final int totalCards;
  final int dueCards;
  final int weakCards;
  final int masteredCards;
  final int reviewedCards;
  final int unreviewedCards;
  final int recentlyReviewedCards;
  final double averageMastery;

  double ratio(int value) {
    if (totalCards == 0) return 0;
    return value / totalCards;
  }
}

final knowledgeSpaceSummariesProvider =
    FutureProvider<List<KnowledgeSpaceSummary>>((ref) async {
      final cards = await ref.watch(knowledgeCardsProvider.future);
      final sources = await ref.watch(
        knowledgeSourcesWithProgressProvider.future,
      );
      final archivedKeys = await ref.watch(
        archivedKnowledgeSpacesProvider.future,
      );
      final createdSpaces = await ref.watch(
        createdKnowledgeSpacesProvider.future,
      );
      final aliases = {
        for (final item in createdSpaces) item.spaceKey: item.spaceName,
      };
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final spaces = <String, _KnowledgeSpaceAccumulator>{};

      _KnowledgeSpaceAccumulator bucketFor({
        required String? key,
        required String? name,
      }) {
        final spaceKey = _spaceKey(key, name);
        return spaces.putIfAbsent(
          spaceKey,
          () => _KnowledgeSpaceAccumulator(
            spaceKey: spaceKey,
            spaceName: _spaceName(spaceKey, name, aliases: aliases),
          ),
        );
      }

      for (final card in cards) {
        bucketFor(key: card.goalKey, name: card.goalName).addCard(card, nowMs);
      }
      for (final item in sources) {
        bucketFor(
          key: item.source.goalKey,
          name: item.source.goalName,
        ).addSource(item);
      }
      for (final space in createdSpaces) {
        spaces.putIfAbsent(
          space.spaceKey,
          () => _KnowledgeSpaceAccumulator(
            spaceKey: space.spaceKey,
            spaceName: space.spaceName,
          ),
        );
      }

      if (spaces.isEmpty) {
        spaces[_defaultKnowledgeSpaceKey] = _KnowledgeSpaceAccumulator(
          spaceKey: _defaultKnowledgeSpaceKey,
          spaceName: _defaultKnowledgeSpaceName,
        );
      }

      final summaries = spaces.values
          .map((item) => item.toSummary())
          .where((item) => !archivedKeys.contains(item.spaceKey))
          .toList(growable: false);
      summaries.sort((a, b) {
        final activityCompare = b.lastUpdatedAt.compareTo(a.lastUpdatedAt);
        if (activityCompare != 0) return activityCompare;
        final pendingCompare = b.pendingChunkCount.compareTo(
          a.pendingChunkCount,
        );
        if (pendingCompare != 0) return pendingCompare;
        return b.cardCount.compareTo(a.cardCount);
      });
      return summaries;
    });

final allKnowledgeSpaceSummariesProvider =
    FutureProvider<List<KnowledgeSpaceSummary>>((ref) async {
      final cards = await ref.watch(knowledgeCardsProvider.future);
      final sources = await ref.watch(
        knowledgeSourcesWithProgressProvider.future,
      );
      final createdSpaces = await ref.watch(
        createdKnowledgeSpacesProvider.future,
      );
      final aliases = {
        for (final item in createdSpaces) item.spaceKey: item.spaceName,
      };
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final spaces = <String, _KnowledgeSpaceAccumulator>{};

      _KnowledgeSpaceAccumulator bucketFor({
        required String? key,
        required String? name,
      }) {
        final spaceKey = _spaceKey(key, name);
        return spaces.putIfAbsent(
          spaceKey,
          () => _KnowledgeSpaceAccumulator(
            spaceKey: spaceKey,
            spaceName: _spaceName(spaceKey, name, aliases: aliases),
          ),
        );
      }

      for (final card in cards) {
        bucketFor(key: card.goalKey, name: card.goalName).addCard(card, nowMs);
      }
      for (final item in sources) {
        bucketFor(
          key: item.source.goalKey,
          name: item.source.goalName,
        ).addSource(item);
      }
      for (final space in createdSpaces) {
        spaces.putIfAbsent(
          space.spaceKey,
          () => _KnowledgeSpaceAccumulator(
            spaceKey: space.spaceKey,
            spaceName: space.spaceName,
          ),
        );
      }

      if (spaces.isEmpty) {
        spaces[_defaultKnowledgeSpaceKey] = _KnowledgeSpaceAccumulator(
          spaceKey: _defaultKnowledgeSpaceKey,
          spaceName: _defaultKnowledgeSpaceName,
        );
      }

      final summaries = spaces.values
          .map((item) => item.toSummary())
          .toList(growable: false);
      summaries.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
      return summaries;
    });

final archivedKnowledgeSpacesProvider = FutureProvider<Set<String>>((
  ref,
) async {
  final repo = ref.watch(settingRepositoryProvider);
  final raw = await repo.getSetting(_archivedKnowledgeSpacesKey);
  if (raw == null || raw.trim().isEmpty) return const <String>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
  } catch (e) { debugPrint('knowledge spaces parse failed: $e'); }
  return const <String>{};
});

final createdKnowledgeSpacesProvider = FutureProvider<List<KnowledgeSpaceSeed>>(
  (ref) async {
    final repo = ref.watch(settingRepositoryProvider);
    final raw = await repo.getSetting(_createdKnowledgeSpacesKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(KnowledgeSpaceSeed.fromJson)
            .where(
              (item) => item.spaceKey.isNotEmpty && item.spaceName.isNotEmpty,
            )
            .toList(growable: false);
      }
    } catch (e) { debugPrint('knowledge spaces parse failed: $e'); }
    return const [];
  },
);

final recentKnowledgeSpaceProvider = FutureProvider<KnowledgeSpaceSummary>((
  ref,
) async {
  final repo = ref.watch(settingRepositoryProvider);
  final raw = await repo.getSetting(_recentKnowledgeSpaceKey);
  final spaces = await ref.watch(knowledgeSpaceSummariesProvider.future);
  if (spaces.isEmpty) {
    return const KnowledgeSpaceSummary(
      spaceKey: _defaultKnowledgeSpaceKey,
      spaceName: _defaultKnowledgeSpaceName,
      sourceCount: 0,
      cardCount: 0,
      dueCardCount: 0,
      weakCardCount: 0,
      pendingChunkCount: 0,
      lastUpdatedAt: 0,
    );
  }
  if (raw != null && raw.trim().isNotEmpty) {
    for (final space in spaces) {
      if (space.spaceKey == raw.trim()) return space;
    }
  }
  return spaces.first;
});

final knowledgeSpaceSearchProvider =
    FutureProvider.family<
      KnowledgeSpaceSearchResult,
      KnowledgeSpaceSearchQuery
    >((ref, request) async {
      final query = request.query.trim();
      if (query.isEmpty) return const KnowledgeSpaceSearchResult.empty();

      final q = query.toLowerCase();
      final spaces = await ref.watch(knowledgeSpaceSummariesProvider.future);
      final sources = await ref.watch(
        knowledgeSourcesWithProgressProvider.future,
      );
      final cards = await ref.watch(knowledgeCardsProvider.future);
      final sourceRepo = ref.watch(knowledgeSourceRepositoryProvider);
      final chunkResults = await sourceRepo.searchChunks(
        query: query,
        goalKey: request.spaceKey == null
            ? null
            : _goalKeyForSpaceKey(request.spaceKey!),
        goalName:
            request.spaceKey != null &&
                _goalKeyForSpaceKey(request.spaceKey!) == 'custom'
            ? request.spaceName
            : null,
        limit: request.limit,
      );

      bool inScope(String? key, String? name) {
        if (request.spaceKey == null) return true;
        return _spaceKey(key, name) == request.spaceKey;
      }

      final matchedSpaces = request.spaceKey == null
          ? spaces
                .where((space) => space.spaceName.toLowerCase().contains(q))
                .take(request.limit)
                .toList(growable: false)
          : const <KnowledgeSpaceSummary>[];
      final matchedSources = sources
          .where(
            (item) =>
                inScope(item.source.goalKey, item.source.goalName) &&
                (_contains(item.source.title, q) ||
                    _contains(item.source.type, q) ||
                    _contains(item.source.sourcePath, q)),
          )
          .take(request.limit)
          .toList(growable: false);
      final matchedCards = cards
          .where(
            (card) =>
                inScope(card.goalKey, card.goalName) &&
                (_contains(card.title, q) ||
                    _contains(card.question, q) ||
                    _contains(card.answer, q) ||
                    _contains(card.subject, q)),
          )
          .take(request.limit)
          .toList(growable: false);

      return KnowledgeSpaceSearchResult(
        spaces: matchedSpaces,
        sources: matchedSources,
        cards: matchedCards,
        chunks: chunkResults,
      );
    });

Future<void> rememberRecentKnowledgeSpace(dynamic ref, String spaceKey) async {
  final trimmed = spaceKey.trim();
  if (trimmed.isEmpty) return;
  await ref
      .read(settingRepositoryProvider)
      .setSetting(_recentKnowledgeSpaceKey, trimmed);
  ref.invalidate(recentKnowledgeSpaceProvider);
}

Future<KnowledgeSpaceSeed> createKnowledgeSpace(
  dynamic ref, {
  required String spaceName,
}) async {
  final name = spaceName.trim();
  if (name.isEmpty) {
    throw ArgumentError.value(spaceName, 'spaceName', '空间名称不能为空');
  }
  final seed = KnowledgeSpaceSeed(spaceKey: 'custom::$name', spaceName: name);
  final current = [...await ref.read(createdKnowledgeSpacesProvider.future)];
  final existingIndex = current.indexWhere(
    (item) => item.spaceKey == seed.spaceKey,
  );
  if (existingIndex == -1) {
    current.add(seed);
  } else {
    current[existingIndex] = seed;
  }
  await ref
      .read(settingRepositoryProvider)
      .setSetting(
        _createdKnowledgeSpacesKey,
        jsonEncode(current.map((item) => item.toJson()).toList()),
      );
  await rememberRecentKnowledgeSpace(ref, seed.spaceKey);
  ref.invalidate(createdKnowledgeSpacesProvider);
  ref.invalidate(knowledgeSpaceSummariesProvider);
  ref.invalidate(allKnowledgeSpaceSummariesProvider);
  return seed;
}

Future<KnowledgeSpaceSeed> renameKnowledgeSpace(
  dynamic ref, {
  required String spaceKey,
  required String newName,
}) async {
  final name = newName.trim();
  if (name.isEmpty) {
    throw ArgumentError.value(newName, 'newName', '空间名称不能为空');
  }
  final customSpace = spaceKey.startsWith('custom::');
  final oldName = customSpace
      ? spaceKey.substring('custom::'.length).trim()
      : '';
  final next = KnowledgeSpaceSeed(
    spaceKey: customSpace ? 'custom::$name' : spaceKey,
    spaceName: name,
  );
  final current = [...await ref.read(createdKnowledgeSpacesProvider.future)];
  final existingIndex = current.indexWhere((item) => item.spaceKey == spaceKey);
  if (existingIndex == -1) {
    current.add(next);
  } else {
    current[existingIndex] = next;
  }
  await ref
      .read(settingRepositoryProvider)
      .setSetting(
        _createdKnowledgeSpacesKey,
        jsonEncode(current.map((item) => item.toJson()).toList()),
      );
  if (customSpace) {
    await ref
        .read(knowledgeCardRepositoryProvider)
        .renameCustomGoal(oldGoalName: oldName, newGoalName: name);
    await ref
        .read(knowledgeSourceRepositoryProvider)
        .renameCustomGoal(oldGoalName: oldName, newGoalName: name);
  }
  await rememberRecentKnowledgeSpace(ref, next.spaceKey);
  ref.invalidate(createdKnowledgeSpacesProvider);
  ref.invalidate(knowledgeCardsProvider);
  ref.invalidate(knowledgeSourcesProvider);
  ref.invalidate(knowledgeSourcesWithProgressProvider);
  ref.invalidate(knowledgeSpaceSummariesProvider);
  ref.invalidate(allKnowledgeSpaceSummariesProvider);
  return next;
}

Future<void> resetKnowledgeSpaceAlias(
  dynamic ref, {
  required String spaceKey,
}) async {
  final trimmed = spaceKey.trim();
  if (trimmed.isEmpty || trimmed == _defaultKnowledgeSpaceKey) return;
  if (trimmed.startsWith('custom::')) return;

  final current = [...await ref.read(createdKnowledgeSpacesProvider.future)];
  current.removeWhere((item) => item.spaceKey == trimmed);
  await ref
      .read(settingRepositoryProvider)
      .setSetting(
        _createdKnowledgeSpacesKey,
        jsonEncode(current.map((item) => item.toJson()).toList()),
      );
  ref.invalidate(createdKnowledgeSpacesProvider);
  ref.invalidate(knowledgeSpaceSummariesProvider);
  ref.invalidate(allKnowledgeSpaceSummariesProvider);
}

Future<void> setKnowledgeSpaceArchived(
  dynamic ref, {
  required String spaceKey,
  required bool archived,
}) async {
  final trimmed = spaceKey.trim();
  if (trimmed.isEmpty) return;
  final current = <String>{
    ...await ref.read(archivedKnowledgeSpacesProvider.future),
  };
  if (archived) {
    current.add(trimmed);
  } else {
    current.remove(trimmed);
  }
  await ref
      .read(settingRepositoryProvider)
      .setSetting(_archivedKnowledgeSpacesKey, jsonEncode(current.toList()));
  ref.invalidate(archivedKnowledgeSpacesProvider);
  ref.invalidate(knowledgeSpaceSummariesProvider);
  ref.invalidate(allKnowledgeSpaceSummariesProvider);
}

final knowledgeSpaceCardsProvider =
    FutureProvider.family<List<KnowledgeCard>, String>((ref, spaceKey) async {
      final cards = await ref.watch(knowledgeCardsProvider.future);
      return cards
          .where((card) => _spaceKey(card.goalKey, card.goalName) == spaceKey)
          .toList(growable: false);
    });

final knowledgeSpaceSourcesProvider =
    FutureProvider.family<List<KnowledgeSourceWithProgress>, String>((
      ref,
      spaceKey,
    ) async {
      final sources = await ref.watch(
        knowledgeSourcesWithProgressProvider.future,
      );
      return sources
          .where(
            (item) =>
                _spaceKey(item.source.goalKey, item.source.goalName) ==
                spaceKey,
          )
          .toList(growable: false);
    });

class KnowledgeSpaceSummary {
  const KnowledgeSpaceSummary({
    required this.spaceKey,
    required this.spaceName,
    required this.sourceCount,
    required this.cardCount,
    required this.dueCardCount,
    required this.weakCardCount,
    required this.pendingChunkCount,
    required this.lastUpdatedAt,
  });

  final String spaceKey;
  final String spaceName;
  final int sourceCount;
  final int cardCount;
  final int dueCardCount;
  final int weakCardCount;
  final int pendingChunkCount;
  final int lastUpdatedAt;

  bool get hasContent => sourceCount > 0 || cardCount > 0;

  String get statusText {
    if (!hasContent) return '导入资料，自动生成知识卡';
    if (dueCardCount > 0) return '今日 $dueCardCount 张待复习';
    if (pendingChunkCount > 0) return '还有 $pendingChunkCount 个片段待沉淀';
    if (weakCardCount > 0) return '$weakCardCount 张薄弱卡建议复习';
    return '资料和知识卡已整理好';
  }
}

class KnowledgeSpaceSeed {
  const KnowledgeSpaceSeed({required this.spaceKey, required this.spaceName});

  factory KnowledgeSpaceSeed.fromJson(Map<String, dynamic> json) {
    return KnowledgeSpaceSeed(
      spaceKey: json['spaceKey']?.toString().trim() ?? '',
      spaceName: json['spaceName']?.toString().trim() ?? '',
    );
  }

  final String spaceKey;
  final String spaceName;

  Map<String, String> toJson() => {
    'spaceKey': spaceKey,
    'spaceName': spaceName,
  };
}

class KnowledgeSpaceSearchQuery {
  const KnowledgeSpaceSearchQuery({
    required this.query,
    this.spaceKey,
    this.spaceName,
    this.limit = 8,
  });

  final String query;
  final String? spaceKey;
  final String? spaceName;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is KnowledgeSpaceSearchQuery &&
        other.query == query &&
        other.spaceKey == spaceKey &&
        other.spaceName == spaceName &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(query, spaceKey, spaceName, limit);
}

class KnowledgeSpaceSearchResult {
  const KnowledgeSpaceSearchResult({
    required this.spaces,
    required this.sources,
    required this.cards,
    required this.chunks,
  });

  const KnowledgeSpaceSearchResult.empty()
    : spaces = const [],
      sources = const [],
      cards = const [],
      chunks = const [];

  final List<KnowledgeSpaceSummary> spaces;
  final List<KnowledgeSourceWithProgress> sources;
  final List<KnowledgeCard> cards;
  final List<KnowledgeChunkSearchResult> chunks;

  bool get isEmpty =>
      spaces.isEmpty && sources.isEmpty && cards.isEmpty && chunks.isEmpty;

  int get totalCount =>
      spaces.length + sources.length + cards.length + chunks.length;
}

class _KnowledgeSpaceAccumulator {
  _KnowledgeSpaceAccumulator({required this.spaceKey, required this.spaceName});

  final String spaceKey;
  final String spaceName;
  int sourceCount = 0;
  int cardCount = 0;
  int dueCardCount = 0;
  int weakCardCount = 0;
  int pendingChunkCount = 0;
  int lastUpdatedAt = 0;

  void addCard(KnowledgeCard card, int nowMs) {
    if (card.archived) return;
    cardCount++;
    if (card.dueAt <= nowMs) dueCardCount++;
    if (isWeakKnowledgeCard(card)) weakCardCount++;
    lastUpdatedAt = _max(lastUpdatedAt, card.updatedAt);
  }

  void addSource(KnowledgeSourceWithProgress item) {
    sourceCount++;
    pendingChunkCount += item.progress.pendingChunkCount;
    lastUpdatedAt = _max(lastUpdatedAt, item.source.updatedAt);
  }

  KnowledgeSpaceSummary toSummary() {
    return KnowledgeSpaceSummary(
      spaceKey: spaceKey,
      spaceName: spaceName,
      sourceCount: sourceCount,
      cardCount: cardCount,
      dueCardCount: dueCardCount,
      weakCardCount: weakCardCount,
      pendingChunkCount: pendingChunkCount,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}

const _defaultKnowledgeSpaceKey = 'custom';
const _defaultKnowledgeSpaceName = '默认知识空间';
const _archivedKnowledgeSpacesKey = 'knowledge_archived_spaces';
const _recentKnowledgeSpaceKey = 'knowledge_recent_space';
const _createdKnowledgeSpacesKey = 'knowledge_created_spaces';

String _spaceKey(String? key, String? name) {
  final trimmedKey = key?.trim();
  if (trimmedKey != null && trimmedKey.isNotEmpty) {
    if (trimmedKey == 'custom') {
      final customName = name?.trim();
      if (customName != null && customName.isNotEmpty) {
        return 'custom::$customName';
      }
    }
    return trimmedKey;
  }
  final trimmedName = name?.trim();
  if (trimmedName != null && trimmedName.isNotEmpty) {
    return 'custom::$trimmedName';
  }
  return _defaultKnowledgeSpaceKey;
}

String _spaceName(
  String key,
  String? name, {
  Map<String, String> aliases = const {},
}) {
  final alias = aliases[key]?.trim();
  if (alias != null && alias.isNotEmpty) return alias;
  final trimmedName = name?.trim();
  if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
  if (key == _defaultKnowledgeSpaceKey || key.startsWith('custom::')) {
    return _defaultKnowledgeSpaceName;
  }
  return KnowledgeCardAssets.goalForKey(key).name;
}

int _max(int a, int b) => a > b ? a : b;

String _goalKeyForSpaceKey(String spaceKey) {
  if (spaceKey.startsWith('custom::')) return 'custom';
  return spaceKey;
}

bool _contains(String? value, String query) {
  final text = value?.trim().toLowerCase();
  return text != null && text.contains(query);
}

/// 用户选中的目标模板 key 列表。
/// 为空/null 时返回所有 goalTemplates 的 key（兼容旧用户）。
final selectedGoalKeysProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final raw = await repo.getSetting('knowledge_selected_goals');
  if (raw == null || raw.trim().isEmpty) {
    return KnowledgeCardAssets.goalTemplates.map((g) => g.key).toList();
  }
  try {
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    if (list.isEmpty) {
      return KnowledgeCardAssets.goalTemplates.map((g) => g.key).toList();
    }
    return list;
  } catch (_) {
    return KnowledgeCardAssets.goalTemplates.map((g) => g.key).toList();
  }
});

/// 是否已完成新手引导。
final knowledgeOnboardingDoneProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final raw = await repo.getSetting('knowledge_onboarding_done');
  return raw == 'true';
});

/// 根据用户选中的目标过滤后的目标摘要列表。
/// 如果用户未选择任何目标（兼容旧用户），返回全部。
final filteredKnowledgeGoalSummariesProvider =
    FutureProvider<List<KnowledgeGoalSummary>>((ref) async {
      final allSummaries = await ref.watch(
        knowledgeGoalSummariesProvider.future,
      );
      final selectedKeys = await ref.watch(selectedGoalKeysProvider.future);

      // 如果选中了全部 key 或 selectedKeys 包含所有 goalTemplates 的 key，
      // 说明是旧用户兼容模式，直接返回全部
      final allKeys = KnowledgeCardAssets.goalTemplates
          .map((g) => g.key)
          .toList();
      final isAllSelected =
          selectedKeys.length >= allKeys.length &&
          selectedKeys.toSet().containsAll(allKeys.toSet());

      if (isAllSelected) return allSummaries;

      // 过滤：只保留选中的目标 + custom 目标（始终显示）
      return allSummaries.where((s) {
        return selectedKeys.contains(s.visual.key) || s.visual.key == 'custom';
      }).toList();
    });
// =============================================================================
// Flash Review Page Providers
// =============================================================================

/// 今日复习进度
// =============================================================================
// Flash Review Page Providers
// =============================================================================

/// 今日复习进度
class TodayReviewProgress {
  const TodayReviewProgress({required this.reviewed, required this.total});

  final int reviewed;
  final int total;

  double get progress => total > 0 ? reviewed / total : 0.0;
}

/// 今日复习进度 Provider
final todayReviewProgressProvider = FutureProvider<TodayReviewProgress>((
  ref,
) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final now = DateTime.now();
  final startOfDay = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;
  final dueCards = cards.where((c) => c.dueAt <= nowMs).length;
  final reviewedToday = cards
      .where((c) => c.lastReviewedAt != null && c.lastReviewedAt! >= startOfDay)
      .length;
  return TodayReviewProgress(reviewed: reviewedToday, total: dueCards);
});

/// 今日待复习卡片预览（前 3 张，按 dueAt 排序）
final dueCardsPreviewProvider = FutureProvider<List<KnowledgeCard>>((
  ref,
) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final due = cards.where((c) => !c.archived && c.dueAt <= nowMs).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  return due.take(3).toList();
});

/// AI 推荐复习卡 Provider
final aiRecommendedCardsProvider = FutureProvider<List<KnowledgeCard>>((
  ref,
) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final weak = cards.where(isWeakKnowledgeCard).toList();
  final dueSoon = cards
      .where(
        (c) =>
            c.dueAt > nowMs &&
            c.dueAt <= nowMs + const Duration(hours: 24).inMilliseconds,
      )
      .toList();
  final highError = cards
      .where((c) => c.reviewCount > 0 && c.correctStreak == 0)
      .toList();
  // 合并去重，排序：薄弱 > 即将过期 > 高频错误
  final seen = <int>{};
  final result = <KnowledgeCard>[];
  for (final card in [...weak, ...dueSoon, ...highError]) {
    if (seen.add(card.id)) result.add(card);
    if (result.length >= 10) break;
  }
  return result;
});
