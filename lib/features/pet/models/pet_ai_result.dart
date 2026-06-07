import 'dart:convert';

/// AI 分析类型
enum PetAIAnalysisType {
  study,
  fitness,
  diet,
  sleep,
  weeklyReport,
  monthlyReport,
}

/// AI 分析结果
class PetAIResult {
  const PetAIResult({
    required this.title,
    required this.summary,
    required this.highlights,
    required this.risks,
    required this.suggestions,
    required this.petMessage,
  });

  final String title;
  final String summary;
  final List<String> highlights;
  final List<String> risks;
  final List<String> suggestions;
  final String petMessage;

  /// Clean markdown symbols from text
  static String _cleanMarkdown(String text) {
    var cleaned = text.replaceAll(RegExp(r'\*\*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*-\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*#+\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'highlights': highlights,
        'risks': risks,
        'suggestions': suggestions,
        'pet_message': petMessage,
      };

  factory PetAIResult.fromJson(Map<String, dynamic> json) {
    return PetAIResult(
      title: _cleanMarkdown(json['title'] as String? ?? '甜甜的分析'),
      summary: _cleanMarkdown(json['summary'] as String? ?? ''),
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => _cleanMarkdown(e.toString()))
              .toList() ??
          [],
      risks: (json['risks'] as List<dynamic>?)
              ?.map((e) => _cleanMarkdown(e.toString()))
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => _cleanMarkdown(e.toString()))
              .toList() ??
          [],
      petMessage: _cleanMarkdown(json['pet_message'] as String? ?? ''),
    );
  }

  /// 从 AI 原始文本解析（尝试 JSON，失败则用纯文本）
  factory PetAIResult.fromRawText(String raw, {String fallbackTitle = '甜甜的分析'}) {
    try {
      String jsonStr = raw;
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PetAIResult.fromJson(map);
    } catch (_) {
      return PetAIResult(
        title: _cleanMarkdown(fallbackTitle),
        summary: _cleanMarkdown(raw),
        highlights: [],
        risks: [],
        suggestions: [],
        petMessage: _cleanMarkdown(raw.length > 50 ? '${raw.substring(0, 50)}...' : raw),
      );
    }
  }
}
