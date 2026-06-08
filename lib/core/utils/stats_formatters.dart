/// 统计数据格式化工具
///
/// 提供统一的中文格式化方法，用于所有统计页面。
/// 所有函数均为顶层函数，直接调用即可。

/// 格式化分钟为中文时长
///
/// - 0 → "0分钟"
/// - 45 → "45分钟"
/// - 90 → "1小时30分钟"
/// - 120 → "2小时"
/// - 150 → "2小时30分钟"
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0分钟';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m分钟';
  if (m == 0) return '$h小时';
  return '$h小时${m}分钟';
}

/// 格式化分钟为短格式
///
/// - 0 → "0m"
/// - 45 → "45m"
/// - 90 → "1.5h"
/// - 120 → "2.0h"
/// - 150 → "2.5h"
String formatMinutesShort(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final hours = minutes / 60;
  if (hours == hours.roundToDouble()) return '${hours.toInt()}.0h';
  return '${hours.toStringAsFixed(1)}h';
}

/// 格式化经验值
///
/// - 0 → "0"
/// - 340 → "340"
/// - 1280 → "1,280"
/// - 12800 → "12.8k"
String formatExp(int exp) {
  if (exp <= 0) return '0';
  if (exp >= 10000) return '${(exp / 1000).toStringAsFixed(1)}k';
  // 千分位分隔
  final str = exp.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

/// 格式化数量 + 单位
///
/// - (5, '篇') → "5篇"
/// - (0, '次') → "0次"
/// - (12, '分钟') → "12分钟"
String formatCount(int count, String unit) {
  return '$count$unit';
}

/// 格式化百分比
///
/// - 0.7 → "70%"
/// - 0.756 → "76%"
/// - 1.0 → "100%"
String formatPercent(double ratio) {
  return '${(ratio * 100).round()}%';
}

/// 格式化日期为中文短格式
///
/// - DateTime(2026, 6, 8) → "6月8日"
String formatDateChinese(DateTime date) {
  return '${date.month}月${date.day}日';
}

/// 格式化星期为中文
///
/// - DateTime.weekday 1 → "周一"
/// - DateTime.weekday 7 → "周日"
String formatWeekday(DateTime date) {
  const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return weekdays[date.weekday - 1];
}

/// 格式化完整日期（日期 + 星期）
///
/// - "6月8日 · 周日"
String formatFullDate(DateTime date) {
  return '${formatDateChinese(date)} · ${formatWeekday(date)}';
}

/// 格式化周范围
///
/// - "6/2 — 6/8"
String formatWeekRange(DateTime start, DateTime end) {
  return '${start.month}/${start.day} — ${end.month}/${end.day}';
}

/// 格式化月份为中文
///
/// - "2026年6月"
String formatMonth(DateTime date) {
  return '${date.year}年${date.month}月';
}

/// 格式化年份为中文
///
/// - "2026年度"
String formatYear(int year) {
  return '${year}年度';
}
