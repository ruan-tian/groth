import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/study/utils/knowledge_card_import_parser.dart';

void main() {
  group('KnowledgeCardImportParser', () {
    test('parses pipe lines with chapter and tags', () {
      final result = KnowledgeCardImportParser.parse('''
进程和线程有什么区别？|进程是资源分配单位，线程是 CPU 调度单位。|操作系统
行测资料分析速算技巧？|先估算量级，再处理尾数。|资料分析|高频，易错
''');

      expect(result.errors, isEmpty);
      expect(result.drafts, hasLength(2));
      expect(result.drafts.first.title, '进程和线程有什么区别');
      expect(result.drafts.first.subject, '操作系统');
      expect(result.drafts.last.subject, '资料分析');
      expect(result.drafts.last.tags, ['高频', '易错']);
    });

    test('parses block cards with Chinese labels', () {
      final result = KnowledgeCardImportParser.parse('''
标题：生产力与生产关系
问题：生产力和生产关系的辩证关系是什么？
答案：生产力决定生产关系，生产关系反作用于生产力。
章节：马原
标签：政治，基础
---
Q: What is an index in database?
A: A data structure that speeds up lookup at extra write/storage cost.
Chapter: Database
''');

      expect(result.errors, isEmpty);
      expect(result.drafts, hasLength(2));
      expect(result.drafts.first.title, '生产力与生产关系');
      expect(result.drafts.first.subject, '马原');
      expect(result.drafts.first.tags, ['政治', '基础']);
      expect(result.drafts.last.title, 'What is an index in database');
      expect(result.drafts.last.subject, 'Database');
    });

    test('keeps valid cards and reports invalid rows', () {
      final result = KnowledgeCardImportParser.parse('''
只有问题没有答案
有效问题|有效答案
|空问题
''');

      expect(result.drafts, hasLength(1));
      expect(result.errors, hasLength(2));
      expect(result.errors.first.displayText, contains('第 1 行'));
    });
  });
}
