import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'tables_extra.dart';
import 'pet_tables.dart';
import 'pet_messages.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    StudyRecords,
    FitnessRecords,
    FitnessExercises,
    FitnessWorkoutTemplates,
    FitnessWorkoutTemplateExercises,
    BodyMetrics,
    JournalFolders,
    DailyJournals,
    FocusSessions,
    GrowthExpLogs,
    AppSettings,
    AiConfigs,
    BackupRecords,
    DailyTasks,
    TaskTemplates,
    DietRecords,
    SleepRecords,
    PetProfiles,
    PetStates,
    PetDiaries,
    JournalAssets,
    PetMessages,
    DailyWeatherTable,
    ApiConfigs,
    WeatherSearchHistoryTable,
    MusicTracks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'growth_os_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  int get schemaVersion => 20;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await _createPerformanceIndexes();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // 添加每日任务表
          await m.createTable(dailyTasks);
          // 添加任务模板表
          await m.createTable(taskTemplates);
        }
        if (from < 3) {
          // 添加饮食记录表
          await m.createTable(dietRecords);
          // 添加睡眠记录表
          await m.createTable(sleepRecords);
        }
        if (from < 4) {
          // 添加宠物表
          await m.createTable(petProfiles);
          await m.createTable(petStates);
        }
        if (from < 5) {
          // 添加日记附件表
          await m.createTable(journalAssets);
          // 为日记表添加 Markdown 支持列
          await m.addColumn(dailyJournals, dailyJournals.markdownContent);
          await m.addColumn(dailyJournals, dailyJournals.plainText);
        }
        if (from < 6) {
          // 添加富文本编辑器支持列
          await m.addColumn(dailyJournals, dailyJournals.contentType);
          await m.addColumn(dailyJournals, dailyJournals.quillDeltaJson);
        }
        if (from < 7) {
          // 添加宠物消息表
          await m.createTable(petMessages);
        }
        if (from < 9) {
          // 添加天气记录表
          await m.createTable(dailyWeatherTable);
        }
        if (from < 10) {
          // 添加 API 配置表
          await m.createTable(apiConfigs);
        }
        if (from < 11) {
          // 添加天气城市搜索历史表
          await m.createTable(weatherSearchHistoryTable);
        }
        if (from < 13) {
          // 为每日任务表添加优先级列
          await m.addColumn(dailyTasks, dailyTasks.priority);
        }
        if (from < 14) {
          await m.createTable(petDiaries);
        }
        if (from < 15) {
          // 为专注记录表添加轮次和分组列
          await m.addColumn(focusSessions, focusSessions.roundIndex);
          await m.addColumn(focusSessions, focusSessions.sessionGroupId);
        }
        if (from < 16) {
          await m.createTable(fitnessWorkoutTemplates);
          await m.createTable(fitnessWorkoutTemplateExercises);
          await m.addColumn(fitnessExercises, fitnessExercises.exerciseType);
          await m.addColumn(fitnessExercises, fitnessExercises.durationSeconds);
          await m.addColumn(fitnessExercises, fitnessExercises.sortOrder);
        }
        if (from < 17) {
          await m.createTable(musicTracks);
        }
        if (from < 18) {
          await _createPerformanceIndexes();
        }
        if (from < 19) {
          // 为健身记录表添加运动类型列
          await m.addColumn(fitnessRecords, fitnessRecords.activityType);
        }
        if (from < 20) {
          await m.createTable(journalFolders);
          await m.addColumn(dailyJournals, dailyJournals.folderId);
          await _createPerformanceIndexes();
        }
      },
    );
  }

  Future<void> _createPerformanceIndexes() async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_study_records_created_at ON study_records(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_fitness_records_created_at ON fitness_records(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_focus_sessions_created_at ON focus_sessions(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_growth_exp_logs_created_at ON growth_exp_logs(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_growth_exp_logs_source_created ON growth_exp_logs(source_type, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_body_metrics_created_at ON body_metrics(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_body_metrics_record_date ON body_metrics(record_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_journals_journal_date ON daily_journals(journal_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_journals_folder_id ON daily_journals(folder_id)',
      'CREATE INDEX IF NOT EXISTS idx_daily_journals_date_folder ON daily_journals(journal_date, folder_id)',
      'CREATE INDEX IF NOT EXISTS idx_journal_folders_sort ON journal_folders(sort_order, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_daily_tasks_task_date ON daily_tasks(task_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_tasks_template_id ON daily_tasks(template_id)',
      'CREATE INDEX IF NOT EXISTS idx_diet_records_meal_date ON diet_records(meal_date)',
      'CREATE INDEX IF NOT EXISTS idx_sleep_records_sleep_date ON sleep_records(sleep_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_weather_date_city ON daily_weather_table(date, city)',
      'CREATE INDEX IF NOT EXISTS idx_weather_search_history_city ON weather_search_history_table(city_name)',
      'CREATE INDEX IF NOT EXISTS idx_weather_search_history_created_at ON weather_search_history_table(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_fitness_exercises_record_id ON fitness_exercises(fitness_record_id)',
      'CREATE INDEX IF NOT EXISTS idx_template_exercises_template_id ON fitness_workout_template_exercises(template_id)',
      'CREATE INDEX IF NOT EXISTS idx_journal_assets_journal_id ON journal_assets(journal_id)',
      'CREATE INDEX IF NOT EXISTS idx_pet_messages_source ON pet_messages(source_type, source_range, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_pet_messages_is_read ON pet_messages(is_read)',
      'CREATE INDEX IF NOT EXISTS idx_pet_diaries_diary_date ON pet_diaries(diary_date)',
      'CREATE INDEX IF NOT EXISTS idx_music_tracks_created_at ON music_tracks(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_music_tracks_last_played_at ON music_tracks(last_played_at)',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}
