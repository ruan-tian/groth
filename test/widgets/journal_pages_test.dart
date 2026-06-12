import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    expect(find.byType(WriteJournalPage), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('QuillEditorPage renders system style editor controls', (
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
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('引用'), findsOneWidget);
    expect(find.text('工具'), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
  });

  testWidgets(
    'QuillEditorPage compact mode separates list panel from paragraph',
    (tester) async {
      await setViewport(tester, 390, 844);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          home: QuillEditorPage(
            initialTitle: '今日记录',
            initialPlainText: 'hello',
            initialDeltaJson: null,
            onSave: (_, _, _, _, _) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('今日记录'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);

      await tester.tap(find.text('工具'));
      await tester.pumpAndSettle();

      expect(find.text('字体'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('无序'), findsOneWidget);
      expect(find.text('有序'), findsOneWidget);
      expect(find.text('H1'), findsNothing);
    },
  );
}
