import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/shared/widgets/common/common_widgets.dart';

Widget _wrap(Widget child, {double width = 390}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('animated bar chart handles narrow width and zero data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(
      _wrap(
        GrowthAnimatedBarChart(
          points: const [
            GrowthChartPoint(label: '1/1', value: 0),
            GrowthChartPoint(label: '1/2', value: 0),
            GrowthChartPoint(label: '1/3', value: 0),
          ],
          color: Colors.teal,
          valueFormatter: (value) => value.round().toString(),
        ),
        width: 360,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('multi line chart handles extreme values', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    await tester.pumpWidget(
      _wrap(
        GrowthMultiLineChart(
          color: Colors.orange,
          series: [
            GrowthChartSeries(
              name: 'A',
              unit: 'min',
              color: Colors.orange,
              points: const [
                GrowthChartPoint(label: '1/1', value: 1),
                GrowthChartPoint(label: '1/2', value: 2000),
                GrowthChartPoint(label: '1/3', value: 18),
              ],
              valueFormatter: (value) => value.round().toString(),
            ),
            GrowthChartSeries(
              name: 'B',
              unit: 'ml',
              color: Colors.blue,
              points: const [
                GrowthChartPoint(label: '1/1', value: 500),
                GrowthChartPoint(label: '1/2', value: 0),
                GrowthChartPoint(label: '1/3', value: 1500),
              ],
              valueFormatter: (value) => value.round().toString(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('heatmap calendar renders a scrollable yearly grid', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    await tester.pumpWidget(
      _wrap(
        GrowthHeatmapCalendar(
          data: {
            DateTime(2026): 1,
            DateTime(2026, 6, 24): 8,
            DateTime(2026, 12, 31): 4,
          },
          startDate: DateTime(2026),
          endDate: DateTime(2026, 12, 31),
          baseColor: const Color(0xFFF6D8E8),
          maxColor: const Color(0xFFE84F8A),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
