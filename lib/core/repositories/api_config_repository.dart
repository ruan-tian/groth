import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ApiConfigRepository {
  ApiConfigRepository(this._db);
  final AppDatabase _db;

  /// 获取指定 provider 的配置
  Future<ApiConfig?> getConfig(String provider) async {
    return (_db.select(_db.apiConfigs)
          ..where((t) => t.provider.equals(provider))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取当前激活的天气 API 配置
  Future<ApiConfig?> getActiveWeatherConfig() async {
    return (_db.select(_db.apiConfigs)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 保存或更新配置
  Future<void> upsertConfig({
    required String provider,
    String? apiKey,
    String? baseUrl,
    required bool isActive,
  }) async {
    final existing = await getConfig(provider);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing != null) {
      await (_db.update(_db.apiConfigs)
            ..where((t) => t.provider.equals(provider)))
          .write(ApiConfigsCompanion(
        apiKey: Value(apiKey),
        baseUrl: Value(baseUrl),
        isActive: Value(isActive),
        updatedAt: Value(now),
      ));
    } else {
      await _db.into(_db.apiConfigs).insert(ApiConfigsCompanion(
            provider: Value(provider),
            apiKey: Value(apiKey),
            baseUrl: Value(baseUrl),
            isActive: Value(isActive),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
    }
  }

  /// 获取所有配置
  Future<List<ApiConfig>> getAllConfigs() async {
    return (_db.select(_db.apiConfigs)
          ..orderBy([(t) => OrderingTerm.asc(t.provider)]))
        .get();
  }
}
