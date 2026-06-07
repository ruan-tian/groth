import 'package:drift/drift.dart';

/// 宠物消息表
///
/// 存储 AI 分析结果和系统消息。
@DataClassName('PetMessage')
class PetMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 消息类型: analysis / report / reminder / system
  TextColumn get type => text()();

  /// 标题
  TextColumn get title => text()();

  /// 完整内容 (AI 分析的完整文本)
  TextColumn get content => text()();

  /// 宠物简短消息 (气泡显示的一句话)
  TextColumn get petMessage => text()();

  /// 来源模块: study / fitness / diet / sleep / growth
  TextColumn get sourceType => text()();

  /// 时间范围: today / last_7_days / last_30_days
  TextColumn get sourceRange => text().nullable()();

  /// 是否已读
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// 高亮点 (JSON 数组)
  TextColumn get highlights => text().nullable()();

  /// 风险点 (JSON 数组)
  TextColumn get risks => text().nullable()();

  /// 建议 (JSON 数组)
  TextColumn get suggestions => text().nullable()();

  /// 创建时间 (Unix 毫秒)
  IntColumn get createdAt => integer()();
}
