import '../../../core/database/app_database.dart';
import '../repositories/knowledge_v3_repository.dart';

class KnowledgeContextServiceV3 {
  KnowledgeContextServiceV3(this._repository);

  final KnowledgeV3Repository _repository;

  static const int maxMaterials = 4;
  static const int maxTokens = 1200;

  Future<KnowledgeContextBundleV3> buildForStudyRecords(
    List<StudyRecord> records, {
    int? spaceId,
  }) async {
    final query = _buildStudyQuery(records);
    return buildForQuery(query, spaceId: spaceId);
  }

  Future<KnowledgeContextBundleV3> buildForQuery(
    String query, {
    int? spaceId,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const KnowledgeContextBundleV3.empty();
    }

    // 如果没有指定空间，获取默认空间
    final targetSpaceId = spaceId ?? (await _repository.ensureDefaultSpace()).id;

    final materials = await _repository.searchMaterials(
      spaceId: targetSpaceId,
      query: normalized,
      limit: maxMaterials * 2,
    );
    final selected = _selectWithinBudget(materials);
    return KnowledgeContextBundleV3(
      query: normalized,
      materials: selected,
      spaceId: targetSpaceId,
    );
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

  List<KnowledgeMaterial> _selectWithinBudget(List<KnowledgeMaterial> materials) {
    final selected = <KnowledgeMaterial>[];
    var tokens = 0;

    for (final material in materials) {
      final tokenEstimate = _estimateTokens(material.content);
      if (selected.isNotEmpty && tokens + tokenEstimate > maxTokens) {
        continue;
      }
      selected.add(material);
      tokens += tokenEstimate;
      if (selected.length >= maxMaterials) break;
    }

    return selected;
  }

  int _estimateTokens(String text) {
    // 粗略估计：中文 1 字 ≈ 1.5 token，英文 1 词 ≈ 1 token
    final chineseChars = RegExp(r'[\u4e00-\u9fff]').allMatches(text).length;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (chineseChars * 1.5 + words).round();
  }
}

class KnowledgeContextBundleV3 {
  const KnowledgeContextBundleV3({
    required this.query,
    required this.materials,
    this.spaceId,
  });

  // 向后兼容：接受 results 参数
  factory KnowledgeContextBundleV3.withResults({
    required String query,
    required List<KnowledgeMaterial> results,
    int? spaceId,
  }) {
    return KnowledgeContextBundleV3(
      query: query,
      materials: results,
      spaceId: spaceId,
    );
  }

  const KnowledgeContextBundleV3.empty()
      : query = '',
        materials = const [],
        spaceId = null;

  final String query;
  final List<KnowledgeMaterial> materials;
  final int? spaceId;

  bool get isEmpty => materials.isEmpty;

  // 向后兼容：results 等同于 materials
  List<KnowledgeMaterial> get results => materials;

  int get tokenEstimate => materials.fold<int>(
        0,
        (sum, material) =>
            sum +
            (RegExp(r'[\u4e00-\u9fff]').allMatches(material.content).length * 1.5)
                .round(),
      );

  String toPromptSection() {
    if (materials.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('【本地知识库检索片段】')
      ..writeln('检索词：$query')
      ..writeln(
          '说明：以下片段来自用户本地导入资料，只能作为学习建议的依据；不要引用片段外的知识来断言具体概念。')
      ..writeln(
          '引用规则：回答中如使用这些资料，请尽量标注为【资料 1】、【资料 2】这种编号。')
      ..writeln();

    for (var i = 0; i < materials.length; i++) {
      final material = materials[i];
      buffer
        ..writeln('资料 ${i + 1}: ${material.title}')
        ..writeln(_compact(material.content))
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
