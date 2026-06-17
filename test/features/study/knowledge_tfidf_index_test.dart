import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/study/utils/knowledge_tfidf_index.dart';

void main() {
  group('TfidfIndex', () {
    group('tokenize', () {
      test('splits English text into lowercase terms', () {
        final terms = TfidfIndex.tokenize('Hello World Test');
        expect(terms, containsAll(['hello', 'world', 'test']));
      });

      test('splits Chinese text using dictionary matching', () {
        final terms = TfidfIndex.tokenize('机器学习');
        // Dictionary matches '机器学习' as a whole term
        expect(terms, contains('机器学习'));
        // Should also produce bigrams for unmatched chars as fallback
        // '机器学习' is fully matched by dictionary, so no leftover bigrams
      });

      test('handles mixed Chinese/English text', () {
        final terms = TfidfIndex.tokenize('Python 机器学习 algorithm');
        expect(terms, contains('python'));
        expect(terms, contains('algorithm'));
        // Dictionary matches '机器学习' as a whole term
        expect(terms, contains('机器学习'));
      });

      test('drops single-character English terms', () {
        final terms = TfidfIndex.tokenize('a b hello world');
        expect(terms, isNot(contains('a')));
        expect(terms, isNot(contains('b')));
        expect(terms, contains('hello'));
      });

      test('handles empty text', () {
        final terms = TfidfIndex.tokenize('');
        expect(terms, isEmpty);
      });

      test('handles punctuation', () {
        final terms = TfidfIndex.tokenize('hello, world! test.');
        expect(terms, contains('hello'));
        expect(terms, contains('world'));
        expect(terms, contains('test'));
      });
    });

    group('search', () {
      test('returns empty for empty index', () {
        final index = TfidfIndex();
        final results = index.search('test');
        expect(results, isEmpty);
      });

      test('finds exact matches', () {
        final index = TfidfIndex();
        index.build([
          (id: 1, text: '机器学习是人工智能的一个分支'),
          (id: 2, text: '深度学习是机器学习的子集'),
          (id: 3, text: '数据库系统原理'),
        ]);

        final results = index.search('机器学习');
        expect(results, isNotEmpty);
        expect(results.first.id, isIn([1, 2]));
      });

      test('ranks more relevant documents higher', () {
        final index = TfidfIndex();
        index.build([
          (id: 1, text: '机器学习 machine learning 机器学习 机器学习'),
          (id: 2, text: '深度学习是机器学习的一个子集'),
          (id: 3, text: '数据库系统与SQL查询优化'),
        ]);

        final results = index.search('机器学习');
        expect(results, isNotEmpty);
        // Document 1 has more occurrences, should rank higher
        expect(results.first.id, 1);
      });

      test('returns results sorted by score descending', () {
        final index = TfidfIndex();
        index.build([
          (id: 1, text: 'Flutter is a UI framework for building apps'),
          (id: 2, text: 'Dart programming language used by Flutter'),
          (id: 3, text: 'Python is a general purpose programming language'),
        ]);

        final results = index.search('Flutter');
        expect(results.length, greaterThanOrEqualTo(2));
        // Scores should be in descending order
        for (var i = 0; i < results.length - 1; i++) {
          expect(
            results[i].score,
            greaterThanOrEqualTo(results[i + 1].score),
          );
        }
      });

      test('respects limit parameter', () {
        final index = TfidfIndex();
        index.build([
          (id: 1, text: 'test content one'),
          (id: 2, text: 'test content two'),
          (id: 3, text: 'test content three'),
          (id: 4, text: 'test content four'),
          (id: 5, text: 'test content five'),
        ]);

        final results = index.search('test', limit: 3);
        expect(results.length, lessThanOrEqualTo(3));
      });

      test('ignores terms not in index', () {
        final index = TfidfIndex();
        index.build([
          (id: 1, text: '机器学习基础'),
          (id: 2, text: '操作系统原理'),
        ]);

        final results = index.search('量子计算');
        expect(results, isEmpty);
      });

      test('handles Chinese bigram matching', () {
        final index = TfidfIndex();
        index.build([
          (id: 1, text: '进程和线程是操作系统的基本概念'),
          (id: 2, text: '数据库索引加速查询'),
        ]);

        final results = index.search('操作系统');
        expect(results, isNotEmpty);
        expect(results.first.id, 1);
      });
    });
  });
}
