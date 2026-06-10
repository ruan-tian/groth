import '../../../core/domain/pet/pet_ai_result.dart';

/// AI 结果解析器
///
/// 解析 AI 返回的文本，提取结构化数据。
class PetAIResultParser {
  PetAIResultParser._();

  /// 解析 AI 原始文本为 PetAIResult
  static PetAIResult parse(String raw, {PetAIAnalysisType? type}) {
    final title = type != null ? _getDefaultTitle(type) : '甜甜的分析';
    return PetAIResult.fromRawText(raw, fallbackTitle: title);
  }

  static String _getDefaultTitle(PetAIAnalysisType type) {
    switch (type) {
      case PetAIAnalysisType.study:
        return '甜甜的学习分析';
      case PetAIAnalysisType.fitness:
        return '甜甜的健身分析';
      case PetAIAnalysisType.diet:
        return '甜甜的饮食分析';
      case PetAIAnalysisType.sleep:
        return '甜甜的睡眠分析';
      case PetAIAnalysisType.weeklyReport:
        return '甜甜的成长周报';
      case PetAIAnalysisType.monthlyReport:
        return '甜甜的成长月报';
    }
  }
}
