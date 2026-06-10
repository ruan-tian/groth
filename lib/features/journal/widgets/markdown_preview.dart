import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// 日记 Markdown 预览组件
///
/// 将 Markdown 文本渲染为格式化的 Flutter Widget，
/// 支持标题、加粗、斜体、删除线、高亮、列表、任务列表、引用、分割线、图片、代码块。
///
/// 当 [onContentChanged] 不为 null 时，任务列表的复选框可点击切换。
class JournalMarkdownPreview extends StatefulWidget {
  const JournalMarkdownPreview({
    super.key,
    required this.markdown,
    this.onContentChanged,
  });

  final String markdown;

  /// 当内容被修改时回调（例如任务列表复选框切换）。
  final ValueChanged<String>? onContentChanged;

  @override
  State<JournalMarkdownPreview> createState() => _JournalMarkdownPreviewState();
}

class _JournalMarkdownPreviewState extends State<JournalMarkdownPreview> {
  /// 用于追踪当前渲染到第几个 checkbox，以便点击时定位到对应的 Markdown 行。
  int _checkboxIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 每次 build 重置计数器
    _checkboxIndex = 0;

    return MarkdownBody(
      data: widget.markdown,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet(
        // Headings
        h1: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2329),
          height: 1.4,
        ),
        h2: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2329),
          height: 1.4,
        ),
        h3: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2329),
          height: 1.4,
        ),
        // Body
        p: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Color(0xFF1F2329),
        ),
        // Bold
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2329),
        ),
        // Italic
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF1F2329),
        ),
        // Strikethrough
        del: TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey.shade500,
        ),
        // Blockquote
        blockquote: const TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: Color(0xFF6B7280),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: const Color(0xFF9B8FE8).withValues(alpha: 0.5),
              width: 3,
            ),
          ),
          color: const Color(0xFFF0EFFF).withValues(alpha: 0.3),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        // Inline code
        code: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          backgroundColor: Color(0xFFF3F4F6),
          color: Color(0xFF1F2329),
        ),
        // Code block
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        // Lists
        listBullet: const TextStyle(color: Color(0xFF6B7280)),
        // Horizontal rule
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
      ),
      builders: {
        'mark': _HighlightBuilder(),
        'img': _LocalImageBuilder(),
      },
      checkboxBuilder: widget.onContentChanged != null
          ? _buildInteractiveCheckbox
          : _buildStaticCheckbox,
    );
  }

  /// 可交互的复选框：点击后切换对应行的 `[ ]` / `[x]`。
  Widget _buildInteractiveCheckbox(bool isChecked) {
    final index = _checkboxIndex++;
    return GestureDetector(
      onTap: () => _toggleTaskAtIndex(index),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(
          isChecked
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 20,
          color: isChecked ? const Color(0xFF9B8FE8) : const Color(0xFFC4C7D6),
        ),
      ),
    );
  }

  /// 静态复选框（不可点击）。
  Widget _buildStaticCheckbox(bool isChecked) {
    _checkboxIndex++;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        isChecked
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded,
        size: 20,
        color: isChecked ? const Color(0xFF9B8FE8) : const Color(0xFFC4C7D6),
      ),
    );
  }

  /// 切换第 [targetIndex] 个任务复选框的状态。
  void _toggleTaskAtIndex(int targetIndex) {
    final lines = widget.markdown.split('\n');
    int taskCounter = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // 匹配任务列表行： "* [ ] " / "- [x] " / "* [X] " 等
      final match = RegExp(r'^(\s*[-*]\s+)\[([ xX])\]\s').firstMatch(line);
      if (match != null) {
        if (taskCounter == targetIndex) {
          final prefix = match.group(1)!;
          final current = match.group(2)!;
          final newMark = (current == ' ') ? 'x' : ' ';
          lines[i] = '$prefix[$newMark] ${line.substring(match.end)}';
          break;
        }
        taskCounter++;
      }
    }

    final updated = lines.join('\n');
    widget.onContentChanged?.call(updated);
  }
}

/// 本地图片构建器
///
/// 将 `![image](local_path)` 渲染为本地文件图片，
/// 文件不存在时显示占位图标。
class _LocalImageBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'] ?? '';
    if (src.isEmpty) return const SizedBox.shrink();

    final file = File(src);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.data != true) {
              return _buildPlaceholder();
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFFC4C7D6)),
            SizedBox(height: 4),
            Text(
              '图片无法加载',
              style: TextStyle(fontSize: 12, color: Color(0xFFC4C7D6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 高亮文本构建器（`<mark>text</mark>` 语法）
class _HighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        element.textContent,
        style: (preferredStyle ?? const TextStyle()).copyWith(
          backgroundColor: const Color(0xFFFFF8DC),
        ),
      ),
    );
  }
}
