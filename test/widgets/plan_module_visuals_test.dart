import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/features/plan/utils/plan_module_assets.dart';
import 'package:growth_os/features/plan/widgets/plan_module_visuals.dart';

void main() {
  testWidgets('premium action cards render module copy and buttons', (
    tester,
  ) async {
    for (final module in PlanModuleType.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 390,
                child: PlanModuleActionImageCard(
                  module: module,
                  color: Colors.orange,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(PlanModuleAssets.actionTitle(module)), findsOneWidget);
      expect(
        find.text(PlanModuleAssets.actionButtonLabel(module)),
        findsOneWidget,
      );
    }
  });

  testWidgets('premium record and weekly cards render stable labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PlanModuleRecordEntryCard(
                color: Colors.orange,
                icon: Icons.edit_note_rounded,
                title: '记录训练',
                subtitle: '手动添加训练记录',
                buttonLabel: '添加',
                onTap: () {},
              ),
              PlanModuleWeeklyCard(
                color: Colors.orange,
                icon: Icons.calendar_month_rounded,
                title: '本周训练',
                count: 2,
                goal: 5,
                unit: '次',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('记录训练'), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);
    expect(find.text('本周训练'), findsOneWidget);
    expect(find.text('2/5 次'), findsOneWidget);
  });
}
