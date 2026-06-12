import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:growth_os/features/fitness/pages/add_fitness_record_page.dart';
import 'package:growth_os/features/health/pages/add_diet_record_page.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(child: MaterialApp(home: child));
  }

  testWidgets('AddFitnessRecordPage renders quick record shell', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const AddFitnessRecordPage()));

    expect(find.text('添加运动记录'), findsOneWidget);
    expect(find.text('运动类型'), findsOneWidget);
    expect(find.text('训练信息'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('AddDietRecordPage renders quick record shell', (tester) async {
    await tester.pumpWidget(wrap(const AddDietRecordPage()));

    expect(find.text('记录饮食'), findsOneWidget);
    expect(find.text('餐次'), findsOneWidget);
    expect(find.text('吃了什么'), findsOneWidget);
    expect(find.text('营养判断'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });
}
