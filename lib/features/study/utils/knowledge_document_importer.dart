import 'dart:io';

import 'package:doc_text_extractor/doc_text_extractor.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Result of extracting text from a document or web source.
class DocumentImportResult {
  const DocumentImportResult({
    required this.title,
    required this.content,
    required this.type,
    this.sourcePath,
    this.errorMessage,
  });

  final String title;
  final String content;
  final String type;
  final String? sourcePath;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null && content.trim().isNotEmpty;

  String? get displayError => errorMessage;
}

/// Extracts text from PDF, Word (.docx), and web pages for import into
/// the local knowledge base.
class KnowledgeDocumentImporter {
  KnowledgeDocumentImporter() : _extractor = TextExtractor();

  final TextExtractor _extractor;

  /// Extract text from a local file (PDF, Word, TXT, or Markdown).
  Future<DocumentImportResult> extractFromFile(
    File file, {
    Future<String> Function(List<int> imageBytes, String mimeType)? ocrCallback,
  }) async {
    final path = file.path;
    final lowerPath = path.toLowerCase();

    if (lowerPath.endsWith('.pdf') ||
        lowerPath.endsWith('.docx') ||
        lowerPath.endsWith('.doc') ||
        lowerPath.endsWith('.md')) {
      final result = await _extractWithDocTextExtractor(file);
      // If PDF text extraction returned empty (scanned PDF) and OCR is available
      if (!result.isSuccess &&
          lowerPath.endsWith('.pdf') &&
          ocrCallback != null) {
        return _extractFromImageWithOcr(file, ocrCallback, type: 'pdf_ocr');
      }
      return result;
    } else if (lowerPath.endsWith('.txt')) {
      return _extractFromPlainText(file);
    } else if (_isImageFile(lowerPath)) {
      if (ocrCallback == null) {
        return DocumentImportResult(
          title: _fileNameWithoutExtension(path),
          content: '',
          type: 'image',
          sourcePath: path,
          errorMessage: '图片导入需要配置 AI API Key 以启用 OCR 文字识别。',
        );
      }
      return _extractFromImageWithOcr(file, ocrCallback, type: 'image_ocr');
    }

    return DocumentImportResult(
      title: _fileNameWithoutExtension(path),
      content: '',
      type: 'text',
      sourcePath: path,
      errorMessage:
          '不支持的文件格式：${_fileExtension(path)}。支持 PDF、Word (.docx)、TXT、Markdown 和图片。',
    );
  }

  /// Fetch and extract text content from a web URL.
  ///
  /// Strips HTML tags and navigation, keeping main article content.
  Future<DocumentImportResult> extractFromUrl(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    if (normalizedUrl.isEmpty) {
      return const DocumentImportResult(
        title: '',
        content: '',
        type: 'web',
        errorMessage: '请输入有效的网页 URL。',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse(normalizedUrl),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return DocumentImportResult(
          title: '',
          content: '',
          type: 'web',
          sourcePath: normalizedUrl,
          errorMessage: '网页请求失败 (${response.statusCode})。',
        );
      }

      final htmlBody = response.body;
      return _parseHtmlContent(htmlBody, normalizedUrl);
    } on Exception catch (e) {
      return DocumentImportResult(
        title: '',
        content: '',
        type: 'web',
        sourcePath: normalizedUrl,
        errorMessage: '网页抓取失败：${e.toString().split('\n').first}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // doc_text_extractor based extraction
  // ---------------------------------------------------------------------------

  Future<DocumentImportResult> _extractWithDocTextExtractor(File file) async {
    try {
      final result = await _extractor.extractText(file.path, isUrl: false);
      final trimmed = result.text.trim();
      if (trimmed.isEmpty) {
        return DocumentImportResult(
          title: _fileNameWithoutExtension(file.path),
          content: '',
          type: _typeForFile(file.path),
          sourcePath: file.path,
          errorMessage: '文件无法提取文字，可能是扫描件或纯图片文件。',
        );
      }

      return DocumentImportResult(
        title: result.filename.isNotEmpty
            ? _fileNameWithoutExtension(result.filename)
            : _fileNameWithoutExtension(file.path),
        content: _cleanExtractedText(trimmed),
        type: _typeForFile(file.path),
        sourcePath: file.path,
      );
    } on Exception catch (e) {
      return DocumentImportResult(
        title: _fileNameWithoutExtension(file.path),
        content: '',
        type: _typeForFile(file.path),
        sourcePath: file.path,
        errorMessage: '文件解析失败：${e.toString().split('\n').first}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Plain text / Markdown (fallback for .txt)
  // ---------------------------------------------------------------------------

  Future<DocumentImportResult> _extractFromPlainText(File file) async {
    try {
      final text = await file.readAsString();
      final trimmed = text.trim();

      return DocumentImportResult(
        title: _fileNameWithoutExtension(file.path),
        content: trimmed,
        type: 'text',
        sourcePath: file.path,
      );
    } on Exception catch (e) {
      return DocumentImportResult(
        title: _fileNameWithoutExtension(file.path),
        content: '',
        type: 'text',
        sourcePath: file.path,
        errorMessage: '文件读取失败：${e.toString().split('\n').first}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HTML parsing
  // ---------------------------------------------------------------------------

  DocumentImportResult _parseHtmlContent(String html, String url) {
    try {
      final document = html_parser.parseFragment(html);

      // Try to extract title
      String title = '';
      final titleElement = document.querySelector('title');
      if (titleElement != null) {
        title = titleElement.text.trim();
      }
      if (title.isEmpty) {
        final h1 = document.querySelector('h1');
        if (h1 != null) {
          title = h1.text.trim();
        }
      }
      if (title.isEmpty) {
        title = _fileNameWithoutExtension(url);
      }

      // Try to find main content area
      String content = '';

      // Priority: article > main > .content > .article > body
      final contentSelectors = [
        'article',
        '[role="main"]',
        'main',
        '.content',
        '.article',
        '.post-content',
        '.entry-content',
        '#content',
        '#article',
      ];

      for (final selector in contentSelectors) {
        final element = document.querySelector(selector);
        if (element != null) {
          content = _extractTextFromElement(element);
          if (content.trim().length > 100) break;
        }
      }

      // Fallback to body text
      if (content.trim().length < 100) {
        final body = document.querySelector('body');
        if (body != null) {
          content = _extractTextFromElement(body);
        }
      }

      content = _cleanExtractedText(content);

      // Guard against extremely large content
      if (content.length > 500000) {
        content = content.substring(0, 500000);
      }

      if (content.trim().isEmpty) {
        return DocumentImportResult(
          title: title,
          content: '',
          type: 'web',
          sourcePath: url,
          errorMessage: '网页内容为空或无法提取正文。',
        );
      }

      return DocumentImportResult(
        title: title,
        content: content.trim(),
        type: 'web',
        sourcePath: url,
      );
    } on Exception catch (e) {
      return DocumentImportResult(
        title: _fileNameWithoutExtension(url),
        content: '',
        type: 'web',
        sourcePath: url,
        errorMessage: '网页内容解析失败：${e.toString().split('\n').first}',
      );
    }
  }

  String _extractTextFromElement(dynamic element) {
    final buffer = StringBuffer();
    _walkTextNodes(element, buffer);
    return buffer.toString();
  }

  void _walkTextNodes(dynamic node, StringBuffer buffer, [int depth = 0]) {
    if (node == null || depth > 50) return;

    final tag = node.localName?.toLowerCase() ?? '';

    // Skip noise elements
    if ([
      'script',
      'style',
      'nav',
      'footer',
      'header',
      'noscript',
      'svg',
      'iframe',
    ].contains(tag)) {
      return;
    }

    // Add newlines for block elements
    if ([
      'p',
      'div',
      'br',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'li',
      'tr',
      'blockquote',
      'section',
    ].contains(tag)) {
      if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
        buffer.writeln();
      }
    }

    // Add heading markers
    if (tag.startsWith('h') && tag.length == 2) {
      final level = int.tryParse(tag[1]) ?? 1;
      buffer.write('${'#' * level} ');
    }

    // Process child nodes
    if (node.nodes != null) {
      for (final child in node.nodes!) {
        _walkTextNodes(child, buffer, depth + 1);
      }
    }

    // Add text content for text nodes
    final text = node.text?.trim();
    if (text != null && text.isNotEmpty && node.nodeType == 3) {
      buffer.write(text);
      buffer.write(' ');
    }

    // Add newline after block elements
    if ([
      'p',
      'div',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'li',
      'tr',
      'blockquote',
      'section',
    ].contains(tag)) {
      buffer.writeln();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<DocumentImportResult> _extractFromImageWithOcr(
    File file,
    Future<String> Function(List<int> imageBytes, String mimeType)
    ocrCallback, {
    required String type,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return DocumentImportResult(
          title: _fileNameWithoutExtension(file.path),
          content: '',
          type: type,
          sourcePath: file.path,
          errorMessage: '图片文件为空。',
        );
      }

      final mimeType = _mimeTypeForFile(file.path);
      final extractedText = await ocrCallback(bytes, mimeType);

      if (extractedText.trim().isEmpty) {
        return DocumentImportResult(
          title: _fileNameWithoutExtension(file.path),
          content: '',
          type: type,
          sourcePath: file.path,
          errorMessage: 'OCR 未识别到文字内容，图片可能不包含文字或清晰度不足。',
        );
      }

      return DocumentImportResult(
        title: _fileNameWithoutExtension(file.path),
        content: _cleanExtractedText(extractedText),
        type: type,
        sourcePath: file.path,
      );
    } on Exception catch (e) {
      return DocumentImportResult(
        title: _fileNameWithoutExtension(file.path),
        content: '',
        type: type,
        sourcePath: file.path,
        errorMessage: 'OCR 识别失败：${e.toString().split('\n').first}',
      );
    }
  }

  bool _isImageFile(String lowerPath) {
    return lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.bmp') ||
        lowerPath.endsWith('.gif') ||
        lowerPath.endsWith('.webp');
  }

  String _mimeTypeForFile(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }

  String _typeForFile(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf_text';
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return 'docx_text';
    if (lower.endsWith('.md')) return 'markdown';
    return 'text';
  }

  String _cleanExtractedText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n \n'), '\n\n')
        .trim();
  }

  String _fileNameWithoutExtension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  String _fileExtension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(dotIndex) : '';
  }

  String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    try {
      Uri.parse(trimmed);
      return trimmed;
    } catch (_) {
      return '';
    }
  }
}
