import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sort_button.dart';

import '../../core/database/app_database.dart';
import '../../core/services/image_service.dart';
import 'dashboard_provider.dart';

// =============================================================================
// 日记 Provider
// =============================================================================

/// 按日期获取日记列表（FutureProvider.family）
///
/// 用法：`ref.watch(journalsProvider(date))`
final journalsProvider =
    FutureProvider.family<List<DailyJournal>, DateTime>((ref, date) async {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getJournalsByDate(date);
});

/// 今日日记列表
final todayJournalsProvider = FutureProvider<List<DailyJournal>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getJournalsByDate(DateTime.now());
});

/// 今日日记篇数
final todayJournalCountProvider = FutureProvider<int>((ref) async {
  final journals = await ref.watch(todayJournalsProvider.future);
  return journals.length;
});

/// 最近 5 条日记（按创建时间倒序）
final recentJournalsProvider = FutureProvider<List<DailyJournal>>((ref) async {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.dailyJournals)
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ..limit(5);
  return query.get();
});

/// 全部日记中出现过的标签（去重）
final allJournalTagsProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final journals = await (db.select(db.dailyJournals)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  final tagSet = <String>{};
  for (final j in journals) {
    if (j.tags != null && j.tags!.isNotEmpty) {
      try {
        final list = (jsonDecode(j.tags!) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
        tagSet.addAll(list);
      } catch (_) {
        // skip malformed tags
      }
    }
  }
  return tagSet.toList();
});

/// 按标签筛选日记
final journalsByTagProvider =
    FutureProvider.family<List<DailyJournal>, String>((ref, tag) async {
  final db = ref.watch(databaseProvider);
  final journals = await (db.select(db.dailyJournals)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  // Drift doesn't support JSON array contains natively, filter in Dart
  return journals.where((j) {
    if (j.tags == null || j.tags!.isEmpty) return false;
    try {
      final list =
          (jsonDecode(j.tags!) as List<dynamic>).map((e) => e.toString());
      return list.contains(tag);
    } catch (_) {
      return false;
    }
  }).toList();
});

/// 单篇日记详情（按 ID）
final journalByIdProvider =
    FutureProvider.family<DailyJournal?, int>((ref, id) async {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getJournalById(id);
});

// =============================================================================
// 排序状态 Provider
// =============================================================================

/// 日记排序方式
final journalSortProvider = StateProvider<SortOption>((ref) => SortOption.newest);

// =============================================================================
// 图片服务 Provider
// =============================================================================

/// 图片选取与本地存储服务
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});
