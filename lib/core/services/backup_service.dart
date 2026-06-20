import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

class BackupRestoreException implements Exception {
  const BackupRestoreException({
    required this.message,
    this.tableName,
    this.rowIndex,
    this.recordId,
  });

  final String message;
  final String? tableName;
  final int? rowIndex;
  final Object? recordId;

  @override
  String toString() {
    final parts = <String>[
      'BackupRestoreException: $message',
      if (tableName != null) 'table=$tableName',
      if (rowIndex != null) 'row=$rowIndex',
      if (recordId != null) 'id=$recordId',
    ];
    return parts.join(', ');
  }
}

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<String> exportToJson() async {
    final data = <String, List<Map<String, dynamic>>>{};
    final counts = <String, int>{};

    for (final spec in _tableSpecs) {
      final rows = await spec.exportRows();
      data[spec.name] = rows;
      counts[spec.name] = rows.length;
    }

    // Export V3 knowledge tables (raw SQL, not registered in Drift)
    for (final tableName in [
      'knowledge_spaces_v3',
      'knowledge_materials',
      'knowledge_cards_v3',
      'knowledge_review_logs_v3',
      'tiantian_qa_sessions',
      'tiantian_qa_messages',
    ]) {
      try {
        final rows = await _db.customSelect('SELECT * FROM $tableName').get();
        data[tableName] = rows.map((r) => r.data).toList(growable: false);
        counts[tableName] = rows.length;
      } catch (_) {
        data[tableName] = [];
        counts[tableName] = 0;
      }
    }

    final jsonStr = jsonEncode(data);
    final checksum = _calculateChecksum(jsonStr);

    final payload = {
      'version': 2,
      'backupVersion': 2,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'checksum': checksum,
      'tables': counts,
      'data': data,
    };

    return jsonEncode(payload);
  }

  /// 计算数据校验和（简单 hash，不引入额外依赖）
  String _calculateChecksum(String data) {
    var hash = 0;
    for (var i = 0; i < data.length; i++) {
      hash = ((hash << 5) - hash) + data.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toRadixString(16);
  }

  Future<void> importFromJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const BackupRestoreException(
        message: 'Backup root is not an object',
      );
    }

    final version = decoded['backupVersion'] ?? decoded['version'];
    if (version is! int || version < 2) {
      throw BackupRestoreException(
        message: 'Unsupported backup version: ${version ?? 'missing'}',
      );
    }

    // 检查 schemaVersion 兼容性
    final backupSchemaVersion = decoded['schemaVersion'] as int?;
    if (backupSchemaVersion != null &&
        backupSchemaVersion > _db.schemaVersion) {
      throw BackupRestoreException(message: '备份来自更高版本的应用，无法恢复。请先更新应用。');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupRestoreException(message: 'Backup data is missing');
    }

    await _db.transaction(() async {
      // 先清除所有业务表（反向顺序避免 FK 冲突），跳过 backupRecords
      for (final spec in _tableSpecs.reversed) {
        if (spec.name == 'backupRecords') continue;
        await spec.deleteAll();
      }
      // 再导入
      for (final spec in _tableSpecs) {
        // 跳过备份记录（设备本地元数据，不应跨设备恢复）
        if (spec.name == 'backupRecords') continue;
        await spec.importRows(data[spec.name]);
      }

      // Import V3 knowledge tables (raw SQL)
      final v3Tables = [
        'knowledge_spaces_v3',
        'knowledge_materials',
        'knowledge_cards_v3',
        'knowledge_review_logs_v3',
        'tiantian_qa_sessions',
        'tiantian_qa_messages',
      ];
      // Delete existing V3 data in reverse FK order
      for (final tableName in v3Tables.reversed) {
        try {
          await _db.customStatement('DELETE FROM $tableName');
        } catch (_) {}
      }
      // Insert in FK order
      for (final tableName in v3Tables) {
        final rawRows = decoded['data'][tableName];
        if (rawRows is! List) continue;
        for (final raw in rawRows) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw);
          final columns = row.keys.join(', ');
          final placeholders = row.keys.map((_) => '?').join(', ');
          try {
            await _db.customStatement(
              'INSERT OR REPLACE INTO $tableName ($columns) VALUES ($placeholders)',
              row.values.toList(),
            );
          } catch (_) {}
        }
      }
    });
  }

  Future<String> saveBackupToFile() async {
    final jsonStr = await exportToJson();

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}${Platform.pathSeparator}backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final now = DateTime.now();
    final timestamp =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final fileName = 'backup_$timestamp.json';
    final filePath = '${backupDir.path}${Platform.pathSeparator}$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonStr, encoding: utf8);

    final fileSize = await file.length();
    await _db
        .into(_db.backupRecords)
        .insert(
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

  Future<String?> loadBackupFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw BackupRestoreException(message: '备份文件不存在: $path');
    }
    try {
      return await file.readAsString();
    } catch (e) {
      throw BackupRestoreException(message: '备份文件读取失败: $e');
    }
  }

  List<_BackupTableSpec> get _tableSpecs => [
    _BackupTableSpec<StudyRecord>(
      name: 'studyRecords',
      exportRows: () async =>
          (await _db.select(_db.studyRecords).get()).mapJson(),
      fromJson: StudyRecord.fromJson,
      insert: (row) => _db
          .into(_db.studyRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.studyRecords).go(),
    ),
    _BackupTableSpec<KnowledgeCard>(
      name: 'knowledgeCards',
      exportRows: () async =>
          (await _db.select(_db.knowledgeCards).get()).mapJson(),
      fromJson: _knowledgeCardFromJson,
      insert: (row) => _db
          .into(_db.knowledgeCards)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeCards).go(),
      optional: true,
    ),
    _BackupTableSpec<KnowledgeReviewLog>(
      name: 'knowledgeReviewLogs',
      exportRows: () async =>
          (await _db.select(_db.knowledgeReviewLogs).get()).mapJson(),
      fromJson: KnowledgeReviewLog.fromJson,
      insert: (row) => _db
          .into(_db.knowledgeReviewLogs)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeReviewLogs).go(),
      optional: true,
    ),
    _BackupTableSpec<KnowledgeCustomTemplate>(
      name: 'knowledgeCustomTemplates',
      exportRows: () async =>
          (await _db.select(_db.knowledgeCustomTemplates).get()).mapJson(),
      fromJson: KnowledgeCustomTemplate.fromJson,
      insert: (row) => _db
          .into(_db.knowledgeCustomTemplates)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeCustomTemplates).go(),
      optional: true,
    ),
    _BackupTableSpec<KnowledgeCustomTemplateModule>(
      name: 'knowledgeCustomTemplateModules',
      exportRows: () async =>
          (await _db.select(_db.knowledgeCustomTemplateModules).get())
              .mapJson(),
      fromJson: KnowledgeCustomTemplateModule.fromJson,
      insert: (row) => _db
          .into(_db.knowledgeCustomTemplateModules)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeCustomTemplateModules).go(),
      optional: true,
    ),
    _BackupTableSpec<KnowledgeSource>(
      name: 'knowledgeSources',
      exportRows: () async =>
          (await _db.select(_db.knowledgeSources).get()).mapJson(),
      fromJson: KnowledgeSource.fromJson,
      insert: (row) => _db
          .into(_db.knowledgeSources)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeSources).go(),
      optional: true,
    ),
    _BackupTableSpec<KnowledgeChunk>(
      name: 'knowledgeChunks',
      exportRows: () async =>
          (await _db.select(_db.knowledgeChunks).get()).mapJson(),
      fromJson: KnowledgeChunk.fromJson,
      insert: (row) => _db
          .into(_db.knowledgeChunks)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeChunks).go(),
      optional: true,
    ),
    _BackupTableSpec<KnowledgeCardSourceLink>(
      name: 'knowledgeCardSourceLinks',
      exportRows: () async =>
          (await _db.select(_db.knowledgeCardSourceLinks).get()).mapJson(),
      fromJson: KnowledgeCardSourceLink.fromJson,
      insert: (row) => _db
          .into(_db.knowledgeCardSourceLinks)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.knowledgeCardSourceLinks).go(),
      optional: true,
    ),
    _BackupTableSpec<FitnessRecord>(
      name: 'fitnessRecords',
      exportRows: () async =>
          (await _db.select(_db.fitnessRecords).get()).mapJson(),
      fromJson: FitnessRecord.fromJson,
      insert: (row) => _db
          .into(_db.fitnessRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.fitnessRecords).go(),
    ),
    _BackupTableSpec<FitnessWorkoutTemplate>(
      name: 'fitnessWorkoutTemplates',
      exportRows: () async =>
          (await _db.select(_db.fitnessWorkoutTemplates).get()).mapJson(),
      fromJson: FitnessWorkoutTemplate.fromJson,
      insert: (row) => _db
          .into(_db.fitnessWorkoutTemplates)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.fitnessWorkoutTemplates).go(),
    ),
    _BackupTableSpec<BodyMetric>(
      name: 'bodyMetrics',
      exportRows: () async =>
          (await _db.select(_db.bodyMetrics).get()).mapJson(),
      fromJson: BodyMetric.fromJson,
      insert: (row) => _db
          .into(_db.bodyMetrics)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.bodyMetrics).go(),
    ),
    _BackupTableSpec<JournalFolder>(
      name: 'journalFolders',
      exportRows: () async =>
          (await _db.select(_db.journalFolders).get()).mapJson(),
      fromJson: JournalFolder.fromJson,
      insert: (row) => _db
          .into(_db.journalFolders)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.journalFolders).go(),
    ),
    _BackupTableSpec<DailyJournal>(
      name: 'dailyJournals',
      exportRows: () async =>
          (await _db.select(_db.dailyJournals).get()).mapJson(),
      fromJson: DailyJournal.fromJson,
      insert: (row) => _db
          .into(_db.dailyJournals)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.dailyJournals).go(),
    ),
    _BackupTableSpec<TaskTemplate>(
      name: 'taskTemplates',
      exportRows: () async =>
          (await _db.select(_db.taskTemplates).get()).mapJson(),
      fromJson: TaskTemplate.fromJson,
      insert: (row) => _db
          .into(_db.taskTemplates)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.taskTemplates).go(),
    ),
    _BackupTableSpec<DailyTask>(
      name: 'dailyTasks',
      exportRows: () async =>
          (await _db.select(_db.dailyTasks).get()).mapJson(),
      fromJson: DailyTask.fromJson,
      insert: (row) => _db
          .into(_db.dailyTasks)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.dailyTasks).go(),
    ),
    _BackupTableSpec<DietRecord>(
      name: 'dietRecords',
      exportRows: () async =>
          (await _db.select(_db.dietRecords).get()).mapJson(),
      fromJson: DietRecord.fromJson,
      insert: (row) => _db
          .into(_db.dietRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.dietRecords).go(),
    ),
    _BackupTableSpec<SleepRecord>(
      name: 'sleepRecords',
      exportRows: () async =>
          (await _db.select(_db.sleepRecords).get()).mapJson(),
      fromJson: SleepRecord.fromJson,
      insert: (row) => _db
          .into(_db.sleepRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.sleepRecords).go(),
    ),
    _BackupTableSpec<PetProfile>(
      name: 'petProfiles',
      exportRows: () async =>
          (await _db.select(_db.petProfiles).get()).mapJson(),
      fromJson: PetProfile.fromJson,
      insert: (row) => _db
          .into(_db.petProfiles)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.petProfiles).go(),
    ),
    _BackupTableSpec<PetState>(
      name: 'petStates',
      exportRows: () async => (await _db.select(_db.petStates).get()).mapJson(),
      fromJson: PetState.fromJson,
      insert: (row) =>
          _db.into(_db.petStates).insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.petStates).go(),
    ),
    _BackupTableSpec<PetDiary>(
      name: 'petDiaries',
      exportRows: () async =>
          (await _db.select(_db.petDiaries).get()).mapJson(),
      fromJson: PetDiary.fromJson,
      insert: (row) => _db
          .into(_db.petDiaries)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.petDiaries).go(),
    ),
    _BackupTableSpec<DailyWeather>(
      name: 'dailyWeather',
      exportRows: () async =>
          (await _db.select(_db.dailyWeatherTable).get()).mapJson(),
      fromJson: DailyWeather.fromJson,
      insert: (row) => _db
          .into(_db.dailyWeatherTable)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.dailyWeatherTable).go(),
    ),
    _BackupTableSpec<ApiConfig>(
      name: 'apiConfigs',
      exportRows: () async =>
          (await _db.select(_db.apiConfigs).get()).mapJson(),
      fromJson: ApiConfig.fromJson,
      insert: (row) => _db
          .into(_db.apiConfigs)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.apiConfigs).go(),
    ),
    _BackupTableSpec<WeatherSearchHistory>(
      name: 'weatherSearchHistory',
      exportRows: () async =>
          (await _db.select(_db.weatherSearchHistoryTable).get()).mapJson(),
      fromJson: WeatherSearchHistory.fromJson,
      insert: (row) => _db
          .into(_db.weatherSearchHistoryTable)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.weatherSearchHistoryTable).go(),
    ),
    _BackupTableSpec<MusicTrack>(
      name: 'musicTracks',
      exportRows: () async =>
          (await _db.select(_db.musicTracks).get()).mapJson(),
      fromJson: MusicTrack.fromJson,
      insert: (row) => _db
          .into(_db.musicTracks)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.musicTracks).go(),
    ),
    _BackupTableSpec<MusicPlaylist>(
      name: 'musicPlaylists',
      exportRows: () async =>
          (await _db.select(_db.musicPlaylists).get()).mapJson(),
      fromJson: MusicPlaylist.fromJson,
      insert: (row) => _db
          .into(_db.musicPlaylists)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.musicPlaylists).go(),
    ),
    _BackupTableSpec<MusicPlaylistTrack>(
      name: 'musicPlaylistTracks',
      exportRows: () async =>
          (await _db.select(_db.musicPlaylistTracks).get()).mapJson(),
      fromJson: MusicPlaylistTrack.fromJson,
      insert: (row) => _db
          .into(_db.musicPlaylistTracks)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.musicPlaylistTracks).go(),
    ),
    _BackupTableSpec<AppSetting>(
      name: 'appSettings',
      exportRows: () async =>
          (await _db.select(_db.appSettings).get()).mapJson(),
      fromJson: AppSetting.fromJson,
      insert: (row) => _db
          .into(_db.appSettings)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.appSettings).go(),
    ),
    _BackupTableSpec<AiConfig>(
      name: 'aiConfigs',
      exportRows: () async => (await _db.select(_db.aiConfigs).get()).mapJson(),
      fromJson: AiConfig.fromJson,
      insert: (row) =>
          _db.into(_db.aiConfigs).insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.aiConfigs).go(),
    ),
    _BackupTableSpec<BackupRecord>(
      name: 'backupRecords',
      exportRows: () async =>
          (await _db.select(_db.backupRecords).get()).mapJson(),
      fromJson: BackupRecord.fromJson,
      insert: (row) => _db
          .into(_db.backupRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.backupRecords).go(),
    ),
    _BackupTableSpec<FitnessExercise>(
      name: 'fitnessExercises',
      exportRows: () async =>
          (await _db.select(_db.fitnessExercises).get()).mapJson(),
      fromJson: FitnessExercise.fromJson,
      insert: (row) => _db
          .into(_db.fitnessExercises)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.fitnessExercises).go(),
    ),
    _BackupTableSpec<FitnessWorkoutTemplateExercise>(
      name: 'fitnessWorkoutTemplateExercises',
      exportRows: () async =>
          (await _db.select(_db.fitnessWorkoutTemplateExercises).get())
              .mapJson(),
      fromJson: FitnessWorkoutTemplateExercise.fromJson,
      insert: (row) => _db
          .into(_db.fitnessWorkoutTemplateExercises)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.fitnessWorkoutTemplateExercises).go(),
    ),
    _BackupTableSpec<JournalAsset>(
      name: 'journalAssets',
      exportRows: () async =>
          (await _db.select(_db.journalAssets).get()).mapJson(),
      fromJson: JournalAsset.fromJson,
      insert: (row) => _db
          .into(_db.journalAssets)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.journalAssets).go(),
    ),
    _BackupTableSpec<FocusSession>(
      name: 'focusSessions',
      exportRows: () async =>
          (await _db.select(_db.focusSessions).get()).mapJson(),
      fromJson: FocusSession.fromJson,
      insert: (row) => _db
          .into(_db.focusSessions)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.focusSessions).go(),
    ),
    _BackupTableSpec<GrowthExpLog>(
      name: 'growthExpLogs',
      exportRows: () async =>
          (await _db.select(_db.growthExpLogs).get()).mapJson(),
      fromJson: GrowthExpLog.fromJson,
      insert: (row) => _db
          .into(_db.growthExpLogs)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.growthExpLogs).go(),
    ),
    _BackupTableSpec<PetMessage>(
      name: 'petMessages',
      exportRows: () async =>
          (await _db.select(_db.petMessages).get()).mapJson(),
      fromJson: PetMessage.fromJson,
      insert: (row) => _db
          .into(_db.petMessages)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.petMessages).go(),
    ),
    _BackupTableSpec<AiChatMessage>(
      name: 'aiChatMessages',
      exportRows: () async =>
          (await _db.select(_db.aiChatMessages).get()).mapJson(),
      fromJson: AiChatMessage.fromJson,
      insert: (row) => _db
          .into(_db.aiChatMessages)
          .insert(row, mode: InsertMode.insertOrReplace),
      deleteAll: () => _db.delete(_db.aiChatMessages).go(),
      optional: true,
    ),
  ];

  static KnowledgeCard _knowledgeCardFromJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json)
      ..putIfAbsent('goalKey', () => 'custom')
      ..putIfAbsent('goalName', () => null)
      ..putIfAbsent('moduleKey', () => 'custom')
      ..putIfAbsent('moduleName', () => null);
    return KnowledgeCard.fromJson(normalized);
  }
}

class _BackupTableSpec<T extends DataClass> {
  const _BackupTableSpec({
    required this.name,
    required this.exportRows,
    required this.fromJson,
    required this.insert,
    required this.deleteAll,
    this.optional = false,
  });

  final String name;
  final Future<List<Map<String, dynamic>>> Function() exportRows;
  final T Function(Map<String, dynamic>) fromJson;
  final Future<void> Function(Insertable<T>) insert;
  final Future<void> Function() deleteAll;
  final bool optional;

  Future<void> importRows(dynamic rawRows) async {
    if (rawRows == null) {
      if (optional) return;
      throw BackupRestoreException(
        tableName: name,
        message: 'Table is missing from backup',
      );
    }
    if (rawRows is! List) {
      throw BackupRestoreException(
        tableName: name,
        message: 'Table payload is not a list',
      );
    }

    for (var index = 0; index < rawRows.length; index++) {
      final raw = rawRows[index];
      if (raw is! Map) {
        throw BackupRestoreException(
          tableName: name,
          rowIndex: index,
          message: 'Record is not an object',
        );
      }

      final row = Map<String, dynamic>.from(raw);
      try {
        final dataClass = fromJson(row);
        await insert(dataClass as Insertable<T>);
      } catch (error) {
        throw BackupRestoreException(
          tableName: name,
          rowIndex: index,
          recordId: row['id'] ?? row['key'],
          message: error.toString(),
        );
      }
    }
  }
}

extension _JsonRows<T extends DataClass> on List<T> {
  List<Map<String, dynamic>> mapJson() {
    return map((row) => row.toJson()).toList(growable: false);
  }
}
