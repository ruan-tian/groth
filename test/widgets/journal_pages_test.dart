import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/journal/pages/quill_editor_page.dart';
import 'package:growth_os/features/journal/pages/write_journal_page.dart';
import 'package:growth_os/features/journal/providers/journal_stats_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setViewport(
    WidgetTester tester,
    double width,
    double height,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('WriteJournalPage renders the soft paper writing desk', (
    tester,
  ) async {
    await setViewport(tester, 390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalStreakProvider.overrideWith((ref) async => 1)],
        child: const MaterialApp(home: WriteJournalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('写日记'), findsOneWidget);
    expect(find.text('今天的心情是？'), findsOneWidget);
    expect(find.text('灵感提示'), findsOneWidget);
    expect(find.text('保存日记'), findsOneWidget);
  });

  testWidgets('QuillEditorPage renders immersive editor controls', (
    tester,
  ) async {
    await setViewport(tester, 390, 844);
    await tester.pumpWidget(
      MaterialApp(
        home: QuillEditorPage(
          initialTitle: '',
          initialPlainText: '',
          initialDeltaJson: null,
          onSave: (_, _, _, _, _) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('完成'), findsOneWidget);
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('图片'), findsOneWidget);
    expect(find.text('任务'), findsOneWidget);
    expect(find.text('列表'), findsOneWidget);
    expect(find.text('引用'), findsOneWidget);
    expect(find.text('字体'), findsOneWidget);
    expect(find.text('更多'), findsOneWidget);
  });
}
