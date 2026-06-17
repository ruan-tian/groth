/// 日期相关常量
class DateConstants {
  DateConstants._();

  /// 中文星期数组（周一到周日）
  static const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 获取星期名称（1=周一, 7=周日）
  static String weekdayName(int weekday) => weekdays[weekday - 1];
}
