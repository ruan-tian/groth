/// Shared data processor for all chart types.
///
/// Provides consistent data merging and aggregation across charts.
class ChartDataProcessor {
  const ChartDataProcessor._();

  /// Merge two data sources by date.
  ///
  /// Returns a list of maps with merged data, sorted by date ascending.
  static List<Map<String, dynamic>> mergeByDate({
    required List<Map> primary,
    required List<Map>? secondary,
    required String primaryKey,
    required String secondaryKey,
  }) {
    final map = <String, Map<String, dynamic>>{};
    for (final item in primary) {
      final date = normalizeDate(item['date'] as String? ?? '');
      if (date.isEmpty) continue;
      map[date] = {'date': date, primaryKey: item[primaryKey], secondaryKey: null};
    }
    if (secondary != null) {
      for (final item in secondary) {
        final date = normalizeDate(item['date'] as String? ?? '');
        if (date.isEmpty) continue;
        map.putIfAbsent(date, () => {'date': date, primaryKey: null, secondaryKey: null});
        map[date]![secondaryKey] = item[secondaryKey];
      }
    }
    return map.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Aggregate daily data into weekly buckets.
  ///
  /// Returns a list of weekly aggregates with 'date', 'endDate', and aggregated values.
  static List<Map<String, dynamic>> aggregateByWeek(
    List<Map<String, dynamic>> daily, {
    required String valueKey,
  }) {
    if (daily.isEmpty) return [];
    final weeks = <Map<String, dynamic>>[];
    for (var i = 0; i < daily.length; i += 7) {
      final chunk = daily.sublist(i, (i + 7).clamp(0, daily.length));
      final values = chunk
          .map((e) => (e[valueKey] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      weeks.add({
        'date': chunk.first['date'],
        'endDate': chunk.last['date'],
        valueKey: values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length,
      });
    }
    return weeks;
  }

  /// Aggregate daily data into monthly buckets.
  ///
  /// Returns a list of monthly aggregates with 'date' and aggregated values.
  static List<Map<String, dynamic>> aggregateByMonth(
    List<Map<String, dynamic>> daily, {
    required String valueKey,
  }) {
    if (daily.isEmpty) return [];
    final monthMap = <String, List<Map<String, dynamic>>>{};
    for (final item in daily) {
      final date = item['date'] as String? ?? '';
      if (date.length < 7) continue;
      monthMap.putIfAbsent(date.substring(0, 7), () => []).add(item);
    }
    final keys = monthMap.keys.toList()..sort();
    return keys.map((key) {
      final chunk = monthMap[key]!;
      final values = chunk
          .map((e) => (e[valueKey] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      return {
        'date': key,
        valueKey: values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length,
      };
    }).toList();
  }

  /// Normalize date string to yyyy-MM-dd format.
  static String normalizeDate(String date) {
    if (date.isEmpty) return '';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  /// Calculate average of a list of doubles.
  static double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
