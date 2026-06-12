import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/shared/widgets/common/common_widgets.dart';

void main() {
  testWidgets('GrowthPressable keeps tap behavior with animations enabled', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GrowthPressable(
            semanticLabel: 'tap target',
            onTap: () => taps++,
            child: const SizedBox(width: 80, height: 48, child: Text('Tap')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets(
    'GrowthPressable keeps tap behavior when animations are disabled',
    (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: GrowthPressable(
                semanticLabel: 'tap target',
                onTap: () => taps++,
                child: const SizedBox(
                  width: 80,
                  height: 48,
                  child: Text('Tap'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    },
  );
}
