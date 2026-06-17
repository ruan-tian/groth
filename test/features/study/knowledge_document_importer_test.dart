import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/study/utils/knowledge_document_importer.dart';

void main() {
  group('KnowledgeDocumentImporter', () {
    late KnowledgeDocumentImporter importer;

    setUp(() {
      importer = KnowledgeDocumentImporter();
    });

    group('extractFromFile', () {
      test('rejects unsupported file extension', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/test_$ts.xyz');
        await file.writeAsString('some content');

        final result = await importer.extractFromFile(file);
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('不支持的文件格式'));

        await file.delete();
      });

      test('extracts plain text from .txt file', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/notes_$ts.txt');
        await file.writeAsString('Hello World\nThis is a test note.');

        final result = await importer.extractFromFile(file);
        expect(result.isSuccess, isTrue);
        expect(result.content, 'Hello World\nThis is a test note.');
        expect(result.type, 'text');

        await file.delete();
      });

      test('extracts markdown from .md file', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/notes_$ts.md');
        await file.writeAsString('# Title\n\nSome markdown content.');

        final result = await importer.extractFromFile(file);
        expect(result.isSuccess, isTrue);
        expect(result.content, contains('Title'));
        expect(result.type, 'markdown');

        await file.delete();
      });

      test('handles empty .txt file', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/empty_$ts.txt');
        await file.writeAsString('');

        final result = await importer.extractFromFile(file);
        expect(result.isSuccess, isFalse);

        await file.delete();
      });

      test('preserves source path for local files', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/src_$ts.txt');
        await file.writeAsString('content with source');

        final result = await importer.extractFromFile(file);
        expect(result.isSuccess, isTrue);
        expect(result.sourcePath, file.path);

        await file.delete();
      });
    });

    group('URL import', () {
      test('empty URL returns error without network call', () async {
        final result = await importer.extractFromUrl('');
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('请输入有效的网页 URL'));
        expect(result.sourcePath, isNull);
      });

      test('whitespace-only URL returns error', () async {
        final result = await importer.extractFromUrl('   ');
        expect(result.isSuccess, isFalse);
      });
    });

    group('DocumentImportResult', () {
      test('isSuccess requires non-empty content and no error', () {
        const success = DocumentImportResult(
          title: 'Test',
          content: 'Some content',
          type: 'text',
        );
        expect(success.isSuccess, isTrue);

        const emptyContent = DocumentImportResult(
          title: 'Test',
          content: '',
          type: 'text',
        );
        expect(emptyContent.isSuccess, isFalse);

        const withError = DocumentImportResult(
          title: 'Test',
          content: 'Some content',
          type: 'text',
          errorMessage: 'Something went wrong',
        );
        expect(withError.isSuccess, isFalse);
      });

      test('displayError returns null on success', () {
        const result = DocumentImportResult(
          title: 'Test',
          content: 'Content',
          type: 'text',
        );
        expect(result.displayError, isNull);
      });

      test('displayError returns error message when set', () {
        const result = DocumentImportResult(
          title: 'Test',
          content: '',
          type: 'text',
          errorMessage: 'File not found',
        );
        expect(result.displayError, 'File not found');
      });
    });
  });
}
