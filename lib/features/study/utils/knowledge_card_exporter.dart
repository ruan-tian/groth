import 'dart:convert';

import '../../../core/database/app_database.dart';
import 'knowledge_card_assets.dart';

class KnowledgeCardExporter {
  KnowledgeCardExporter._();

  static String toMarkdown(List<KnowledgeCard> cards) {
    if (cards.isEmpty) return '# 知识卡导出\n\n暂无知识卡。';

    final buffer = StringBuffer()
      ..writeln('# 知识卡导出')
      ..writeln()
      ..writeln('- 导出数量：${cards.length}')
      ..writeln();

    for (var i = 0; i < cards.length; i += 1) {
      final card = cards[i];
      final tags = _decodeTags(card.tags);
      buffer
        ..writeln('## ${i + 1}. ${_escapeMarkdown(card.title)}')
        ..writeln()
        ..writeln('- 目标：${_goalNameForCard(card)}')
        ..writeln('- 模块：${_moduleNameForCard(card)}')
        ..writeln(
          '- 章节：${card.subject?.trim().isEmpty == false ? card.subject!.trim() : '未填写'}',
        )
        ..writeln('- 掌握度：${card.masteryLevel}/5')
        ..writeln('- 复习次数：${card.reviewCount}')
        ..writeln('- 标签：${tags.isEmpty ? '无' : tags.join('、')}')
        ..writeln()
        ..writeln('**问题**')
        ..writeln()
        ..writeln(card.question.trim())
        ..writeln()
        ..writeln('**答案**')
        ..writeln()
        ..writeln(card.answer.trim())
        ..writeln();

      final explanation = card.explanation?.trim();
      if (explanation != null && explanation.isNotEmpty) {
        buffer
          ..writeln('**补充解释**')
          ..writeln()
          ..writeln(explanation)
          ..writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  static String toCsv(List<KnowledgeCard> cards) {
    const headers = [
      'title',
      'goal',
      'module',
      'chapter',
      'question',
      'answer',
      'explanation',
      'tags',
      'masteryLevel',
      'reviewCount',
      'archived',
    ];
    final rows = <List<String>>[
      headers,
      for (final card in cards)
        [
          card.title,
          _goalNameForCard(card),
          _moduleNameForCard(card),
          card.subject ?? '',
          card.question,
          card.answer,
          card.explanation ?? '',
          _decodeTags(card.tags).join(';'),
          card.masteryLevel.toString(),
          card.reviewCount.toString(),
          card.archived ? 'true' : 'false',
        ],
    ];

    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  static String _goalNameForCard(KnowledgeCard card) {
    if (card.goalKey != 'custom') {
      return KnowledgeCardAssets.goalForKey(card.goalKey).name;
    }
    final customName = card.goalName?.trim();
    return customName == null || customName.isEmpty ? '自定义目标' : customName;
  }

  static String _moduleNameForCard(KnowledgeCard card) {
    final module = KnowledgeCardAssets.moduleForKeys(
      card.goalKey,
      card.moduleKey,
    );
    if (module.deckKey != 'custom') return module.name;
    final customName = card.moduleName?.trim();
    return customName == null || customName.isEmpty ? module.name : customName;
  }

  static List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _escapeMarkdown(String value) {
    return value.replaceAll('\n', ' ').trim();
  }
}
