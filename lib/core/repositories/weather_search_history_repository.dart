import 'package:drift/drift.dart';
import '../database/app_database.dart';

class WeatherSearchHistoryRepository {
  WeatherSearchHistoryRepository(this._db);
  final AppDatabase _db;

  /// 添加搜索历史
  Future<void> addHistory({
    required String cityName,
    String? country,
    String? admin1,
    required double latitude,
    required double longitude,
  }) async {
    // 检查是否已存在
    final existing = await (_db.select(_db.weatherSearchHistoryTable)
          ..where((t) => t.cityName.equals(cityName))
          ..limit(1))
        .getSingleOrNull();
    
    if (existing != null) {
      // 更新时间
      await (_db.update(_db.weatherSearchHistoryTable)
            ..where((t) => t.cityName.equals(cityName)))
          .write(WeatherSearchHistoryTableCompanion(
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    } else {
      // 插入新记录
      await _db.into(_db.weatherSearchHistoryTable).insert(
        WeatherSearchHistoryTableCompanion(
          cityName: Value(cityName),
          country: Value(country),
          admin1: Value(admin1),
          latitude: Value(latitude),
          longitude: Value(longitude),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  /// 获取搜索历史（最多20条）
  Future<List<WeatherSearchHistory>> getHistory({int limit = 20}) async {
    return (_db.select(_db.weatherSearchHistoryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 删除搜索历史
  Future<void> deleteHistory(int id) async {
    await (_db.delete(_db.weatherSearchHistoryTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// 清空搜索历史
  Future<void> clearHistory() async {
    await _db.delete(_db.weatherSearchHistoryTable).go();
  }
}
