import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/study/utils/knowledge_card_exporter.dart';

KnowledgeCard _card({
  String title = '进程与线程',
  String question = '进程和线程有什么区别？',
  String answer = '进程是资源分配单位，线程是 CPU 调度单位。',
  String? tags = '["408","易错"]',
  bool archived = false,
}) {
  final now = DateTime(2026, 6, 15).millisecondsSinceEpoch;
  return KnowledgeCard(
    id: 1,
    deckKey: 'computer',
    goalKey: 'kaoyan_computer',
    goalName: null,
    moduleKey: 'operating_system',
    moduleName: null,
    subject: '操作系统',
    title: title,
    question: question,
    answer: answer,
    explanation: '补充说明',
    tags: tags,
    sourceStudyId: null,
    masteryLevel: 2,
    reviewCount: 3,
    correctStreak: 0,
    lastReviewedAt: now,
    dueAt: now,
    archived: archived,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('exports knowledge cards as markdown', () {
    final markdown = KnowledgeCardExporter.toMarkdown([_card()]);

    expect(markdown, contains('# 知识卡导出'));
    expect(markdown, contains('## 1. 进程与线程'));
    expect(markdown, contains('- 目标：考研·计算机'));
    expect(markdown, contains('**问题**'));
    expect(markdown, contains('进程和线程有什么区别？'));
    expect(markdown, contains('408、易错'));
  });

  test('exports knowledge cards as csv with escaping', () {
    final csv = KnowledgeCardExporter.toCsv([
      _card(title: '带,逗号 "标题"', question: 'Q,1', answer: 'A "quoted"'),
    ]);

    expect(csv, startsWith('"title","goal","module"'));
    expect(csv, contains('"带,逗号 ""标题"""'));
    expect(csv, contains('"Q,1"'));
    expect(csv, contains('"A ""quoted"""'));
  });
}
