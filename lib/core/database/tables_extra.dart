import 'package:drift/drift.dart';

/// 番茄钟/专注记录
@DataClassName('FocusSession')
class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // pomodoro / deep / custom
  TextColumn get title => text()();
  IntColumn get relatedStudyId => integer().nullable()();
  IntColumn get startTime => integer()(); // timestamp ms
  IntColumn get endTime => integer()(); // timestamp ms
  IntColumn get durationMinutes => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get soundType => text().nullable()();
  IntColumn get createdAt => integer()(); // timestamp ms
}

/// 经验日志（等级计算核心）
@DataClassName('GrowthExpLog')
class GrowthExpLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceType => text()(); // study / fitness / journal / focus
  IntColumn get sourceId => integer()();
  IntColumn get expValue => integer()();
  TextColumn get reason => text()();
  IntColumn get createdAt => integer()(); // timestamp ms
}

/// 系统设置（KV 存储）
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()(); // timestamp ms

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// AI API 配置
@DataClassName('AiConfig')
class AiConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text()(); // openai / deepseek / gemini / custom
  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text()();
  TextColumn get modelName => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  IntColumn get maxTokens => integer().withDefault(const Constant(2048))();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}

/// 备份记录
@DataClassName('BackupRecord')
class BackupRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get backupName => text()();
  TextColumn get backupPath => text()();
  TextColumn get backupType => text()(); // json / sqlite
  IntColumn get fileSize => integer().nullable()();
  IntColumn get createdAt => integer()(); // timestamp ms
}

/// 每日任务
@DataClassName('DailyTask')
class DailyTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()(); // 任务名称
  TextColumn get description => text().nullable()(); // 详细任务描述
  TextColumn get taskDate => text()(); // 任务日期 YYYY-MM-DD
  IntColumn get startHour => integer()(); // 开始时间（小时 0-23）
  IntColumn get startMinute => integer()(); // 开始时间（分钟 0-59）
  IntColumn get endHour => integer()(); // 结束时间（小时 0-23）
  IntColumn get endMinute => integer()(); // 结束时间（分钟 0-59）
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // 0=无, 1=低, 2=中, 3=高
  IntColumn get templateId => integer().nullable()(); // 关联模板 ID
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}

/// 日记附件表
@DataClassName('JournalAsset')
class JournalAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get journalId => integer()();
  TextColumn get assetType => text().withDefault(const Constant('image'))();
  TextColumn get localPath => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

/// 任务模板
@DataClassName('TaskTemplate')
class TaskTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // 模板名称
  TextColumn get description => text().nullable()(); // 模板描述
  IntColumn get defaultStartHour => integer()(); // 默认开始时间（小时）
  IntColumn get defaultStartMinute => integer()(); // 默认开始时间（分钟）
  IntColumn get defaultEndHour => integer()(); // 默认结束时间（小时）
  IntColumn get defaultEndMinute => integer()(); // 默认结束时间（分钟）
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}
