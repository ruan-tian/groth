/// 同义词映射表，用于查询扩展提升召回率。
class KnowledgeSynonyms {
  KnowledgeSynonyms._();

  static const _synonyms = <String, List<String>>{
    '进程': ['process', '任务', '程序'],
    '线程': ['thread', '协程'],
    '内存': ['存储器', '主存', 'RAM'],
    '缓存': ['cache', '高速缓存'],
    '算法': ['algorithm', '方法'],
    '数据库': ['database', 'DB'],
    '网络': ['network', '互联网'],
    '编译': ['compile', '汇编'],
    '函数': ['function', '方法', '映射'],
    '变量': ['variable', '参数'],
    '数组': ['array', '列表'],
    '链表': ['linked list'],
    '树': ['tree', '二叉树'],
    '图': ['graph', '网络结构'],
    '排序': ['sort', 'ordering'],
    '查找': ['search', '检索', '查询'],
    '递归': ['recursion', '迭代'],
    '概率': ['probability', '可能性'],
    '矩阵': ['matrix', '行列式'],
    '导数': ['derivative', '微分'],
    '积分': ['integral', 'integration'],
    '唯物主义': ['materialism'],
    '辩证法': ['dialectics'],
    '机器学习': ['machine learning', 'ML'],
    '深度学习': ['deep learning', 'DL'],
    '神经网络': ['neural network', 'NN'],
    '操作系统': ['operating system', 'OS'],
    '面向对象': ['object-oriented', 'OOP'],
    '继承': ['inheritance', '派生'],
    '多态': ['polymorphism'],
    '封装': ['encapsulation'],
    '死锁': ['deadlock', '死锁检测'],
    '分页': ['paging', '页面置换'],
    '虚拟内存': ['virtual memory'],
    '事务': ['transaction', 'ACID'],
    '索引': ['index', 'B树', 'B+树'],
    '路由': ['routing', '路由器'],
    '协议': ['protocol'],
    '加密': ['encryption', '密码学'],
    '哈希': ['hash', '散列', '杂凑'],
  };

  /// Returns synonym list for a term, or empty list if no synonyms.
  static List<String> synonymsFor(String term) {
    final lower = term.toLowerCase().trim();
    // Check direct match
    for (final entry in _synonyms.entries) {
      if (entry.key == lower || entry.value.any((v) => v.toLowerCase() == lower)) {
        return [entry.key, ...entry.value];
      }
    }
    return const [];
  }

  /// Expand a query with synonyms, returning all related terms.
  static List<String> expandQuery(String query) {
    final terms = query.split(RegExp(r'[\s,\u3001/]+'));
    final expanded = <String>{};
    for (final term in terms) {
      final trimmed = term.trim();
      if (trimmed.isEmpty) continue;
      expanded.add(trimmed);
      expanded.addAll(synonymsFor(trimmed));
    }
    return expanded.toList();
  }
}
