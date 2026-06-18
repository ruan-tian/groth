import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/repositories/knowledge_card_repository.dart';
import '../../features/study/utils/knowledge_card_assets.dart';
import 'repository_providers.dart';
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
  final allSummaries = await ref.watch(knowledgeGoalSummariesProvider.future);
  final selectedKeys = await ref.watch(selectedGoalKeysProvider.future);

  // 如果选中了全部 key 或 selectedKeys 包含所有 goalTemplates 的 key，
  // 说明是旧用户兼容模式，直接返回全部
  final allKeys = KnowledgeCardAssets.goalTemplates
      .map((g) => g.key)
      .toList();
  final isAllSelected = selectedKeys.length >= allKeys.length &&
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
final todayReviewProgressProvider = FutureProvider<TodayReviewProgress>((ref) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final dueCards = cards.where((c) => c.dueAt <= nowMs).length;
  final reviewedToday = cards.where((c) =>
    c.lastReviewedAt != null && c.lastReviewedAt! >= startOfDay,
  ).length;
  return TodayReviewProgress(reviewed: reviewedToday, total: dueCards);
});

/// 今日待复习卡片预览（前 3 张，按 dueAt 排序）
final dueCardsPreviewProvider = FutureProvider<List<KnowledgeCard>>((ref) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final due = cards.where((c) => !c.archived && c.dueAt <= nowMs).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  return due.take(3).toList();
});

/// AI 推荐复习卡 Provider
final aiRecommendedCardsProvider = FutureProvider<List<KnowledgeCard>>((ref) async {
  final cards = await ref.watch(knowledgeCardsProvider.future);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final weak = cards.where(isWeakKnowledgeCard).toList();
  final dueSoon = cards.where((c) =>
    c.dueAt > nowMs && c.dueAt <= nowMs + const Duration(hours: 24).inMilliseconds,
  ).toList();
  final highError = cards.where((c) =>
    c.reviewCount > 0 && c.correctStreak == 0,
  ).toList();
  // 合并去重，排序：薄弱 > 即将过期 > 高频错误
  final seen = <int>{};
  final result = <KnowledgeCard>[];
  for (final card in [...weak, ...dueSoon, ...highError]) {
    if (seen.add(card.id)) result.add(card);
    if (result.length >= 10) break;
  }
  return result;
});
