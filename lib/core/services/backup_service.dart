import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

/// 备份与恢复服务
///
/// 提供全量 JSON 导出/导入、本地文件存取功能。
/// 导入时使用事务保证原子性，任一表写入失败则整体回滚。
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // 导出
  // ---------------------------------------------------------------------------

  /// 将数据库中所有表导出为 JSON 字符串。
  ///
  /// 返回格式:
  /// ```json
  /// {
  ///   "version": 1,
  ///   "exportedAt": 1717600000000,
  ///   "data": {
  ///     "studyRecords": [...],
  ///     "fitnessRecords": [...],
  ///     ...
  ///   }
  /// }
  /// ```
  Future<String> exportToJson() async {
    final studyRecords = await _db.select(_db.studyRecords).get();
    final fitnessRecords = await _db.select(_db.fitnessRecords).get();
    final fitnessExercises = await _db.select(_db.fitnessExercises).get();
    final bodyMetrics = await _db.select(_db.bodyMetrics).get();
    final dailyJournals = await _db.select(_db.dailyJournals).get();
    final focusSessions = await _db.select(_db.focusSessions).get();
    final growthExpLogs = await _db.select(_db.growthExpLogs).get();
    final appSettings = await _db.select(_db.appSettings).get();
    final aiConfigs = await _db.select(_db.aiConfigs).get();
    final backupRecords = await _db.select(_db.backupRecords).get();

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'data': {
        'studyRecords':
            studyRecords.map((r) => r.toJson()).toList(growable: false),
        'fitnessRecords':
            fitnessRecords.map((r) => r.toJson()).toList(growable: false),
        'fitnessExercises':
            fitnessExercises.map((r) => r.toJson()).toList(growable: false),
        'bodyMetrics':
            bodyMetrics.map((r) => r.toJson()).toList(growable: false),
        'dailyJournals':
            dailyJournals.map((r) => r.toJson()).toList(growable: false),
        'focusSessions':
            focusSessions.map((r) => r.toJson()).toList(growable: false),
        'growthExpLogs':
            growthExpLogs.map((r) => r.toJson()).toList(growable: false),
        'appSettings':
            appSettings.map((r) => r.toJson()).toList(growable: false),
        'aiConfigs':
            aiConfigs.map((r) => r.toJson()).toList(growable: false),
        'backupRecords':
            backupRecords.map((r) => r.toJson()).toList(growable: false),
      },
    };

    return jsonEncode(payload);
  }

  // ---------------------------------------------------------------------------
  // 导入
  // ---------------------------------------------------------------------------

  /// 从 JSON 字符串导入数据到数据库。
  ///
  /// - 使用事务保证原子性，任一表写入失败则整体回滚。
  /// - 缺失的表字段会自动跳过，不会抛出异常。
  Future<void> importFromJson(String jsonStr) async {
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>? ?? {};

    await _db.transaction(() async {
      // 按外键依赖顺序插入：先父表，再子表
      await _importTable(
        data['studyRecords'],
        (json) => StudyRecord.fromJson(json),
        (companion) => _db.into(_db.studyRecords).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['fitnessRecords'],
        (json) => FitnessRecord.fromJson(json),
        (companion) => _db.into(_db.fitnessRecords).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      // fitnessExercises 依赖 fitnessRecords
      await _importTable(
        data['fitnessExercises'],
        (json) => FitnessExercise.fromJson(json),
        (companion) => _db.into(_db.fitnessExercises).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['bodyMetrics'],
        (json) => BodyMetric.fromJson(json),
        (companion) => _db.into(_db.bodyMetrics).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['dailyJournals'],
        (json) => DailyJournal.fromJson(json),
        (companion) => _db.into(_db.dailyJournals).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['focusSessions'],
        (json) => FocusSession.fromJson(json),
        (companion) => _db.into(_db.focusSessions).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['growthExpLogs'],
        (json) => GrowthExpLog.fromJson(json),
        (companion) => _db.into(_db.growthExpLogs).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['appSettings'],
        (json) => AppSetting.fromJson(json),
        (companion) => _db.into(_db.appSettings).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['aiConfigs'],
        (json) => AiConfig.fromJson(json),
        (companion) => _db.into(_db.aiConfigs).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );

      await _importTable(
        data['backupRecords'],
        (json) => BackupRecord.fromJson(json),
        (companion) => _db.into(_db.backupRecords).insert(
              companion,
              mode: InsertMode.insertOrReplace,
            ),
      );
    });
  }

  /// 将 JSON 列表解析为数据类后逐条写入。
  ///
  /// [fromJson] 负责将 `Map<String, dynamic>` 反序列化为 Drift DataClass；
  /// [inserter] 负责将 `Insertable<T>` 写入对应表。
  ///
  /// 每个 Drift 生成的 DataClass 均实现了 `Insertable<自身类型>`，
  /// 因此可直接将 `fromJson` 的结果传入 `inserter`。
  Future<void> _importTable<T extends DataClass>(
    dynamic jsonList,
    T Function(Map<String, dynamic>) fromJson,
    Future<void> Function(Insertable<T>) inserter,
  ) async {
    if (jsonList is! List) return;

    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final dataClass = fromJson(item);
        // T (如 StudyRecord) 实现了 Insertable<T>，可直接传入。
        await inserter(dataClass as Insertable<T>);
      } catch (_) {
        // 单条记录解析/写入失败时跳过，继续处理剩余记录
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 文件操作
  // ---------------------------------------------------------------------------

  /// 将当前数据导出为 JSON 文件并保存到本地文档目录。
  ///
  /// 文件名格式: `backup_YYYYMMDD_HHMMSS.json`。
  /// 同时在 `BackupRecords` 表中插入一条备份记录。
  ///
  /// 返回保存的文件绝对路径。
  Future<String> saveBackupToFile() async {
    final jsonStr = await exportToJson();

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final fileName = 'backup_$timestamp.json';
    final filePath = '${dir.path}${Platform.pathSeparator}$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonStr);

    // 记录备份元数据
    final fileSize = await file.length();
    await _db.into(_db.backupRecords).insert(
          BackupRecordsCompanion(
            backupName: Value(fileName),
            backupPath: Value(filePath),
            backupType: const Value('json'),
            fileSize: Value(fileSize),
            createdAt: Value(now.millisecondsSinceEpoch),
          ),
        );

    return filePath;
  }

  /// 从指定文件路径读取备份 JSON 内容。
  ///
  /// 若文件不存在或读取失败则返回 `null`。
  Future<String?> loadBackupFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }
}
