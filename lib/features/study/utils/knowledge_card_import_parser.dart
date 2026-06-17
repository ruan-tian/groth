class ParsedKnowledgeCardDraft {
  const ParsedKnowledgeCardDraft({
    required this.title,
    required this.question,
    required this.answer,
    this.subject,
    this.explanation,
    this.tags = const [],
  });

  final String title;
  final String question;
  final String answer;
  final String? subject;
  final String? explanation;
  final List<String> tags;
}

class KnowledgeCardImportParseError {
  const KnowledgeCardImportParseError({
    required this.message,
    this.line,
    this.block,
  });

  final String message;
  final int? line;
  final int? block;

  String get displayText {
    if (line != null) return '第 $line 行：$message';
    if (block != null) return '第 $block 段：$message';
    return message;
  }
}

class KnowledgeCardImportParseResult {
  const KnowledgeCardImportParseResult({
    required this.drafts,
    required this.errors,
  });

  final List<ParsedKnowledgeCardDraft> drafts;
  final List<KnowledgeCardImportParseError> errors;

  bool get hasDrafts => drafts.isNotEmpty;
}

class KnowledgeCardImportParser {
  KnowledgeCardImportParser._();

  static KnowledgeCardImportParseResult parse(String raw) {
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (text.isEmpty) {
      return const KnowledgeCardImportParseResult(
        drafts: [],
        errors: [KnowledgeCardImportParseError(message: '先粘贴要导入的知识点文本')],
      );
    }

    final hasBlockLabels = RegExp(
      r'(^|\n)\s*(Q|A|Question|Answer|Title|Chapter|Section|Explanation|Explain|Tag|Tags|问题|答案|标题|章节|单元|知识单元|解释|补充|标签)\s*[:：]',
      caseSensitive: false,
    ).hasMatch(text);
    return hasBlockLabels ? _parseBlocks(text) : _parsePipeLines(text);
  }

  static KnowledgeCardImportParseResult _parsePipeLines(String text) {
    final drafts = <ParsedKnowledgeCardDraft>[];
    final errors = <KnowledgeCardImportParseError>[];
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split('|').map((part) => part.trim()).toList();
      if (parts.length < 2) {
        errors.add(
          KnowledgeCardImportParseError(line: i + 1, message: '请使用“问题|答案”格式'),
        );
        continue;
      }

      final question = parts[0];
      final answer = parts[1];
      if (question.isEmpty || answer.isEmpty) {
        errors.add(
          KnowledgeCardImportParseError(line: i + 1, message: '问题和答案都不能为空'),
        );
        continue;
      }

      var title = _titleFromQuestion(question);
      String? subject;
      var tags = const <String>[];

      if (parts.length == 3) {
        subject = _nullable(parts[2]);
      } else if (parts.length == 4) {
        subject = _nullable(parts[2]);
        tags = _parseTags(parts[3]);
      } else if (parts.length >= 5) {
        title = _nullable(parts[2]) ?? title;
        subject = _nullable(parts[3]);
        tags = _parseTags(parts.sublist(4).join(','));
      }

      drafts.add(
        ParsedKnowledgeCardDraft(
          title: title,
          question: question,
          answer: answer,
          subject: subject,
          tags: tags,
        ),
      );
    }

    return KnowledgeCardImportParseResult(drafts: drafts, errors: errors);
  }

  static KnowledgeCardImportParseResult _parseBlocks(String text) {
    final blocks = _splitBlocks(text);
    final drafts = <ParsedKnowledgeCardDraft>[];
    final errors = <KnowledgeCardImportParseError>[];

    for (var i = 0; i < blocks.length; i += 1) {
      final fields = _parseBlockFields(blocks[i]);
      final question = _nullable(fields['question'] ?? '');
      final answer = _nullable(fields['answer'] ?? '');

      if (question == null || answer == null) {
        errors.add(
          KnowledgeCardImportParseError(block: i + 1, message: '每段至少需要问题和答案'),
        );
        continue;
      }

      drafts.add(
        ParsedKnowledgeCardDraft(
          title:
              _nullable(fields['title'] ?? '') ?? _titleFromQuestion(question),
          question: question,
          answer: answer,
          subject: _nullable(fields['subject'] ?? ''),
          explanation: _nullable(fields['explanation'] ?? ''),
          tags: _parseTags(fields['tags'] ?? ''),
        ),
      );
    }

    return KnowledgeCardImportParseResult(drafts: drafts, errors: errors);
  }

  static List<List<String>> _splitBlocks(String text) {
    final blocks = <List<String>>[];
    var current = <String>[];

    for (final line in text.split('\n')) {
      if (RegExp(r'^\s*---+\s*$').hasMatch(line)) {
        if (current.any((item) => item.trim().isNotEmpty)) {
          blocks.add(current);
        }
        current = <String>[];
      } else {
        current.add(line);
      }
    }

    if (current.any((item) => item.trim().isNotEmpty)) {
      blocks.add(current);
    }
    return blocks;
  }

  static Map<String, String> _parseBlockFields(List<String> lines) {
    final fields = <String, String>{};
    String? currentKey;

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) continue;

      final match = RegExp(
        r'^\s*([^:：]{1,16})\s*[:：]\s*(.*)$',
      ).firstMatch(line);
      if (match != null) {
        final key = _normalizeLabel(match.group(1) ?? '');
        if (key != null) {
          currentKey = key;
          fields[key] = _appendLine(fields[key], match.group(2)?.trim() ?? '');
          continue;
        }
      }

      if (currentKey != null) {
        fields[currentKey] = _appendLine(fields[currentKey], line.trim());
      }
    }

    return fields;
  }

  static String? _normalizeLabel(String raw) {
    final label = raw.trim().toLowerCase();
    switch (label) {
      case 'q':
      case 'question':
      case '问题':
        return 'question';
      case 'a':
      case 'answer':
      case '答案':
        return 'answer';
      case 'title':
      case '标题':
        return 'title';
      case 'chapter':
      case 'section':
      case '章节':
      case '单元':
      case '知识单元':
        return 'subject';
      case 'explanation':
      case 'explain':
      case '解释':
      case '补充':
        return 'explanation';
      case 'tag':
      case 'tags':
      case '标签':
        return 'tags';
    }
    return null;
  }

  static String _appendLine(String? current, String next) {
    if (next.isEmpty) return current ?? '';
    if (current == null || current.trim().isEmpty) return next;
    return '$current\n$next';
  }

  static List<String> _parseTags(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'[,，、;；\n]+'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static String _titleFromQuestion(String question) {
    var title = question.trim();
    while (title.isNotEmpty && RegExp(r'[?？!！。.;；:：]$').hasMatch(title)) {
      title = title.substring(0, title.length - 1).trimRight();
    }
    if (title.isEmpty) return '未命名知识点';
    const maxRunes = 28;
    if (title.runes.length <= maxRunes) return title;
    return String.fromCharCodes(title.runes.take(maxRunes));
  }

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
