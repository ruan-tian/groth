/// 日记 Markdown 工具类
class JournalMarkdownUtils {
  JournalMarkdownUtils._();

  // ── 插入类 ──

  /// 插入图片 Markdown
  static String insertImage(String text, int cursorPos, String localPath) {
    final md = '![image]($localPath)';
    return _insertAtCursor(text, cursorPos, md);
  }

  /// 插入分割线
  static String insertDivider(String text, int cursorPos) {
    return _insertAtCursor(text, cursorPos, '\n---\n');
  }

  /// 插入任务点（未完成）
  static String insertTaskUnchecked(String text, int cursorPos) {
    return _insertAtCursor(text, cursorPos, '* [ ] ');
  }

  /// 插入任务点（已完成）
  static String insertTaskChecked(String text, int cursorPos) {
    return _insertAtCursor(text, cursorPos, '* [x] ');
  }

  /// 插入代码块
  static String insertCodeBlock(String text, int cursorPos) {
    return _insertAtCursor(text, cursorPos, '\n```\n\n```\n');
  }

  /// 插入行内代码
  static String insertInlineCode(String text, int cursorPos, {String? selectedText}) {
    if (selectedText != null && selectedText.isNotEmpty) {
      final start = _getSelectionStart(text, cursorPos);
      return text.replaceRange(start, cursorPos, '`$selectedText`');
    }
    return _insertAtCursor(text, cursorPos, '``');
  }

  /// 插入引用块
  static String insertQuote(String text, int cursorPos, {String? selectedText}) {
    if (selectedText != null && selectedText.isNotEmpty) {
      final quoted = selectedText.split('\n').map((l) => '> $l').join('\n');
      return text.replaceRange(_getSelectionStart(text, cursorPos), cursorPos, quoted);
    }
    return _insertAtCursor(text, cursorPos, '> ');
  }

  // ── 文本样式类 ──

  /// 加粗
  static String toggleBold(String text, int cursorPos, {String? selectedText}) {
    return _wrapSelection(text, cursorPos, '**', selectedText: selectedText);
  }

  /// 斜体
  static String toggleItalic(String text, int cursorPos, {String? selectedText}) {
    return _wrapSelection(text, cursorPos, '*', selectedText: selectedText);
  }

  /// 下划线
  static String toggleUnderline(String text, int cursorPos, {String? selectedText}) {
    return _wrapSelection(text, cursorPos, '<u>', endTag: '</u>', selectedText: selectedText);
  }

  /// 删除线
  static String toggleStrikethrough(String text, int cursorPos, {String? selectedText}) {
    return _wrapSelection(text, cursorPos, '~~', selectedText: selectedText);
  }

  /// 高亮
  static String toggleHighlight(String text, int cursorPos, {String? selectedText}) {
    return _wrapSelection(text, cursorPos, '<mark>', endTag: '</mark>', selectedText: selectedText);
  }

  /// 清除格式
  static String clearFormat(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'(?<!\*)\*(?!\*)'), '')
        .replaceAll(RegExp(r'~~'), '')
        .replaceAll(RegExp(r'<u>|</u>'), '')
        .replaceAll(RegExp(r'<mark>|</mark>'), '')
        .replaceAll(RegExp(r'^#{1,3}\s', multiLine: true), '')
        .replaceAll(RegExp(r'^>\s', multiLine: true), '');
  }

  // ── 列表类 ──

  /// 插入无序列表
  static String insertUnorderedList(String text, int cursorPos) {
    return _insertAtCursor(text, cursorPos, '* ');
  }

  /// 插入有序列表
  static String insertOrderedList(String text, int cursorPos, {int number = 1}) {
    return _insertAtCursor(text, cursorPos, '$number. ');
  }

  // ── 标题类 ──

  /// 设置标题级别
  static String setHeading(String text, int cursorPos, int level) {
    // 先移除当前行的标题标记
    final lineStart = _getLineStart(text, cursorPos);
    final lineEnd = _getLineEnd(text, cursorPos);
    final line = text.substring(lineStart, lineEnd);
    final cleaned = line.replaceFirst(RegExp(r'^#{0,3}\s*'), '');
    
    if (level == 0) {
      // 正文
      return text.replaceRange(lineStart, lineEnd, cleaned);
    }
    
    final prefix = '${'#' * level} ';
    return text.replaceRange(lineStart, lineEnd, '$prefix$cleaned');
  }

  // ── 对齐类 ──

  /// 左对齐（扩展语法）
  static String alignLeft(String text, int cursorPos) {
    return _wrapLine(text, cursorPos, '<p align="left">', '</p>');
  }

  /// 居中（扩展语法）
  static String alignCenter(String text, int cursorPos) {
    return _wrapLine(text, cursorPos, '<p align="center">', '</p>');
  }

  /// 右对齐（扩展语法）
  static String alignRight(String text, int cursorPos) {
    return _wrapLine(text, cursorPos, '<p align="right">', '</p>');
  }

  // ── 工具方法 ──

  /// 在光标位置插入文本
  static String _insertAtCursor(String text, int cursorPos, String insert) {
    final pos = cursorPos.clamp(0, text.length);
    return text.substring(0, pos) + insert + text.substring(pos);
  }

  /// 包裹选中文本
  static String _wrapSelection(
    String text,
    int cursorPos,
    String startTag, {
    String? endTag,
    String? selectedText,
  }) {
    endTag ??= startTag;
    if (selectedText != null && selectedText.isNotEmpty) {
      final start = _getSelectionStart(text, cursorPos);
      final wrapped = '$startTag$selectedText$endTag';
      return text.replaceRange(start, cursorPos, wrapped);
    }
    return _insertAtCursor(text, cursorPos, '$startTag$endTag');
  }

  /// 包裹当前行
  static String _wrapLine(String text, int cursorPos, String startTag, String endTag) {
    final lineStart = _getLineStart(text, cursorPos);
    final lineEnd = _getLineEnd(text, cursorPos);
    final line = text.substring(lineStart, lineEnd);
    return text.replaceRange(lineStart, lineEnd, '$startTag$line$endTag');
  }

  /// 获取当前行起始位置
  static int _getLineStart(String text, int cursorPos) {
    final pos = cursorPos.clamp(0, text.length);
    final lastNewline = text.lastIndexOf('\n', pos - 1);
    return lastNewline == -1 ? 0 : lastNewline + 1;
  }

  /// 获取当前行结束位置
  static int _getLineEnd(String text, int cursorPos) {
    final pos = cursorPos.clamp(0, text.length);
    final nextNewline = text.indexOf('\n', pos);
    return nextNewline == -1 ? text.length : nextNewline;
  }

  /// 获取选区起始位置
  static int _getSelectionStart(String text, int cursorPos) {
    // 简单实现：返回光标位置
    return cursorPos;
  }

  /// 提取纯文本（去除 Markdown 标记）
  static String extractPlainText(String markdown) {
    return markdown
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '') // 图片
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '') // 链接
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // 代码块
        .replaceAll(RegExp(r'`[^`]+`'), '') // 行内代码
        .replaceAll(RegExp(r'\*\*|~~|<u>|</u>|<mark>|</mark>'), '') // 格式标记
        .replaceAll(RegExp(r'(?<!\*)\*(?!\*)'), '') // 斜体
        .replaceAll(RegExp(r'^#{1,3}\s', multiLine: true), '') // 标题
        .replaceAll(RegExp(r'^>\s', multiLine: true), '') // 引用
        .replaceAll(RegExp(r'^\*\s', multiLine: true), '') // 无序列表
        .replaceAll(RegExp(r'^\d+\.\s', multiLine: true), '') // 有序列表
        .replaceAll(RegExp(r'^\*\s\[[ x]\]\s', multiLine: true), '') // 任务列表
        .replaceAll(RegExp(r'^---$', multiLine: true), '') // 分割线
        .replaceAll(RegExp(r'<p align=".*?">|</p>'), '') // 对齐标签
        .trim();
  }

  /// 计算字数（基于纯文本）
  static int countWords(String plainText) {
    if (plainText.isEmpty) return 0;
    // 中文按字符计数，英文按单词计数
    final chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(plainText).length;
    final englishWords = plainText
        .replaceAll(RegExp(r'[\u4e00-\u9fa5]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return chineseChars + englishWords;
  }
}
