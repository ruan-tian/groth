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
    BodyMetrics,
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
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
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
      },
    );
  }
}
