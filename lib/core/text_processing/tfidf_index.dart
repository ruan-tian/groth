import 'dart:math';

/// Lightweight in-memory TF-IDF index for knowledge chunk search.
///
/// Supports mixed Chinese/English text. Builds an inverted index
/// from chunk content and returns TF-IDF weighted scores for queries.
class TfidfIndex {
  TfidfIndex();

  // Inverted index: term -> list of (docIndex, tf)
  final Map<String, List<_TermEntry>> _invertedIndex = {};
  final List<_DocumentMeta> _documents = [];
  int _totalDocuments = 0;

  // ── Stop words ──────────────────────────────────────────────────────
  static const _stopWords = {
    '的', '了', '是', '在', '我', '有', '和', '就', '不', '人', '都', '一', '一个',
    '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好',
    '自己', '这', '他', '她', '它', '们', '那', '里', '为', '什么', '怎么', '如何',
    '可以', '可能', '应该', '已经', '还是', '但是', '因为', '所以', '如果', '虽然',
    '而且', '或者', '以及', '并且', '然后', '接着', '之后', '之前', '以上', '以下',
    '这个', '那个', '这些', '那些', '这里', '那里', '一些', '有些', '每个', '任何',
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'shall', 'can', 'need', 'dare', 'ought',
    'and', 'or', 'but', 'if', 'while', 'of', 'at', 'by', 'for', 'with',
    'about', 'between', 'through', 'to', 'from', 'in', 'on', 'it', 'this',
    'that', 'not', 'no', 'as', 'so', 'than', 'too', 'very',
  };

  // ── Chinese academic dictionary (for longest-match segmentation) ───
  static const _chineseTerms = {
    // 计算机科学
    '操作系统', '进程', '线程', '协程', '并发', '并行', '同步', '异步',
    '死锁', '互斥', '信号量', '临界区', '调度', '中断', '系统调用',
    '内存', '缓存', '虚拟内存', '分页', '分段', '页表', '缺页',
    '文件系统', '磁盘', '扇区', '索引', '目录', '权限',
    '网络', '协议', '路由', '交换', '传输', '报文', '套接字',
    '数据库', '事务', '查询', '范式', '主键', '外键', '视图',
    '算法', '排序', '查找', '递归', '迭代', '动态规划', '贪心',
    '数据结构', '数组', '链表', '栈', '队列', '树', '图', '哈希',
    '编译器', '解释器', '词法分析', '语法分析', '语义分析',
    '面向对象', '封装', '继承', '多态', '抽象', '接口', '类',
    '软件工程', '需求分析', '设计模式', '测试', '敏捷', '瀑布',
    '人工智能', '机器学习', '深度学习', '神经网络', '训练', '推理',
    '加密', '解密', '对称', '非对称', '数字签名',
    // 数学
    '函数', '导数', '积分', '极限', '微分', '方程', '矩阵', '向量',
    '概率', '统计', '期望', '方差', '分布', '假设检验', '回归',
    '集合', '映射', '关系', '群', '环', '域',
    // 考研政治
    '唯物主义', '辩证法', '认识论', '历史唯物主义', '矛盾', '实践',
    '剩余价值', '资本', '商品', '劳动', '市场经济', '社会主义',
    // 英语
    '词汇', '语法', '阅读', '写作', '翻译', '完形填空',
  };

  // Pre-sorted dictionary (longest first) for greedy matching.
  static final List<String> _sortedTerms = _chineseTerms.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  // ── English stemmer ────────────────────────────────────────────────
  static String _stem(String word) {
    if (word.length <= 3) return word;
    // Order matters: try longer suffixes first
    const suffixes = [
      'tion', 'sion', 'ment', 'ness', 'able', 'ible',
      'ing', 'ful', 'ous', 'ive', 'ed', 'er', 'ly', 'al', 'es', 's',
    ];
    for (final suffix in suffixes) {
      if (word.endsWith(suffix) && word.length - suffix.length >= 3) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  // ── Indexing & search ──────────────────────────────────────────────

  /// Build the index from a list of (id, text) pairs.
  ///
  /// [entries] should include all chunks to be indexed.
  /// Each entry has a unique [id] and the [text] content to index.
  void build(List<({int id, String text})> entries) {
    _invertedIndex.clear();
    _documents.clear();
    _totalDocuments = entries.length;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final terms = tokenize(entry.text);
      final termFreq = <String, int>{};
      for (final term in terms) {
        termFreq[term] = (termFreq[term] ?? 0) + 1;
      }

      _documents.add(_DocumentMeta(id: entry.id, termFreq: termFreq));

      for (final e in termFreq.entries) {
        _invertedIndex
            .putIfAbsent(e.key, () => <_TermEntry>[])
            .add(_TermEntry(docIndex: i, tf: e.value));
      }
    }
  }

  /// Compute TF-IDF scores for a query against all indexed documents.
  ///
  /// Returns a list of (id, score) pairs sorted by score descending.
  List<({int id, double score})> search(String query, {int limit = 20}) {
    if (_totalDocuments == 0) return const [];

    final queryTerms = tokenize(query);
    if (queryTerms.isEmpty) return const [];

    final scores = List<double>.filled(_totalDocuments, 0.0);

    for (final term in queryTerms) {
      final entries = _invertedIndex[term];
      if (entries == null || entries.isEmpty) continue;

      // IDF = log(N / df) where df = number of documents containing the term
      final df = entries.length;
      final idf = _log2(_totalDocuments / df);

      for (final entry in entries) {
        // TF = 1 + log(termFreq) if termFreq > 0, else 0
        final tf = 1 + _log2(entry.tf.toDouble());
        scores[entry.docIndex] += tf * idf;
      }
    }

    // Collect and sort results
    final results = <({int id, double score})>[];
    for (var i = 0; i < _totalDocuments; i++) {
      if (scores[i] > 0) {
        results.add((id: _documents[i].id, score: scores[i]));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList(growable: false);
  }

  // ── Tokenizer ──────────────────────────────────────────────────────

  /// Tokenize text into terms for TF-IDF indexing.
  ///
  /// Handles mixed Chinese/English text:
  /// 1. Dictionary-based longest-match for Chinese multi-char terms
  /// 2. Bigrams for remaining unmatched Chinese characters
  /// 3. English stemming and stop-word filtering
  static List<String> tokenize(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final result = <String>[];

    // Split into segments of consecutive Chinese chars vs. everything else.
    // Chinese range: U+4E00–U+9FFF
    final segments = _segmentByScript(normalized);

    for (final seg in segments) {
      if (seg.isChinese) {
        _tokenizeChinese(seg.text, result);
      } else {
        _tokenizeEnglish(seg.text, result);
      }
    }

    return result.toList(growable: false);
  }

  /// Split text into alternating Chinese / non-Chinese segments.
  static List<_ScriptSegment> _segmentByScript(String text) {
    final segments = <_ScriptSegment>[];
    final buffer = StringBuffer();
    bool? currentIsChinese;

    for (final char in text.split('')) {
      final code = char.codeUnitAt(0);
      final isChinese = code >= 0x4e00 && code <= 0x9fff;

      if (currentIsChinese == null) {
        currentIsChinese = isChinese;
      } else if (isChinese != currentIsChinese) {
        segments.add(_ScriptSegment(buffer.toString(), currentIsChinese));
        buffer.clear();
        currentIsChinese = isChinese;
      }
      buffer.write(char);
    }
    if (buffer.isNotEmpty && currentIsChinese != null) {
      segments.add(_ScriptSegment(buffer.toString(), currentIsChinese));
    }
    return segments;
  }

  /// Dictionary-first Chinese tokenizer: greedy longest match, then bigrams.
  static void _tokenizeChinese(String text, List<String> out) {
    final chars = text.split('');
    final matched = List<bool>.filled(chars.length, false);

    // Pass 1: greedy longest-match against dictionary.
    for (final term in _sortedTerms) {
      var start = 0;
      while (true) {
        final idx = text.indexOf(term, start);
        if (idx == -1) break;
        // Mark characters as matched.
        for (var i = idx; i < idx + term.length; i++) {
          matched[i] = true;
        }
        if (!_stopWords.contains(term)) {
          out.add(term);
        }
        start = idx + 1;
      }
    }

    // Pass 2: bigrams for unmatched characters.
    for (var i = 0; i < chars.length - 1; i++) {
      if (!matched[i] && !matched[i + 1]) {
        final bigram = chars[i] + chars[i + 1];
        if (!_stopWords.contains(bigram)) {
          out.add(bigram);
        }
      }
    }
  }

  /// Tokenize an English / punctuation segment: split on non-alphanumeric,
  /// apply stemming, and filter stop words.
  static void _tokenizeEnglish(String text, List<String> out) {
    final words = text.split(RegExp(r'[^a-z0-9_]+'));
    for (final word in words) {
      if (word.length < 2) continue;
      if (_stopWords.contains(word)) continue;
      out.add(_stem(word));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static double _log2(double x) {
    if (x <= 0) return 0;
    return log(x) / ln2;
  }
}

class _ScriptSegment {
  const _ScriptSegment(this.text, this.isChinese);
  final String text;
  final bool isChinese;
}

class _DocumentMeta {
  const _DocumentMeta({required this.id, required this.termFreq});
  final int id;
  final Map<String, int> termFreq;
}

class _TermEntry {
  const _TermEntry({required this.docIndex, required this.tf});
  final int docIndex;
  final int tf;
}
