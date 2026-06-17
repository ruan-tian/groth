import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 系统设置仓库
///
/// 封装 AppSettings（KV 存储）的读写操作。
/// key 为主键，使用 insertOnConflictUpdate 实现 upsert 语义。
class SettingRepository {
  SettingRepository(this._db);

  final AppDatabase _db;

  /// 根据 key 获取设置值，不存在时返回 null。
  Future<String?> getSetting(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// 插入或更新一条设置（upsert）。
  ///
  /// key 已存在时更新 value 和 updatedAt，否则插入新行。
  Future<void> setSetting(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            key: Value(key),
            value: Value(value),
            updatedAt: Value(now),
          ),
        );
  }

  /// 删除指定 key 的设置。
  Future<void> deleteSetting(String key) async {
    await (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();
  }

  /// 获取全部设置列表。
  Future<List<AppSetting>> getAllSettings() {
    return _db.select(_db.appSettings).get();
  }
}
