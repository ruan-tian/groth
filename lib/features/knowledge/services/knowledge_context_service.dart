import '../../../core/database/app_database.dart';
import '../repositories/knowledge_source_repository.dart';

class KnowledgeContextService {
  KnowledgeContextService(this._sourceRepository);

  final KnowledgeSourceRepository _sourceRepository;

  static const int maxChunks = 4;
  static const int maxTokens = 1200;

  Future<KnowledgeContextBundle> buildForStudyRecords(
    List<StudyRecord> records,
  ) async {
    final query = _buildStudyQuery(records);
    return buildForQuery(query);
  }

  Future<KnowledgeContextBundle> buildForQuery(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const KnowledgeContextBundle.empty();
    }

    final results = await _sourceRepository.searchChunks(
      query: normalized,
      limit: maxChunks * 2,
    );
    final selected = _selectWithinBudget(results);
    return KnowledgeContextBundle(query: normalized, results: selected);
  }

  String _buildStudyQuery(List<StudyRecord> records) {
    final weighted = <String, int>{};
    for (final record in records.take(10)) {
      _addTerms(weighted, record.title, 3);
      _addTerms(weighted, record.subject, 4);
    }

    final terms = weighted.entries.toList()
      ..sort((a, b) {
        final score = b.value.compareTo(a.value);
        if (score != 0) return score;
        return a.key.compareTo(b.key);
      });

    return terms.take(8).map((entry) => entry.key).join(' ');
  }

  void _addTerms(Map<String, int> weighted, String? text, int weight) {
    final value = text?.trim().toLowerCase();
    if (value == null || value.isEmpty) return;

    for (final term in value.split(RegExp(r'[\s,，、/|:：;；()（）\[\]【】]+'))) {
      final normalized = term.trim();
      if (normalized.length < 2) continue;
      weighted[normalized] = (weighted[normalized] ?? 0) + weight;
    }
  }

  List<KnowledgeChunkSearchResult> _selectWithinBudget(
    List<KnowledgeChunkSearchResult> results,
  ) {
    final selected = <KnowledgeChunkSearchResult>[];
    final seenChunks = <int>{};
    var tokens = 0;

    for (final result in results) {
      if (!seenChunks.add(result.chunk.id)) continue;
      final tokenEstimate = result.chunk.tokenEstimate;
      if (selected.isNotEmpty && tokens + tokenEstimate > maxTokens) {
        continue;
      }
      selected.add(result);
      tokens += tokenEstimate;
      if (selected.length >= maxChunks) break;
    }

    return selected;
  }
}

class KnowledgeContextBundle {
  const KnowledgeContextBundle({required this.query, required this.results});

  const KnowledgeContextBundle.empty() : query = '', results = const [];

  final String query;
  final List<KnowledgeChunkSearchResult> results;

  bool get isEmpty => results.isEmpty;

  int get tokenEstimate =>
      results.fold<int>(0, (sum, result) => sum + result.chunk.tokenEstimate);

  String toPromptSection() {
    if (results.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('【本地知识库检索片段】')
      ..writeln('检索词：$query')
      ..writeln('说明：以下片段来自用户本地导入资料，只能作为学习建议的依据；不要引用片段外的知识来断言具体概念。')
      ..writeln('引用规则：回答中如使用这些资料，请尽量标注为【片段 1】、【片段 2】这种编号。')
      ..writeln();

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final source = result.source;
      final chunk = result.chunk;
      final heading = chunk.heading?.trim();
      buffer
        ..writeln('片段 ${i + 1}: ${source.title}')
        ..writeln('标题：${heading == null || heading.isEmpty ? '无' : heading}')
        ..writeln('tokens：${chunk.tokenEstimate}')
        ..writeln(_compact(chunk.content))
        ..writeln();
    }

    return buffer.toString();
  }

  static String _compact(String value) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= 500) return text;
    return '${text.substring(0, 500)}...';
  }
}
