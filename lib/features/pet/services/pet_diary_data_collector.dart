import '../../../core/database/app_database.dart';
import '../../health/repositories/diet_repository.dart';
import '../../health/repositories/sleep_repository.dart';
import '../../health/repositories/weather_repository.dart';
import '../../plan/repositories/task_repository.dart';
import '../../study/repositories/study_repository.dart';
import '../../fitness/repositories/fitness_repository.dart';
import '../repositories/exp_repository.dart';

/// Data collector for pet diary generation.
///
/// Aggregates data from study, fitness, diet, sleep, task, exp, and weather
/// modules using repository methods. This isolates the database access
/// pattern from the service layer.
class PetDiaryDataCollector {
  PetDiaryDataCollector({
    required StudyRepository studyRepo,
    required FitnessRepository fitnessRepo,
    required DietRepository dietRepo,
    required SleepRepository sleepRepo,
    required DailyTaskRepository taskRepo,
    required ExpRepository expRepo,
    required WeatherRepository weatherRepo,
  })  : _studyRepo = studyRepo,
        _fitnessRepo = fitnessRepo,
        _dietRepo = dietRepo,
        _sleepRepo = sleepRepo,
        _taskRepo = taskRepo,
        _expRepo = expRepo,
        _weatherRepo = weatherRepo;

  final StudyRepository _studyRepo;
  final FitnessRepository _fitnessRepo;
  final DietRepository _dietRepo;
  final SleepRepository _sleepRepo;
  final DailyTaskRepository _taskRepo;
  final ExpRepository _expRepo;
  final WeatherRepository _weatherRepo;

  /// Collect study records for a date range.
  Future<List<StudyRecord>> getStudyRecords({
    required int startMs,
    required int endMs,
  }) async {
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    return _studyRepo.getStudyRecordsByRange(start, end);
  }

  /// Collect fitness records for a date range.
  Future<List<FitnessRecord>> getFitnessRecords({
    required int startMs,
    required int endMs,
  }) async {
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    return _fitnessRepo.getFitnessRecordsByRange(start, end);
  }

  /// Collect diet records for a specific date.
  Future<List<DietRecord>> getDietRecords(String dateKey) async {
    // Parse dateKey (YYYY-MM-DD) to DateTime
    final date = DateTime.parse(dateKey);
    return _dietRepo.getDietRecordsByDate(date);
  }

  /// Collect sleep records for a specific date.
  Future<List<SleepRecord>> getSleepRecords(String dateKey) async {
    // Parse dateKey (YYYY-MM-DD) to DateTime
    final date = DateTime.parse(dateKey);
    final record = await _sleepRepo.getSleepRecordByDate(date);
    return record != null ? [record] : [];
  }

  /// Collect exp logs for a date range.
  Future<List<GrowthExpLog>> getExpLogs({
    required int startMs,
    required int endMs,
  }) async {
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    return _expRepo.getExpLogsByRange(start, end);
  }

  /// Collect tasks for a specific date.
  Future<List<DailyTask>> getTasks(String dateKey) async {
    return _taskRepo.getTasksByDate(dateKey);
  }

  /// Collect weather for a specific date.
  Future<DailyWeather?> getWeather(String dateKey) async {
    return _weatherRepo.getWeatherByDate(dateKey);
  }
}
