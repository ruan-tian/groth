import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Data collector for pet diary generation.
///
/// Encapsulates direct database queries needed for cross-module data
/// aggregation in pet diary generation. This isolates the database
/// access pattern from the service layer.
///
/// **Why direct DB access?**
/// - PetDiaryDataCollector aggregates data from 7 different modules
/// - Repository methods don't have the exact query signatures needed
///   (e.g., date range queries, multi-table aggregation)
/// - This is a legitimate data aggregation service, not a business logic layer
/// - The collector provides a clean interface that isolates DB access
///
/// **Future optimization:**
/// - Add missing query methods to repositories (e.g., getStudyRecordsByDateRange)
/// - Refactor PetDiaryDataCollector to use repository methods when available
class PetDiaryDataCollector {
  PetDiaryDataCollector(this._db);

  final AppDatabase _db;

  /// Collect study records for a date range.
  Future<List<StudyRecord>> getStudyRecords({
    required int startMs,
    required int endMs,
  }) async {
    return (_db.select(_db.studyRecords)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(startMs) &
                t.startTime.isSmallerThanValue(endMs),
          ))
        .get();
  }

  /// Collect fitness records for a date range.
  Future<List<FitnessRecord>> getFitnessRecords({
    required int startMs,
    required int endMs,
  }) async {
    return (_db.select(_db.fitnessRecords)
          ..where(
            (t) =>
                t.startTime.isBiggerOrEqualValue(startMs) &
                t.startTime.isSmallerThanValue(endMs),
          ))
        .get();
  }

  /// Collect diet records for a specific date.
  Future<List<DietRecord>> getDietRecords(String dateKey) async {
    return (_db.select(_db.dietRecords)
          ..where((t) => t.mealDate.equals(dateKey)))
        .get();
  }

  /// Collect sleep records for a specific date.
  Future<List<SleepRecord>> getSleepRecords(String dateKey) async {
    return (_db.select(_db.sleepRecords)
          ..where((t) => t.sleepDate.equals(dateKey)))
        .get();
  }

  /// Collect exp logs for a date range.
  Future<List<GrowthExpLog>> getExpLogs({
    required int startMs,
    required int endMs,
  }) async {
    return (_db.select(_db.growthExpLogs)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startMs) &
                t.createdAt.isSmallerThanValue(endMs),
          ))
        .get();
  }

  /// Collect tasks for a specific date.
  Future<List<DailyTask>> getTasks(String dateKey) async {
    return (_db.select(_db.dailyTasks)
          ..where((t) => t.taskDate.equals(dateKey)))
        .get();
  }

  /// Collect weather for a specific date.
  Future<DailyWeather?> getWeather(String dateKey) async {
    return (_db.select(_db.dailyWeatherTable)
          ..where((t) => t.date.equals(dateKey)))
        .getSingleOrNull();
  }
}
