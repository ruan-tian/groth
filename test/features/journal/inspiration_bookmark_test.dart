import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/features/journal/models/inspiration_catalog.dart';
import 'package:growth_os/features/journal/pages/inspiration_bookmark_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inspiration catalog parses local text assets', (tester) async {
    final catalog = await InspirationCatalog.load();

    expect(catalog.themes.length, greaterThanOrEqualTo(17));
    expect(catalog.entries.length, greaterThan(800));
    expect(
      catalog.themes.map((theme) => theme.name),
      containsAll(['自我接纳', '行动与坚持', '励志向上', '山水之乐', '警世']),
    );

    for (final theme in catalog.themes) {
      expect(theme.entries, isNotEmpty, reason: theme.name);
      expect(theme.posterPath, startsWith('assets/images/inspiration/'));
      final data = await rootBundle.load(theme.posterPath);
      expect(data.lengthInBytes, greaterThan(0), reason: theme.posterPath);
    }
  });

  testWidgets('inspiration page renders hero, actions, and poster wall', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: InspirationBookmarkPage()));
    for (var i = 0; i < 20 && find.byType(ListView).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('灵感书签'), findsWidgets);
    expect(find.text('灵感加载失败'), findsNothing);
    expect(find.byType(ListView), findsWidgets);

    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('换一句'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    expect(find.text('换个主题'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('主题海报'), findsOneWidget);
  });
}
