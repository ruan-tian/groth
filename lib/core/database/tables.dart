import 'package:drift/drift.dart';

/// 学习记录表
///
/// 保存学习打卡数据，支持简单/专业两种模式。
/// 时间戳以毫秒存储，经验值由系统自动计算。
@DataClassName('StudyRecord')
class StudyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 模式: simple / professional
  TextColumn get mode => text()();

  /// 学习内容标题
  TextColumn get title => text()();

  /// 科目 (可选)
  TextColumn get subject => text().nullable()();

  /// 章节 (可选)
  TextColumn get chapter => text().nullable()();

  /// 开始时间 (Unix 毫秒)
  IntColumn get startTime => integer()();

  /// 结束时间 (Unix 毫秒)
  IntColumn get endTime => integer()();

  /// 学习时长 (分钟)
  IntColumn get durationMinutes => integer()();

  /// 专注度 1-5
  IntColumn get focusLevel => integer().nullable()();

  /// 难度 1-5
  IntColumn get difficultyLevel => integer().nullable()();

  /// 掌握度 1-5
  IntColumn get masteryLevel => integer().nullable()();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 学习收获
  TextColumn get gain => text().nullable()();

  /// 遗留问题
  TextColumn get problem => text().nullable()();

  /// 获得经验值
  IntColumn get expGained => integer().withDefault(const Constant(0))();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// 健身记录表
///
/// 保存一次训练记录，支持简单/专业两种模式。
@DataClassName('FitnessRecord')
class FitnessRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 模式: simple / professional
  TextColumn get mode => text()();

  /// 训练标题 (可选)
  TextColumn get title => text().nullable()();

  /// 训练部位
  TextColumn get bodyPart => text()();

  /// 运动类型 (strength/running/ballSports/yoga/swimming/cycling/outdoor/other)
  TextColumn get activityType =>
      text().withDefault(const Constant('strength'))();

  /// 开始时间 (Unix 毫秒)
  IntColumn get startTime => integer()();

  /// 结束时间 (Unix 毫秒)
  IntColumn get endTime => integer()();

  /// 训练时长 (分钟)
  IntColumn get durationMinutes => integer()();

  /// 疲劳程度 1-5
  IntColumn get fatigueLevel => integer().nullable()();

  /// 强度 1-5
  IntColumn get intensityLevel => integer().nullable()();

  /// 训练感受
  TextColumn get feeling => text().nullable()();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 获得经验值
  IntColumn get expGained => integer().withDefault(const Constant(0))();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// 健身动作表
///
/// 一条健身记录可以包含多个动作 (1:N)。
@DataClassName('FitnessExercise')
class FitnessExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 所属健身记录 ID (外键)
  IntColumn get fitnessRecordId => integer().references(FitnessRecords, #id)();

  /// 动作名称
  TextColumn get exerciseName => text()();

  /// 组数
  IntColumn get sets => integer()();

  /// 次数
  IntColumn get reps => integer()();

  /// 重量 (kg)
  RealColumn get weight => real().nullable()();

  /// 组间休息 (秒)
  IntColumn get restSeconds => integer().nullable()();

  /// 动作类型: reps / timed
  TextColumn get exerciseType => text().withDefault(const Constant('reps'))();

  /// 计时动作时长 (秒)
  IntColumn get durationSeconds => integer().nullable()();

  /// 动作排序
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 动作备注
  TextColumn get note => text().nullable()();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();
}

/// 健身训练模板表
///
/// 保存可复用训练计划。内置模板只读，用户编辑时复制为自定义模板。
@DataClassName('FitnessWorkoutTemplate')
class FitnessWorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 模板名称
  TextColumn get name => text()();

  /// 主要训练部位
  TextColumn get bodyPart => text()();

  /// 目标类型: strength / core / mobility / custom
  TextColumn get goalType => text().withDefault(const Constant('custom'))();

  /// 模板说明
  TextColumn get description => text().nullable()();

  /// 是否内置模板
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// 健身训练模板动作表
@DataClassName('FitnessWorkoutTemplateExercise')
class FitnessWorkoutTemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 所属模板 ID
  IntColumn get templateId =>
      integer().references(FitnessWorkoutTemplates, #id)();

  /// 动作名称
  TextColumn get exerciseName => text()();

  /// 动作类型: reps / timed
  TextColumn get exerciseType => text().withDefault(const Constant('reps'))();

  /// 目标组数
  IntColumn get targetSets => integer()();

  /// 目标次数
  IntColumn get targetReps => integer().nullable()();

  /// 目标秒数
  IntColumn get targetSeconds => integer().nullable()();

  /// 默认重量 (kg)
  RealColumn get weightKg => real().nullable()();

  /// 组间休息 (秒)
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();

  /// 排序
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 动作备注
  TextColumn get note => text().nullable()();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();
}

/// 身体数据表
///
/// 按日期记录体重、围度变化。
@DataClassName('BodyMetric')
class BodyMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 记录日期 (YYYY-MM-DD)
  TextColumn get recordDate => text()();

  /// 体重 (kg)
  RealColumn get weight => real().nullable()();

  /// 体脂率 (%)
  RealColumn get bodyFat => real().nullable()();

  /// 胸围 (cm)
  RealColumn get chest => real().nullable()();

  /// 腰围 (cm)
  RealColumn get waist => real().nullable()();

  /// 臀围 (cm)
  RealColumn get hip => real().nullable()();

  /// 臂围 (cm)
  RealColumn get arm => real().nullable()();

  /// 大腿围 (cm)
  RealColumn get thigh => real().nullable()();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();
}

/// 每日成长日记表
///
/// 保存每日复盘和写作内容。
@DataClassName('JournalFolder')
class JournalFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFFEFA6BA))();
  IntColumn get iconCodePoint =>
      integer().withDefault(const Constant(0xe2c7))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// 每日成长日记表
///
/// 保存每日复盘和写作内容。
@DataClassName('DailyJournal')
class DailyJournals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 日记日期 (YYYY-MM-DD)
  TextColumn get journalDate => text()();

  /// 标题
  TextColumn get title => text()();

  /// 日记内容（兼容旧数据，存纯文本或markdown）
  TextColumn get content => text()();

  /// 内容类型: markdown / quill
  TextColumn get contentType =>
      text().withDefault(const Constant('markdown'))();

  /// Quill Delta JSON（富文本格式）
  TextColumn get quillDeltaJson => text().nullable()();

  /// Markdown 格式内容
  TextColumn get markdownContent => text().nullable()();

  /// 纯文本内容（不含格式标记，用于搜索和AI分析）
  TextColumn get plainText => text().nullable()();

  /// 心情
  TextColumn get mood => text().nullable()();

  /// 标签 (JSON 字符串数组)
  TextColumn get tags => text().nullable()();

  /// 所属文件夹 ID，null = 未分类
  IntColumn get folderId =>
      integer().nullable().references(JournalFolders, #id)();

  /// 字数
  IntColumn get wordCount => integer().withDefault(const Constant(0))();

  /// 获得经验值
  IntColumn get expGained => integer().withDefault(const Constant(0))();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// 饮食记录表
///
/// 记录每日饮食情况，采用粗略评估方式。
@DataClassName('DietRecord')
class DietRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 饮食日期 (YYYY-MM-DD)
  TextColumn get mealDate => text()();

  /// 餐次类型: breakfast / lunch / dinner / snack
  TextColumn get mealType => text()();

  /// 食物描述（自由文本）
  TextColumn get foodText => text()();

  /// 份量: small / normal / large
  TextColumn get portionLevel => text().withDefault(const Constant('normal'))();

  /// 热量等级: low / normal / high
  TextColumn get calorieLevel => text().withDefault(const Constant('normal'))();

  /// 蛋白质等级: low / medium / high
  TextColumn get proteinLevel => text().withDefault(const Constant('medium'))();

  /// 健康评分 1-5
  IntColumn get healthScore => integer().withDefault(const Constant(3))();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// 睡眠记录表
///
/// 记录每日睡眠情况，手动录入模式。
@DataClassName('SleepRecord')
class SleepRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 睡眠日期 (YYYY-MM-DD，以入睡日期为准)
  TextColumn get sleepDate => text()();

  /// 上床时间 (HH:mm)
  TextColumn get bedTime => text()();

  /// 实际入睡时间 (HH:mm)
  TextColumn get sleepTime => text()();

  /// 起床时间 (HH:mm)
  TextColumn get wakeTime => text()();

  /// 睡眠时长（分钟，自动计算）
  IntColumn get durationMinutes => integer()();

  /// 睡眠质量 1-5
  IntColumn get qualityLevel => integer().withDefault(const Constant(3))();

  /// 入睡耗时（分钟）
  IntColumn get fallAsleepMinutes => integer().withDefault(const Constant(0))();

  /// 夜醒次数
  IntColumn get wakeCount => integer().withDefault(const Constant(0))();

  /// 醒后精力 1-5
  IntColumn get energyLevel => integer().withDefault(const Constant(3))();

  /// 梦境备注
  TextColumn get dreamNote => text().nullable()();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// API 配置表
@DataClassName('ApiConfig')
class ApiConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text()();
  TextColumn get apiKey => text().nullable()();
  TextColumn get baseUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// 天气记录表
@DataClassName('DailyWeather')
class DailyWeatherTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get weatherType => text()();
  TextColumn get weatherCode => text()();
  IntColumn get temperature => integer()();
  IntColumn get humidity => integer()();
  TextColumn get windDir => text().nullable()();
  IntColumn get windScale => integer().nullable()();
  TextColumn get city => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get createdAt => integer()();
}

/// 天气城市搜索历史表
@DataClassName('WeatherSearchHistory')
class WeatherSearchHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cityName => text()();
  TextColumn get country => text().nullable()();
  TextColumn get admin1 => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get createdAt => integer()();
}
