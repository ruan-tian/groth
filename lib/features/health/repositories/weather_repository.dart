import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class WeatherRepository {
  WeatherRepository(this._db);
  final AppDatabase _db;

  /// 插入或更新今日天气
  Future<void> upsertWeather(DailyWeatherTableCompanion weather) async {
    final dateStr = weather.date.value;
    final existing = await (_db.select(
      _db.dailyWeatherTable,
    )..where((t) => t.date.equals(dateStr))).getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.dailyWeatherTable,
      )..where((t) => t.date.equals(dateStr))).write(weather);
    } else {
      await _db.into(_db.dailyWeatherTable).insert(weather);
    }
  }

  /// 获取今日天气
  Future<DailyWeather?> getTodayWeather() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return (_db.select(_db.dailyWeatherTable)
          ..where((t) => t.date.equals(dateStr))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取指定日期天气
  Future<DailyWeather?> getWeatherByDate(String dateKey) async {
    return (_db.select(_db.dailyWeatherTable)
          ..where((t) => t.date.equals(dateKey))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取最近 N 天天气
  Future<List<DailyWeather>> getRecentWeather({int days = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    return (_db.select(_db.dailyWeatherTable)
          ..where((t) => t.date.isBiggerOrEqualValue(startStr))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
}
