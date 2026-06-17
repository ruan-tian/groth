import '../constants/date_constants.dart';

/// 日期工具函数
class GrowthDateUtils {
  GrowthDateUtils._();

  /// 格式化日期为 YYYY-MM-DD 字符串
  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 格式化日期为 MM月DD日 周X
  static String formatDateChinese(DateTime date) {
    return '${date.month}月${date.day}日 ${DateConstants.weekdayName(date.weekday)}';
  }

  /// 格式化日期为 YYYY年MM月DD日 周X
  static String formatDateChineseFull(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${DateConstants.weekdayName(date.weekday)}';
  }

  /// 格式化时间为 HH:MM
  static String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 格式化时长为 Xh Xm 或 Xm
  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }

  /// 格式化时长为 HH:MM:SS
  static String formatDurationHMS(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 格式化日期为 MM/DD HH:MM
  static String formatDateTimeShort(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
