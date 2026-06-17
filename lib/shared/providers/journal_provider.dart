import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sort_button.dart';

import '../../core/database/app_database.dart';
import '../../core/services/image_service.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

enum JournalFolderFilterKind { all, uncategorized, folder }

class JournalFolderSelection {
  const JournalFolderSelection._(this.kind, this.folderId);

  const JournalFolderSelection.all()
    : this._(JournalFolderFilterKind.all, null);

  const JournalFolderSelection.uncategorized()
    : this._(JournalFolderFilterKind.uncategorized, null);

  const JournalFolderSelection.folder(int id)
    : this._(JournalFolderFilterKind.folder, id);

  final JournalFolderFilterKind kind;
  final int? folderId;

  bool get isAll => kind == JournalFolderFilterKind.all;

  @override
  bool operator ==(Object other) {
    return other is JournalFolderSelection &&
        other.kind == kind &&
        other.folderId == folderId;
  }

  @override
  int get hashCode => Object.hash(kind, folderId);
}

List<String> _parseTagsSafe(String? tagsString) {
  if (tagsString == null || tagsString.isEmpty) return const [];
  try {
    final decoded = jsonDecode(tagsString);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {
    // JSON 解析失败，回退到逗号分隔
  }
  return tagsString.split(',').where((t) => t.trim().isNotEmpty).toList();
}

// =============================================================================
// 日记 Provider
// =============================================================================

/// 按日期获取日记列表（FutureProvider.family）
///
/// 用法：`ref.watch(journalsProvider(date))`
final journalsProvider = FutureProvider.family<List<DailyJournal>, DateTime>((
  ref,
  date,
) async {
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
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getRecentJournals();
});

final journalFoldersProvider = FutureProvider<List<JournalFolder>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getFolders();
});

final selectedJournalFolderProvider = StateProvider<JournalFolderSelection>(
  (ref) => const JournalFolderSelection.all(),
);

final journalsByFolderProvider =
    FutureProvider.family<List<DailyJournal>, JournalFolderSelection>((
      ref,
      selection,
    ) async {
      final repo = ref.watch(journalRepositoryProvider);
      switch (selection.kind) {
        case JournalFolderFilterKind.all:
          return repo.getRecentJournals(limit: 20);
        case JournalFolderFilterKind.uncategorized:
          return repo.getJournalsByFolder(uncategorizedOnly: true);
        case JournalFolderFilterKind.folder:
          return repo.getJournalsByFolder(folderId: selection.folderId);
      }
    });

/// 全部日记中出现过的标签（去重）
final allJournalTagsProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final journals = await (db.select(
    db.dailyJournals,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  final tagSet = <String>{};
  for (final j in journals) {
    tagSet.addAll(_parseTagsSafe(j.tags));
  }
  return tagSet.toList();
});

/// 按标签筛选日记
final journalsByTagProvider = FutureProvider.family<List<DailyJournal>, String>(
  (ref, tag) async {
    final db = ref.watch(databaseProvider);
    final journals = await (db.select(
      db.dailyJournals,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

    // Drift doesn't support JSON array contains natively, filter in Dart
    return journals.where((j) {
      return _parseTagsSafe(j.tags).contains(tag);
    }).toList();
  },
);

/// 单篇日记详情（按 ID）
final journalByIdProvider = FutureProvider.family<DailyJournal?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getJournalById(id);
});

// =============================================================================
// 排序状态 Provider
// =============================================================================

/// 日记排序方式
final journalSortProvider = StateProvider<SortOption>(
  (ref) => SortOption.newest,
);

// =============================================================================
// 图片服务 Provider
// =============================================================================

/// 图片选取与本地存储服务
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});
