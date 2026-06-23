import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/pet/pet_ai_result.dart';

/// 宠物消息仓库
///
/// 封装 petMessages 表的查询与写入操作。
class PetMessageRepository {
  PetMessageRepository(this._db);

  final AppDatabase _db;

  /// 获取指定来源类型的最新 AI 分析结果
  Future<PetAIResult?> getLatestAnalysis(String sourceType) async {
    final query = _db.select(_db.petMessages)
      ..where(
        (t) => t.type.equals('analysis') & t.sourceType.equals(sourceType),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    final results = await query.get();
    if (results.isEmpty) return null;
    return _mapToResult(results.first);
  }

  /// 获取跨模块的最新 AI 分析结果
  Future<PetAIResult?> getLatestAnalysisOverall() async {
    final query = _db.select(_db.petMessages)
      ..where((t) => t.type.equals('analysis'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    final results = await query.get();
    if (results.isEmpty) return null;
    return _mapToResult(results.first);
  }

  /// 插入一条 AI 分析结果
  Future<void> insertAnalysisResult({
    required String type,
    required String title,
    required String content,
    required String petMessage,
    required String sourceType,
    String? sourceRange,
    List<String> highlights = const [],
    List<String> risks = const [],
    List<String> suggestions = const [],
  }) async {
    await _db.into(_db.petMessages).insert(
      PetMessagesCompanion.insert(
        type: type,
        title: title,
        content: content,
        petMessage: petMessage,
        sourceType: sourceType,
        sourceRange: Value(sourceRange),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        highlights: Value(highlights.join('|||')),
        risks: Value(risks.join('|||')),
        suggestions: Value(suggestions.join('|||')),
      ),
    );
  }

  PetAIResult _mapToResult(PetMessage record) {
    return PetAIResult(
      title: record.title,
      summary: record.content,
      highlights: record.highlights?.split('|||') ?? [],
      risks: record.risks?.split('|||') ?? [],
      suggestions: record.suggestions?.split('|||') ?? [],
      petMessage: record.petMessage,
    );
  }
}
