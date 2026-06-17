import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/ai/services/ai_analysis_card_service.dart';

void main() {
  group('AiAnalysisCardService', () {
    const service = AiAnalysisCardService();

    test('builds actionable card drafts from analysis suggestions', () {
      final drafts = service.buildDraftsFromAnalysis('''
整体不错。
1. 建议优先复习进程和线程的区别，尤其是资源分配单位与 CPU 调度单位。
2. 下一步可以把分页地址组成做成每日复习题。
''');

      expect(drafts, hasLength(2));
      expect(drafts.first.question, contains('建议我如何处理'));
      expect(drafts.first.answer, contains('优先复习进程和线程'));
      expect(drafts.first.tags, contains('AI分析'));
    });

    test('falls back to a summary draft when no actionable line is found', () {
      final drafts = service.buildDraftsFromAnalysis('这是一段没有明确行动词的分析摘要。');

      expect(drafts, hasLength(1));
      expect(drafts.single.title, 'AI 分析要点');
      expect(drafts.single.answer, contains('分析摘要'));
    });
  });
}
