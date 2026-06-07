import '../models/pet_ai_result.dart';

/// 宠物 AI Prompt 构建器
///
/// 负责构建发送给 AI 的 System Prompt 和 User Prompt。
class PetPromptBuilder {
  PetPromptBuilder._();

  /// 系统 Prompt，定义甜甜的角色设定。
  static String buildSystemPrompt() {
    return '''你是 Growth OS 中的成长伙伴"甜甜"。

你是一只温柔、可爱、克制、鼓励型的小猫。
你根据用户的学习、健身、饮食、睡眠、日记数据，给出具体、温柔、可执行的成长建议。

要求：
1. 语气温柔，像一个陪伴用户成长的小猫朋友。
2. 不责备用户，不制造焦虑，不说教。
3. 不做医疗诊断。
4. 不编造数据中不存在的结论。
5. 建议要具体、可执行。
6. 用"甜甜"第一人称说话，比如"甜甜发现..."、"甜甜建议..."。
7. 输出不要太长。

请严格输出以下 JSON 格式，不要添加其他内容：
{
  "title": "甜甜的分析标题（10字以内）",
  "summary": "一句话总结（30字以内）",
  "highlights": ["亮点1（15字以内）", "亮点2"],
  "risks": ["注意点1（15字以内）"],
  "suggestions": ["建议1（15字以内）", "建议2"],
  "pet_message": "甜甜对用户说的鼓励话（20字以内，用甜甜口吻）"
}

注意：
- pet_message 必须用甜甜的第一人称，语气温暖鼓励。
- pet_message 不超过 20 个字。
- title 不超过 10 个字。
- highlights、risks、suggestions 每条不超过 15 个字。
- 输出必须是合法的 JSON。''';
  }

  /// 构建用户 Prompt
  static String buildUserPrompt({
    required PetAIAnalysisType type,
    required Map<String, dynamic> data,
  }) {
    final typeLabel = _getTypeLabel(type);
    final rangeLabel = _getRangeLabel(type);

    return '''以下是用户的$typeLabel数据。

数据类型：$typeLabel
时间范围：$rangeLabel

用户数据：
${_formatData(data)}

请输出 JSON：
{
  "title": "",
  "summary": "",
  "highlights": [],
  "risks": [],
  "suggestions": [],
  "pet_message": ""
}''';
  }

  static String _getTypeLabel(PetAIAnalysisType type) {
    switch (type) {
      case PetAIAnalysisType.study:
        return '学习数据';
      case PetAIAnalysisType.fitness:
        return '健身数据';
      case PetAIAnalysisType.diet:
        return '饮食数据';
      case PetAIAnalysisType.sleep:
        return '睡眠分析';
      case PetAIAnalysisType.weeklyReport:
        return '成长周报';
      case PetAIAnalysisType.monthlyReport:
        return '成长月报';
    }
  }

  static String _getRangeLabel(PetAIAnalysisType type) {
    switch (type) {
      case PetAIAnalysisType.study:
      case PetAIAnalysisType.fitness:
      case PetAIAnalysisType.diet:
      case PetAIAnalysisType.sleep:
        return '近 7 天';
      case PetAIAnalysisType.weeklyReport:
        return '近 7 天';
      case PetAIAnalysisType.monthlyReport:
        return '近 30 天';
    }
  }

  static String _formatData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      buffer.writeln('- $key: $value');
    });
    return buffer.toString();
  }
}