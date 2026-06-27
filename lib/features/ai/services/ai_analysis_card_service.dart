import '../../knowledge/services/knowledge_card_ai_service.dart';

class AiAnalysisCardService {
  const AiAnalysisCardService();

  List<KnowledgeCardAiDraft> buildDraftsFromAnalysis(String analysis) {
    final lines = analysis
        .split(RegExp(r'\r?\n'))
        .map(_cleanLine)
        .where((line) => line.length >= 8)
        .toList(growable: false);
    final candidates = <KnowledgeCardAiDraft>[];

    for (final line in lines) {
      if (!_looksActionable(line)) continue;
      final title = _titleFromLine(line);
      candidates.add(
        KnowledgeCardAiDraft(
          title: title,
          question: '这次 AI 分析建议我如何处理「$title」？',
          answer: line,
          explanation: '由 AI 分析结果转入，保存时会关联本次参考的本地知识库片段。',
          tags: const ['AI分析', '待复习'],
        ),
      );
      if (candidates.length >= 5) break;
    }

    if (candidates.isNotEmpty) return candidates;

    final summary = _compact(analysis);
    if (summary.isEmpty) return const [];
    return [
      KnowledgeCardAiDraft(
        title: 'AI 分析要点',
        question: '这次 AI 分析中最需要记住的要点是什么？',
        answer: summary,
        explanation: '由 AI 分析结果自动生成，请保存前按需编辑。',
        tags: const ['AI分析', '总结'],
      ),
    ];
  }

  String _cleanLine(String line) {
    return line
        .trim()
        .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
        .replaceFirst(RegExp(r'^[-*]\s+'), '')
        .replaceFirst(RegExp(r'^\d+[.)、]\s*'), '')
        .trim();
  }

  bool _looksActionable(String line) {
    const markers = [
      '建议',
      '应该',
      '可以',
      '需要',
      '优先',
      '复习',
      '练习',
      '记录',
      '调整',
      '保持',
      '避免',
      '下一步',
      '重点',
      '薄弱',
    ];
    return markers.any(line.contains);
  }

  String _titleFromLine(String line) {
    final cleaned = line
        .replaceFirst(RegExp(r'^(建议|下一步|重点|薄弱点)[:：]\s*'), '')
        .trim();
    final stop = cleaned.indexOf(RegExp(r'[，。；;,.]'));
    final title = stop > 0 ? cleaned.substring(0, stop) : cleaned;
    final compact = _compact(title, limit: 24);
    return compact.isEmpty ? 'AI 分析建议' : compact;
  }

  String _compact(String value, {int limit = 220}) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }
}
