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
  test('axis labels are sampled evenly instead of by modulo', () {
    expect(
      ChartValueLabelPolicy.visibleAxisIndexes(12, 2),
      equals({0, 2, 4, 7, 9, 11}),
    );
    expect(
      ChartValueLabelPolicy.visibleAxisIndexes(31, 7),
      equals({0, 8, 15, 23, 30}),
    );
  });

  testWidgets('range selector uses shared layout and changes value', (
    tester,
  ) async {
    var selected = 7;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return GrowthChartRangeSelector<int>(
              color: Colors.teal,
              selected: selected,
              options: const [
                GrowthChartRangeOption(value: 7, label: '周'),
                GrowthChartRangeOption(value: 30, label: '月'),
                GrowthChartRangeOption(value: 365, label: '年'),
              ],
              onChanged: (value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );

    expect(find.text('周'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('年'), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    expect(selected, 30);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('animated bar chart accepts duration axis formatter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    await tester.pumpWidget(
      _wrap(
        GrowthAnimatedBarChart(
          points: const [
            GrowthChartPoint(label: '周一', value: 30),
            GrowthChartPoint(label: '周二', value: 60),
            GrowthChartPoint(label: '周三', value: 90),
          ],
          color: Colors.teal,
          valueFormatter: (value) => '${value.round()}m',
          axisFormatter: (value) => '时长${value.round()}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('时长'), findsWidgets);
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

  testWidgets('multi line chart uses primary axis formatter', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    await tester.pumpWidget(
      _wrap(
        GrowthMultiLineChart(
          color: Colors.indigo,
          axisFormatter: (value) => '${value.toStringAsFixed(1)}h',
          series: [
            GrowthChartSeries(
              name: '睡眠时长',
              unit: 'h',
              color: Colors.indigo,
              points: const [
                GrowthChartPoint(label: '1/1', value: 6.5),
                GrowthChartPoint(label: '1/2', value: 8),
              ],
              valueFormatter: (value) => '${value.toStringAsFixed(1)}h',
            ),
            GrowthChartSeries(
              name: '睡眠质量',
              unit: '分',
              color: Colors.pink,
              points: const [
                GrowthChartPoint(label: '1/1', value: 3),
                GrowthChartPoint(label: '1/2', value: 5),
              ],
              valueFormatter: (value) => '${value.toStringAsFixed(1)}分',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('h'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi line chart keeps month axis labels unique', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    final months = List.generate(
      12,
      (index) => GrowthChartPoint(label: '${index + 1}月', value: index + 1),
    );
    await tester.pumpWidget(
      _wrap(
        GrowthMultiLineChart(
          color: Colors.teal,
          series: [
            GrowthChartSeries(
              name: 'A',
              unit: 'min',
              color: Colors.teal,
              points: months,
              valueFormatter: (value) => value.round().toString(),
            ),
            GrowthChartSeries(
              name: 'B',
              unit: 'kcal',
              color: Colors.orange,
              points: months
                  .map(
                    (point) => GrowthChartPoint(
                      label: point.label,
                      value: point.value * 2,
                    ),
                  )
                  .toList(),
              valueFormatter: (value) => value.round().toString(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1月'), findsOneWidget);
    expect(find.text('5月'), findsOneWidget);
    expect(find.text('12月'), findsOneWidget);
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
    expect(find.text('1月'), findsWidgets);
    expect(find.text('6月'), findsWidgets);
    expect(find.text('12月'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
