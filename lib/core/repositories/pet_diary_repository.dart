import 'package:drift/drift.dart';

import '../database/app_database.dart';

class PetDiaryRepository {
  PetDiaryRepository(this._db);

  final AppDatabase _db;

  Future<PetDiary?> getDiaryByDate(String diaryDate) {
    return (_db.select(_db.petDiaries)
          ..where((t) => t.diaryDate.equals(diaryDate))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<PetDiary?> getDiaryById(int id) {
    return (_db.select(_db.petDiaries)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PetDiary>> getRecentDiaries({int limit = 30}) {
    return (_db.select(_db.petDiaries)
          ..orderBy([(t) => OrderingTerm.desc(t.diaryDate)])
          ..limit(limit))
        .get();
  }

  Future<int> insertDiary(PetDiariesCompanion diary) {
    return _db.into(_db.petDiaries).insert(diary);
  }

  Future<void> updateDiary(PetDiariesCompanion diary) async {
    final id = diary.id.value;
    await (_db.update(
      _db.petDiaries,
    )..where((t) => t.id.equals(id))).write(diary);
  }

  Future<PetDiary> saveForDate(PetDiariesCompanion diary) async {
    final existing = await getDiaryByDate(diary.diaryDate.value);
    if (existing == null) {
      final id = await insertDiary(diary);
      return (await getDiaryById(id))!;
    }

    await updateDiary(diary.copyWith(id: Value(existing.id)));
    return (await getDiaryById(existing.id))!;
  }

  Future<void> deleteDiary(int id) async {
    await (_db.delete(_db.petDiaries)..where((t) => t.id.equals(id))).go();
  }
}
