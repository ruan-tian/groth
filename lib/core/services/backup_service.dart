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

    final payload = {
      'version': 2,
      'backupVersion': 2,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'tables': counts,
      'data': data,
    };

    return jsonEncode(payload);
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

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupRestoreException(message: 'Backup data is missing');
    }

    await _db.transaction(() async {
      for (final spec in _tableSpecs) {
        await spec.importRows(data[spec.name]);
      }
    });
  }

  Future<String> saveBackupToFile() async {
    final jsonStr = await exportToJson();

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final timestamp =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final fileName = 'backup_$timestamp.json';
    final filePath = '${dir.path}${Platform.pathSeparator}$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonStr);

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
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
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
    ),
    _BackupTableSpec<FitnessRecord>(
      name: 'fitnessRecords',
      exportRows: () async =>
          (await _db.select(_db.fitnessRecords).get()).mapJson(),
      fromJson: FitnessRecord.fromJson,
      insert: (row) => _db
          .into(_db.fitnessRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<FitnessWorkoutTemplate>(
      name: 'fitnessWorkoutTemplates',
      exportRows: () async =>
          (await _db.select(_db.fitnessWorkoutTemplates).get()).mapJson(),
      fromJson: FitnessWorkoutTemplate.fromJson,
      insert: (row) => _db
          .into(_db.fitnessWorkoutTemplates)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<BodyMetric>(
      name: 'bodyMetrics',
      exportRows: () async =>
          (await _db.select(_db.bodyMetrics).get()).mapJson(),
      fromJson: BodyMetric.fromJson,
      insert: (row) => _db
          .into(_db.bodyMetrics)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<DailyJournal>(
      name: 'dailyJournals',
      exportRows: () async =>
          (await _db.select(_db.dailyJournals).get()).mapJson(),
      fromJson: DailyJournal.fromJson,
      insert: (row) => _db
          .into(_db.dailyJournals)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<TaskTemplate>(
      name: 'taskTemplates',
      exportRows: () async =>
          (await _db.select(_db.taskTemplates).get()).mapJson(),
      fromJson: TaskTemplate.fromJson,
      insert: (row) => _db
          .into(_db.taskTemplates)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<DailyTask>(
      name: 'dailyTasks',
      exportRows: () async =>
          (await _db.select(_db.dailyTasks).get()).mapJson(),
      fromJson: DailyTask.fromJson,
      insert: (row) => _db
          .into(_db.dailyTasks)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<DietRecord>(
      name: 'dietRecords',
      exportRows: () async =>
          (await _db.select(_db.dietRecords).get()).mapJson(),
      fromJson: DietRecord.fromJson,
      insert: (row) => _db
          .into(_db.dietRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<SleepRecord>(
      name: 'sleepRecords',
      exportRows: () async =>
          (await _db.select(_db.sleepRecords).get()).mapJson(),
      fromJson: SleepRecord.fromJson,
      insert: (row) => _db
          .into(_db.sleepRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<PetProfile>(
      name: 'petProfiles',
      exportRows: () async =>
          (await _db.select(_db.petProfiles).get()).mapJson(),
      fromJson: PetProfile.fromJson,
      insert: (row) => _db
          .into(_db.petProfiles)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<PetState>(
      name: 'petStates',
      exportRows: () async => (await _db.select(_db.petStates).get()).mapJson(),
      fromJson: PetState.fromJson,
      insert: (row) =>
          _db.into(_db.petStates).insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<PetDiary>(
      name: 'petDiaries',
      exportRows: () async =>
          (await _db.select(_db.petDiaries).get()).mapJson(),
      fromJson: PetDiary.fromJson,
      insert: (row) => _db
          .into(_db.petDiaries)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<DailyWeather>(
      name: 'dailyWeather',
      exportRows: () async =>
          (await _db.select(_db.dailyWeatherTable).get()).mapJson(),
      fromJson: DailyWeather.fromJson,
      insert: (row) => _db
          .into(_db.dailyWeatherTable)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<ApiConfig>(
      name: 'apiConfigs',
      exportRows: () async =>
          (await _db.select(_db.apiConfigs).get()).mapJson(),
      fromJson: ApiConfig.fromJson,
      insert: (row) => _db
          .into(_db.apiConfigs)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<WeatherSearchHistory>(
      name: 'weatherSearchHistory',
      exportRows: () async =>
          (await _db.select(_db.weatherSearchHistoryTable).get()).mapJson(),
      fromJson: WeatherSearchHistory.fromJson,
      insert: (row) => _db
          .into(_db.weatherSearchHistoryTable)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<MusicTrack>(
      name: 'musicTracks',
      exportRows: () async =>
          (await _db.select(_db.musicTracks).get()).mapJson(),
      fromJson: MusicTrack.fromJson,
      insert: (row) => _db
          .into(_db.musicTracks)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<AppSetting>(
      name: 'appSettings',
      exportRows: () async =>
          (await _db.select(_db.appSettings).get()).mapJson(),
      fromJson: AppSetting.fromJson,
      insert: (row) => _db
          .into(_db.appSettings)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<AiConfig>(
      name: 'aiConfigs',
      exportRows: () async => (await _db.select(_db.aiConfigs).get()).mapJson(),
      fromJson: AiConfig.fromJson,
      insert: (row) =>
          _db.into(_db.aiConfigs).insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<BackupRecord>(
      name: 'backupRecords',
      exportRows: () async =>
          (await _db.select(_db.backupRecords).get()).mapJson(),
      fromJson: BackupRecord.fromJson,
      insert: (row) => _db
          .into(_db.backupRecords)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<FitnessExercise>(
      name: 'fitnessExercises',
      exportRows: () async =>
          (await _db.select(_db.fitnessExercises).get()).mapJson(),
      fromJson: FitnessExercise.fromJson,
      insert: (row) => _db
          .into(_db.fitnessExercises)
          .insert(row, mode: InsertMode.insertOrReplace),
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
    ),
    _BackupTableSpec<JournalAsset>(
      name: 'journalAssets',
      exportRows: () async =>
          (await _db.select(_db.journalAssets).get()).mapJson(),
      fromJson: JournalAsset.fromJson,
      insert: (row) => _db
          .into(_db.journalAssets)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<FocusSession>(
      name: 'focusSessions',
      exportRows: () async =>
          (await _db.select(_db.focusSessions).get()).mapJson(),
      fromJson: FocusSession.fromJson,
      insert: (row) => _db
          .into(_db.focusSessions)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<GrowthExpLog>(
      name: 'growthExpLogs',
      exportRows: () async =>
          (await _db.select(_db.growthExpLogs).get()).mapJson(),
      fromJson: GrowthExpLog.fromJson,
      insert: (row) => _db
          .into(_db.growthExpLogs)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
    _BackupTableSpec<PetMessage>(
      name: 'petMessages',
      exportRows: () async =>
          (await _db.select(_db.petMessages).get()).mapJson(),
      fromJson: PetMessage.fromJson,
      insert: (row) => _db
          .into(_db.petMessages)
          .insert(row, mode: InsertMode.insertOrReplace),
    ),
  ];
}

class _BackupTableSpec<T extends DataClass> {
  const _BackupTableSpec({
    required this.name,
    required this.exportRows,
    required this.fromJson,
    required this.insert,
  });

  final String name;
  final Future<List<Map<String, dynamic>>> Function() exportRows;
  final T Function(Map<String, dynamic>) fromJson;
  final Future<void> Function(Insertable<T>) insert;

  Future<void> importRows(dynamic rawRows) async {
    if (rawRows == null) {
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
