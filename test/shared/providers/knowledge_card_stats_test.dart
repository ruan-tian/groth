import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/providers/knowledge_card_provider.dart';

KnowledgeCard _card({
  required int now,
  int masteryLevel = 0,
  int reviewCount = 0,
  int correctStreak = 0,
  int? lastReviewedAt,
  int? dueAt,
}) {
  return KnowledgeCard(
    id: 1,
    deckKey: 'computer',
    goalKey: 'kaoyan_computer',
    goalName: null,
    moduleKey: 'operating_system',
    moduleName: null,
    subject: '操作系统',
    title: '进程与线程',
    question: '进程和线程有什么区别？',
    answer: '进程是资源分配单位，线程是 CPU 调度单位。',
    explanation: null,
    tags: null,
    sourceStudyId: null,
    masteryLevel: masteryLevel,
    reviewCount: reviewCount,
    correctStreak: correctStreak,
    lastReviewedAt: lastReviewedAt,
    dueAt: dueAt ?? now,
    archived: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('KnowledgeCardReviewStats counts review health buckets', () {
    final now = DateTime(2026, 6, 15).millisecondsSinceEpoch;
    final stats = KnowledgeCardReviewStats.fromCards([
      _card(now: now, masteryLevel: 0),
      _card(
        now: now,
        masteryLevel: 4,
        reviewCount: 3,
        correctStreak: 2,
        lastReviewedAt: now,
        dueAt: now + const Duration(days: 3).inMilliseconds,
      ),
      _card(
        now: now,
        masteryLevel: 4,
        reviewCount: 2,
        correctStreak: 0,
        lastReviewedAt: now - const Duration(days: 10).inMilliseconds,
        dueAt: now - 1,
      ),
    ], now);

    expect(stats.totalCards, 3);
    expect(stats.dueCards, 2);
    expect(stats.weakCards, 2);
    expect(stats.masteredCards, 1);
    expect(stats.unreviewedCards, 1);
    expect(stats.recentlyReviewedCards, 1);
    expect(stats.averageMastery, closeTo(8 / 3, 0.001));
  });
}
