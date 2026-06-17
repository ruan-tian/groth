import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/repository_providers.dart';

final journalStreakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final journals = await repo.getJournalsByRange(
    now.subtract(const Duration(days: 90)),
    now,
  );

  final dates = journals.map((journal) => journal.journalDate).toSet();
  var streak = 0;
  for (var i = 0; i < 90; i++) {
    final date = now.subtract(Duration(days: i));
    final dateStr = GrowthDateUtils.formatDateKey(date);
    if (!dates.contains(dateStr)) break;
    streak++;
  }
  return streak;
});

final onThisDayProvider = FutureProvider<List<DailyJournal>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final lastYear = DateTime(now.year - 1, now.month, now.day);
  return repo.getJournalsByDate(lastYear);
});

final totalJournalCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final count = db.dailyJournals.id.count();
  final query = db.selectOnly(db.dailyJournals)..addColumns([count]);
  final result = await query.getSingle();
  return result.read(count) ?? 0;
});

final monthlyJournalCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month);
  final journals = await repo.getJournalsByRange(start, now);
  return journals.length;
});

final selectedHeatmapYearProvider = StateProvider<int>(
  (ref) => DateTime.now().year,
);

final journalHeatmapProvider = FutureProvider.family<Map<DateTime, int>, int>((
  ref,
  year,
) async {
  final repo = ref.watch(journalRepositoryProvider);
  final start = DateTime(year);
  final end = DateTime(year, 12, 31);
  final journals = await repo.getJournalsByRange(start, end);
  final data = <DateTime, int>{};
  for (final journal in journals) {
    try {
      final date = DateTime.parse(journal.journalDate);
      final key = DateTime(date.year, date.month, date.day);
      data[key] = (data[key] ?? 0) + 1;
    } catch (_) {
      // Ignore malformed legacy dates.
    }
  }
  return data;
});
