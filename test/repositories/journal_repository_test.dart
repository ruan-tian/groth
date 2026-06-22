import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/journal_repository.dart';

DailyJournalsCompanion _journal({
  String title = 'Daily note',
  String date = '2026-06-11',
  int? createdAt,
}) {
  final now = createdAt ?? DateTime.now().millisecondsSinceEpoch;
  return DailyJournalsCompanion.insert(
    journalDate: date,
    title: title,
    content: 'Today was steady and bright.',
    plainText: const Value('Today was steady and bright.'),
    wordCount: const Value(31),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late JournalRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = JournalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates and renames journal folders', () async {
    final id = await repo.createFolder(name: 'Ideas');

    var folders = await repo.getFolders();
    expect(folders, hasLength(1));
    expect(folders.first.id, id);
    expect(folders.first.name, 'Ideas');

    await repo.updateFolder(id: id, name: 'Reviews');

    folders = await repo.getFolders();
    expect(folders.first.name, 'Reviews');
  });

  test('moves journals into folders and filters by folder', () async {
    final folderId = await repo.createFolder(name: 'Training');
    final journalId = await repo.insertJournal(_journal(title: 'Workout log'));

    await repo.moveJournalToFolder(journalId, folderId);

    final inFolder = await repo.getJournalsByFolder(folderId: folderId);
    final uncategorized = await repo.getJournalsByFolder(
      uncategorizedOnly: true,
    );

    expect(inFolder, hasLength(1));
    expect(inFolder.first.id, journalId);
    expect(inFolder.first.folderId, folderId);
    expect(uncategorized, isEmpty);
  });

  test('deleting a folder moves journals back to uncategorized', () async {
    final folderId = await repo.createFolder(name: 'Archive');
    final journalId = await repo.insertJournal(
      _journal(title: 'Archived note'),
    );

    await repo.moveJournalToFolder(journalId, folderId);
    await repo.deleteFolder(folderId);

    final folders = await repo.getFolders();
    final journal = await repo.getJournalById(journalId);
    final uncategorized = await repo.getJournalsByFolder(
      uncategorizedOnly: true,
    );

    expect(folders, isEmpty);
    expect(journal!.folderId, isNull);
    expect(uncategorized.map((item) => item.id), contains(journalId));
  });

  test('deletes a journal and its assets', () async {
    final journalId = await repo.insertJournal(_journal(title: 'To delete'));

    // Insert an asset for this journal
    await repo.insertJournalAsset(
      JournalAssetsCompanion.insert(
        journalId: journalId,
        localPath: '/tmp/test.jpg',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // Verify asset exists
    final assetsBefore = await repo.getJournalAssets(journalId);
    expect(assetsBefore, hasLength(1));

    // Delete journal
    await repo.deleteJournal(journalId);

    // Verify journal and assets are gone
    final journal = await repo.getJournalById(journalId);
    expect(journal, isNull);

    final assetsAfter = await repo.getJournalAssets(journalId);
    expect(assetsAfter, isEmpty);
  });

  test('deleteJournal only targets the specified journal', () async {
    final id1 = await repo.insertJournal(_journal(title: 'Keep'));
    final id2 = await repo.insertJournal(_journal(title: 'Delete'));

    await repo.deleteJournal(id2);

    final remaining = await repo.getJournalById(id1);
    final deleted = await repo.getJournalById(id2);

    expect(remaining, isNotNull);
    expect(remaining!.title, 'Keep');
    expect(deleted, isNull);
  });
}
