import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growth_os/features/health/models/drink_recommendation.dart';
import 'package:growth_os/features/health/pages/drink_recommendation_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('drink catalog has stable local data and category filters', () {
    expect(DrinkCatalog.drinks, hasLength(310));
    expect(
      DrinkCatalog.categories,
      containsAll(['健康区', '咖啡', '新茶饮', '即饮茶', '气泡']),
    );
    expect(DrinkCatalog.byCategory('健康区'), hasLength(4));
    expect(DrinkCatalog.byCategory('咖啡'), hasLength(98));
    expect(DrinkCatalog.byCategory('新茶饮'), hasLength(145));
    expect(DrinkCatalog.byCategory('全部'), hasLength(310));
    expect(
      DrinkCatalog.byCategory('健康区').map((drink) => drink.name),
      containsAll(['白开水多喝', '矿泉水', '无糖可乐', '苏打水']),
    );
    expect(
      DrinkCatalog.todayRecommendation(DateTime(2026, 6, 12)),
      isA<DrinkRecommendation>(),
    );

    for (final drink in DrinkCatalog.drinks) {
      expect(drink.imagePath, startsWith('assets/images/drinks/'));
      expect(drink.imagePath, endsWith('.webp'));
      expect(drink.tags, isNotEmpty, reason: drink.id);
    }
  });

  testWidgets('drink assets are bundled and loadable', (tester) async {
    for (final drink in DrinkCatalog.drinks) {
      final data = await rootBundle.load(drink.imagePath);
      expect(data.lengthInBytes, greaterThan(0), reason: drink.imagePath);
    }
  });

  testWidgets('recommendation page renders actions and category filtering', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DrinkRecommendationPage()));
    await tester.pumpAndSettle();

    expect(find.text('今天想喝点什么'), findsOneWidget);
    expect(find.text('今日推荐'), findsOneWidget);
    expect(find.text('换一杯'), findsOneWidget);
    expect(find.text('就喝这个'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('咖啡').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(find.text('全部饮品墙'), findsOneWidget);
    expect(find.text('98 款'), findsOneWidget);
    expect(find.text('瑞幸咖啡'), findsWidgets);
  });
}
