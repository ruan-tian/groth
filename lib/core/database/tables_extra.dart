import 'package:drift/drift.dart';

import 'tables.dart';

/// 番茄钟/专注记录
@DataClassName('FocusSession')
class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // pomodoro / deep / custom
  TextColumn get title => text()();
  IntColumn get relatedStudyId =>
      integer().nullable().references(StudyRecords, #id)();
  IntColumn get startTime => integer()(); // timestamp ms
  IntColumn get endTime => integer()(); // timestamp ms
  IntColumn get durationMinutes => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get soundType => text().nullable()();
  IntColumn get roundIndex => integer().nullable()(); // 第几轮 (1-based)
  TextColumn get sessionGroupId => text().nullable()(); // cycle UUID，串联多轮
  IntColumn get createdAt => integer()(); // timestamp ms
}

/// 知识抽卡复习卡片
@DataClassName('KnowledgeCard')
class KnowledgeCards extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 学科族: math / computer / politics / custom 等
  TextColumn get deckKey => text().withDefault(const Constant('custom'))();

  /// 复习目标模板: kaoyan_cs / civil_service / custom 等
  TextColumn get goalKey => text().withDefault(const Constant('custom'))();

  /// 自定义目标名称，系统模板可为空
  TextColumn get goalName => text().nullable()();

  /// 目标下的模块: politics / english / data_structure / custom 等
  TextColumn get moduleKey => text().withDefault(const Constant('custom'))();

  /// 自定义模块名称，系统模块可为空
  TextColumn get moduleName => text().nullable()();

  /// 用户输入的章节、知识单元或来源位置
  TextColumn get subject => text().nullable()();

  /// 知识点标题
  TextColumn get title => text()();

  /// 卡片正面问题
  TextColumn get question => text()();

  /// 卡片背面答案
  TextColumn get answer => text()();

  /// 解释、例子或补充笔记
  TextColumn get explanation => text().nullable()();

  /// 标签 JSON 字符串数组
  TextColumn get tags => text().nullable()();

  /// 关联学习记录，后续可从学习记录生成卡片
  IntColumn get sourceStudyId =>
      integer().nullable().references(StudyRecords, #id)();

  /// 掌握度 0-5
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();

  /// 累计复习次数
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();

  /// 连续记得次数
  IntColumn get correctStreak => integer().withDefault(const Constant(0))();

  /// 上次复习时间 (Unix 毫秒)
  IntColumn get lastReviewedAt => integer().nullable()();

  /// 下次到期时间 (Unix 毫秒)
  IntColumn get dueAt => integer()();

  /// 是否归档
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();

  /// 更新时间 (Unix 毫秒)
  IntColumn get updatedAt => integer()();
}

/// 知识卡复习日志
@DataClassName('KnowledgeReviewLog')
class KnowledgeReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get cardId =>
      integer().references(KnowledgeCards, #id, onDelete: KeyAction.cascade)();

  /// 0=不会, 1=模糊, 2=记得, 3=很熟
  IntColumn get quality => integer()();

  IntColumn get previousMastery => integer()();

  IntColumn get nextMastery => integer()();

  IntColumn get reviewedAt => integer()();

  IntColumn get nextDueAt => integer()();
}

/// 用户自定义知识抽卡目标模板
@DataClassName('KnowledgeCustomTemplate')
class KnowledgeCustomTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 模板名称，例如：软考高级、蓝桥杯、期末复习
  TextColumn get name => text()();

  /// 模板说明，可记录考试范围或用途
  TextColumn get description => text().nullable()();

  /// 预留封面资源，当前默认使用自定义模板插画
  TextColumn get coverAsset => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

/// 用户自定义知识抽卡模板内模块
@DataClassName('KnowledgeCustomTemplateModule')
class KnowledgeCustomTemplateModules extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get templateId => integer().references(
    KnowledgeCustomTemplates,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// 模块名称，例如：案例分析、论文、专业课一
  TextColumn get name => text()();

  /// 模块默认卡片封面风格
  TextColumn get deckKey => text().withDefault(const Constant('custom'))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

/// 用户导入的本地知识资料，例如笔记、Markdown、复制文本或后续 PDF 解析文本
@DataClassName('KnowledgeSource')
class KnowledgeSources extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 资料标题
  TextColumn get title => text()();

  /// text / markdown / pdf_text / paste
  TextColumn get type => text().withDefault(const Constant('text'))();

  /// 原始来源说明，例如文件名或手动备注
  TextColumn get sourcePath => text().nullable()();

  /// 资料所属目标模板
  TextColumn get goalKey => text().withDefault(const Constant('custom'))();

  /// 自定义目标名称，系统模板可为空
  TextColumn get goalName => text().nullable()();

  /// 资料所属目标内模块
  TextColumn get moduleKey => text().withDefault(const Constant('custom'))();

  /// 自定义模块名称，系统模块可为空
  TextColumn get moduleName => text().nullable()();

  /// 标签 JSON 字符串数组
  TextColumn get tags => text().nullable()();

  /// 是否归档
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

/// 知识资料切片，用于本地检索后给 AI 提供精确上下文
@DataClassName('KnowledgeChunk')
class KnowledgeChunks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourceId => integer().references(
    KnowledgeSources,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get chunkIndex => integer()();

  /// 切片所属标题或章节
  TextColumn get heading => text().nullable()();

  /// 切片正文
  TextColumn get content => text()();

  /// 粗略 token 估算，用于限制 AI 上下文
  IntColumn get tokenEstimate => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();
}

/// 知识卡与知识库来源片段的关联，便于追溯 AI 生成或人工引用来源
@DataClassName('KnowledgeCardSourceLink')
class KnowledgeCardSourceLinks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get cardId =>
      integer().references(KnowledgeCards, #id, onDelete: KeyAction.cascade)();

  IntColumn get sourceId => integer().references(
    KnowledgeSources,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get chunkId =>
      integer().references(KnowledgeChunks, #id, onDelete: KeyAction.cascade)();

  /// 生成卡片时引用的短摘录
  TextColumn get quote => text().nullable()();

  IntColumn get createdAt => integer()();
}

/// V3 知识空间。用户只看到空间，不再看到目标/模块/章节。
@DataClassName('KnowledgeSpaceV3')
class KnowledgeSpacesV3 extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('custom'))();
  TextColumn get note => text().nullable()();
  TextColumn get iconAssetKey => text().nullable()();
  TextColumn get colorSeed => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// V3 资料。正文保存在本地，后台可检索，UI 不暴露切片/token。
@DataClassName('KnowledgeMaterial')
class KnowledgeMaterials extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spaceId => integer().references(
    KnowledgeSpacesV3,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get sourceType => text().withDefault(const Constant('text'))();
  TextColumn get sourcePath => text().nullable()();
  TextColumn get url => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('ready'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// V3 知识卡。卡片直接绑定空间和可选资料来源。
@DataClassName('KnowledgeCardV3')
class KnowledgeCardsV3 extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spaceId => integer().references(
    KnowledgeSpacesV3,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get materialId => integer().nullable().references(
    KnowledgeMaterials,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get cardType => text().withDefault(const Constant('recall'))();
  IntColumn get importance => integer().withDefault(const Constant(3))();
  IntColumn get difficulty => integer().withDefault(const Constant(3))();
  TextColumn get sourceTitle => text().nullable()();
  TextColumn get sourceExcerpt => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get correctStreak => integer().withDefault(const Constant(0))();
  IntColumn get dueAt => integer()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get lastReviewedAt => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// V3 闪卡复习日志。
@DataClassName('KnowledgeReviewLogV3')
class KnowledgeReviewLogsV3 extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(
    KnowledgeCardsV3,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get spaceId => integer().references(
    KnowledgeSpacesV3,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get rating => integer()();
  IntColumn get previousMastery => integer()();
  IntColumn get nextMastery => integer()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get reviewedAt => integer()();
  IntColumn get nextDueAt => integer()();
}

/// 甜甜问答会话。
@DataClassName('TiantianQaSession')
class TiantianQaSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spaceId => integer().references(
    KnowledgeSpacesV3,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text()();
  TextColumn get referencedMaterialIdsJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// 甜甜问答消息。
@DataClassName('TiantianQaMessage')
class TiantianQaMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(
    TiantianQaSessions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get sourcesJson => text().nullable()();
  BoolColumn get savedAsCard => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
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
  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 0=无, 1=低, 2=中, 3=高
  IntColumn get templateId =>
      integer().nullable().references(TaskTemplates, #id)(); // 关联模板 ID
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()(); // timestamp ms
  IntColumn get updatedAt => integer()(); // timestamp ms
}

/// 日记附件表
@DataClassName('JournalAsset')
class JournalAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get journalId => integer().references(DailyJournals, #id)();
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

@DataClassName('MusicTrack')
class MusicTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get originalPath => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get coverAsset => text().nullable()();
  TextColumn get sceneOverride => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get lastPlayedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('MusicPlaylist')
class MusicPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get coverAsset => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('MusicPlaylistTrack')
class MusicPlaylistTracks extends Table {
  IntColumn get playlistId =>
      integer().references(MusicPlaylists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(MusicTracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {playlistId, trackId};
}

/// AI 对话消息记录
@DataClassName('AiChatMessage')
class AiChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text()();
  IntColumn get cardId => integer().nullable()();
  TextColumn get role => text()(); // 'user' | 'assistant'
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();
}
