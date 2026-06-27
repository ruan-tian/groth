/// Shared label builder for all chart types.
///
/// Provides consistent label generation across study, fitness, diet, and sleep charts.
class ChartLabelBuilder {
  const ChartLabelBuilder._();

  static const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _weekNames = ['一', '二', '三', '四', '五', '六'];

  /// Build main label for X-axis.
  ///
  /// [range] can be 'week' (7), 'month' (30), or 'year' (365)
  /// [index] is the position in the data list
  /// [dateStr] is the date string (yyyy-MM-dd or similar)
  static String buildLabel({
    required int range,
    required int index,
    required String? dateStr,
  }) {
    if (range == 30) {
      // Month view: show week number
      final name = index >= 0 && index < _weekNames.length
          ? _weekNames[index]
          : '${index + 1}';
      return '第$name周';
    }
    if (range == 365) {
      // Year view: show month
      if (dateStr != null && dateStr.length >= 7) {
        final month = int.tryParse(dateStr.substring(5, 7));
        if (month != null) return '$month月';
      }
      return dateStr ?? '';
    }
    // Week view: show weekday name
    final parsed = DateTime.tryParse(dateStr ?? '');
    if (parsed != null) {
      return _weekdayNames[parsed.weekday - 1];
    }
    return dateStr ?? '';
  }

  /// Build sub-label for X-axis.
  ///
  /// [range] can be 'week' (7), 'month' (30), or 'year' (365)
  /// [dateStr] is the start date string
  /// [endDateStr] is the end date string (for month view)
  static String buildSubLabel({
    required int range,
    required String? dateStr,
    String? endDateStr,
  }) {
    if (range == 30) {
      // Month view: show date range
      final start = _formatDateShort(dateStr);
      final end = _formatDateShort(endDateStr);
      if (start.isEmpty || end.isEmpty) return '';
      return '$start-$end';
    }
    if (range == 7) {
      // Week view: show M/d
      return _formatDateShort(dateStr);
    }
    // Year view: no sub-label
    return '';
  }

  /// Format date as M/d
  static String _formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day}';
  }
}
