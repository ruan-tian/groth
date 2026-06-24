import 'package:flutter/material.dart';

import '../../../shared/widgets/common/common_widgets.dart';

class SleepCombinedChart extends StatefulWidget {
  const SleepCombinedChart({
    super.key,
    required this.durationData,
    required this.qualityData,
    required this.durationColor,
    required this.qualityColor,
    required this.goalHours,
    required this.selectedRange,
  });

  final List<Map> durationData;
  final List<Map> qualityData;
  final Color durationColor;
  final Color qualityColor;
  final int goalHours;
  final int selectedRange;

  @override
  State<SleepCombinedChart> createState() => _SleepCombinedChartState();
}

class _SleepCombinedChartState extends State<SleepCombinedChart> {
  List<Map<String, dynamic>>? _cachedProcessedData;

  @override
  void didUpdateWidget(SleepCombinedChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.durationData, oldWidget.durationData) ||
        !identical(widget.qualityData, oldWidget.qualityData) ||
        widget.selectedRange != oldWidget.selectedRange) {
      _cachedProcessedData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _cachedProcessedData ??= _processData();
    final durationPoints = <GrowthChartPoint>[];
    final qualityPoints = <GrowthChartPoint>[];

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final label = _mainLabel(item, i);
      final subLabel = _subLabel(item);
      final duration = (item['duration'] as num?)?.toDouble() ?? 0;
      final quality = (item['quality'] as num?)?.toDouble() ?? 0;

      durationPoints.add(
        GrowthChartPoint(
          label: label,
          subLabel: subLabel,
          value: duration / 60,
          rawLabel: _formatDurationValue(duration),
        ),
      );
      qualityPoints.add(
        GrowthChartPoint(
          label: label,
          subLabel: subLabel,
          value: quality,
          rawLabel: quality > 0 ? _formatQualityValue(quality) : '--',
        ),
      );
    }

    return GrowthSleepComboChart(
      key: ValueKey(
        'sleep_${widget.selectedRange}_${durationPoints.length}_${data.hashCode}',
      ),
      durationSeries: GrowthChartSeries(
        name: '睡眠',
        unit: 'h',
        color: widget.durationColor,
        points: durationPoints,
        valueFormatter: (value) => '${_trim(value)}h',
      ),
      qualitySeries: GrowthChartSeries(
        name: '质量',
        unit: '分',
        color: widget.qualityColor,
        points: qualityPoints,
        valueFormatter: _formatQualityValue,
      ),
      durationColor: widget.durationColor,
      qualityColor: widget.qualityColor,
      goalHours: widget.goalHours,
      height: 244,
    );
  }

  String _formatDurationValue(double minutes) {
    if (minutes < 60) return '${minutes.round()}m';
    final hours = minutes / 60;
    return '${_trim(hours)}h';
  }

  String _formatQualityValue(double quality) {
    if (quality <= 0) return '--';
    return '${quality.toStringAsFixed(1)}分';
  }

  List<Map<String, dynamic>> _mergeData() {
    final map = <String, Map<String, dynamic>>{};
    for (final d in widget.durationData) {
      final date = d['date'] as String? ?? '';
      map[date] = {'date': date, 'duration': d['duration'], 'quality': null};
    }
    for (final q in widget.qualityData) {
      final date = q['date'] as String? ?? '';
      if (map.containsKey(date)) {
        map[date]!['quality'] = q['quality'];
      } else {
        map[date] = {'date': date, 'duration': null, 'quality': q['quality']};
      }
    }
    return map.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  List<Map<String, dynamic>> _aggregateByWeek(
    List<Map<String, dynamic>> daily,
  ) {
    if (daily.isEmpty) return [];
    final weeks = <Map<String, dynamic>>[];
    for (var i = 0; i < daily.length; i += 7) {
      final chunk = daily.sublist(i, (i + 7).clamp(0, daily.length));
      final durValues = chunk
          .map((e) => (e['duration'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final qualValues = chunk
          .map((e) => (e['quality'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      weeks.add({
        'date': chunk.first['date'],
        'endDate': chunk.last['date'],
        'duration': _average(durValues),
        'quality': qualValues.isEmpty ? null : _average(qualValues),
      });
    }
    return weeks;
  }

  List<Map<String, dynamic>> _aggregateByMonth(
    List<Map<String, dynamic>> daily,
  ) {
    final now = DateTime.now();
    final year = now.year;
    final monthMap = <String, List<Map<String, dynamic>>>{};
    for (final item in daily) {
      final date = item['date'] as String? ?? '';
      final parsed = DateTime.tryParse(date);
      if (parsed == null || parsed.year != year) continue;
      monthMap.putIfAbsent(date.substring(0, 7), () => []).add(item);
    }
    return List.generate(12, (index) {
      final month = index + 1;
      final key = '$year-${month.toString().padLeft(2, '0')}';
      final chunk = monthMap[key] ?? const <Map<String, dynamic>>[];
      final durValues = chunk
          .map((e) => (e['duration'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final qualValues = chunk
          .map((e) => (e['quality'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      return {
        'date': key,
        'duration': _average(durValues),
        'quality': qualValues.isEmpty ? null : _average(qualValues),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _processData() {
    final merged = _mergeData();
    if (widget.selectedRange == 30) return _aggregateByWeek(merged);
    if (widget.selectedRange == 365) return _aggregateByMonth(merged);
    return merged;
  }

  String _mainLabel(Map<String, dynamic> item, int index) {
    if (widget.selectedRange == 30) return '第${index + 1}周';
    final date = item['date'] as String? ?? '';
    if (widget.selectedRange == 365) {
      final month = date.length >= 7
          ? int.tryParse(date.substring(5, 7))
          : null;
      return month == null ? date : '$month月';
    }
    final parsed = DateTime.tryParse(date);
    return parsed == null ? date : '${parsed.month}/${parsed.day}';
  }

  String _subLabel(Map<String, dynamic> item) {
    if (widget.selectedRange != 30) return '';
    final start = _dateShort(item['date'] as String? ?? '');
    final end = _dateShort(item['endDate'] as String? ?? '');
    if (start.isEmpty || end.isEmpty) return '';
    return '$start-$end';
  }

  static String _dateShort(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day}';
  }

  static double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static String _trim(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
  }
}
