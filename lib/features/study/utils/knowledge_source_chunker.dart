class KnowledgeSourceChunkDraft {
  const KnowledgeSourceChunkDraft({
    required this.index,
    required this.content,
    required this.tokenEstimate,
    this.heading,
  });

  final int index;
  final String? heading;
  final String content;
  final int tokenEstimate;
}

class KnowledgeSourceChunker {
  const KnowledgeSourceChunker({this.targetChars = 900, this.maxChars = 1400});

  final int targetChars;
  final int maxChars;

  List<KnowledgeSourceChunkDraft> split(String rawText) {
    final normalized = rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) return const [];

    final chunks = <KnowledgeSourceChunkDraft>[];
    final buffer = StringBuffer();
    String? currentHeading;

    void flush() {
      final content = buffer.toString().trim();
      if (content.isEmpty) return;
      chunks.add(
        KnowledgeSourceChunkDraft(
          index: chunks.length,
          heading: currentHeading,
          content: content,
          tokenEstimate: estimateTokens(content),
        ),
      );
      buffer.clear();
    }

    for (final block in normalized.split(RegExp(r'\n\s*\n+'))) {
      final text = block.trim();
      if (text.isEmpty) continue;
      final heading = _headingFromBlock(text);
      if (heading != null) {
        if (buffer.isNotEmpty) flush();
        currentHeading = heading;
      }

      if (text.length > maxChars) {
        if (buffer.isNotEmpty) flush();
        for (final part in _splitLongBlock(text)) {
          buffer.writeln(part);
          flush();
        }
        continue;
      }

      if (buffer.length + text.length > targetChars && buffer.isNotEmpty) {
        flush();
      }
      buffer.writeln(text);
      buffer.writeln();
    }

    flush();
    return chunks;
  }

  static int estimateTokens(String text) {
    if (text.trim().isEmpty) return 0;
    return (text.length / 1.8).ceil();
  }

  String? _headingFromBlock(String block) {
    final firstLine = block.split('\n').first.trim();
    if (firstLine.startsWith('#')) {
      return firstLine.replaceFirst(RegExp(r'^#+\s*'), '').trim();
    }
    if (firstLine.length <= 42 &&
        (RegExp(r'^(第.+[章节篇]|[一二三四五六七八九十]+[、.．])').hasMatch(firstLine) ||
            RegExp(r'^\d+(\.\d+)*\s+').hasMatch(firstLine))) {
      return firstLine;
    }
    return null;
  }

  Iterable<String> _splitLongBlock(String text) sync* {
    var start = 0;
    while (start < text.length) {
      var end = (start + maxChars).clamp(0, text.length);
      if (end < text.length) {
        final preferred = text.lastIndexOf(RegExp(r'[。！？.!?；;]\s*'), end);
        if (preferred > start + targetChars ~/ 2) {
          end = preferred + 1;
        }
      }
      yield text.substring(start, end).trim();
      start = end;
    }
  }
}
