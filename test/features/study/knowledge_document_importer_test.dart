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
        expect(result.displayError, contains('文件格式暂时不支持'));

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
        expect(result.content, '# Title\n\nSome markdown content.');
        expect(result.type, 'markdown');

        await file.delete();
      });

      test('extracts image text through OCR callback', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/scan_$ts.png');
        await file.writeAsBytes([1, 2, 3, 4]);

        final result = await importer.extractFromFile(
          file,
          ocrCallback: (bytes, mimeType) async {
            expect(bytes, [1, 2, 3, 4]);
            expect(mimeType, 'image/png');
            return '行政处罚追诉时效通常从违法行为发生之日起计算。';
          },
        );

        expect(result.isSuccess, isTrue);
        expect(result.type, 'image_ocr');
        expect(result.content, contains('行政处罚追诉时效'));

        await file.delete();
      });

      test(
        'image import without OCR callback gives actionable error',
        () async {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final file = File('${Directory.systemTemp.path}/scan_$ts.webp');
          await file.writeAsBytes([1, 2, 3, 4]);

          final result = await importer.extractFromFile(file);

          expect(result.isSuccess, isFalse);
          expect(result.displayError, contains('图片导入需要先配置 AI'));
          expect(result.displayError, contains('粘贴导入'));

          await file.delete();
        },
      );

      test('OCR callback errors are converted to friendly message', () async {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final file = File('${Directory.systemTemp.path}/broken_$ts.jpg');
        await file.writeAsBytes([9, 8, 7]);

        final result = await importer.extractFromFile(
          file,
          ocrCallback: (_, _) async {
            throw const FormatException('Unexpected end of input');
          },
        );

        expect(result.isSuccess, isFalse);
        expect(result.displayError, isNot(contains('FormatException')));
        expect(result.displayError, contains('图片文字识别失败'));

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

      test('displayError hides internal parser errors for files', () {
        const result = DocumentImportResult(
          title: 'Broken',
          content: '',
          type: 'pdf_text',
          errorMessage:
              'FormatException: Unexpected end of input (at line 342)',
        );

        expect(result.displayError, isNot(contains('FormatException')));
        expect(result.displayError, isNot(contains('Unexpected end')));
        expect(result.displayError, contains('复制文字粘贴'));
      });

      test('displayError hides internal network errors for web import', () {
        const result = DocumentImportResult(
          title: 'Web',
          content: '',
          type: 'web',
          errorMessage: 'SocketException: Failed host lookup',
        );

        expect(result.displayError, isNot(contains('SocketException')));
        expect(result.displayError, contains('网页暂时无法读取'));
      });

      test('displayError hides internal OCR errors for images', () {
        const result = DocumentImportResult(
          title: 'Image',
          content: '',
          type: 'image_ocr',
          errorMessage: 'Exception: model returned stack trace',
        );

        expect(result.displayError, isNot(contains('Exception')));
        expect(result.displayError, contains('图片文字识别失败'));
      });
    });
  });
}
