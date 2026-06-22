import 'dart:io';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

enum DatabaseHealthSeverity { info, warning, error }

enum DatabaseHealthArea {
  integrity,
  schema,
  performance,
  knowledge,
  music,
  settings,
  files,
}

class DatabaseHealthIssue {
  const DatabaseHealthIssue({
    required this.severity,
    required this.area,
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  final DatabaseHealthSeverity severity;
  final DatabaseHealthArea area;
  final String code;
  final String message;
  final Map<String, Object?> details;
}

class DatabaseHealthReport {
  const DatabaseHealthReport({
    required this.schemaVersion,
    required this.issues,
  });

  final int schemaVersion;
  final List<DatabaseHealthIssue> issues;

  bool get isHealthy =>
      issues.every((issue) => issue.severity != DatabaseHealthSeverity.error);

  Iterable<DatabaseHealthIssue> get errors =>
      issues.where((issue) => issue.severity == DatabaseHealthSeverity.error);

  Iterable<DatabaseHealthIssue> get warnings =>
      issues.where((issue) => issue.severity == DatabaseHealthSeverity.warning);
}

class DatabaseHealthService {
  DatabaseHealthService(this._db);

  final AppDatabase _db;

  static const _knowledgeTables = <String>[
    'knowledge_spaces_v3',
    'knowledge_materials',
    'knowledge_cards_v3',
    'knowledge_review_logs_v3',
    'tiantian_qa_sessions',
    'tiantian_qa_messages',
  ];

  static const _knowledgeCardColumns = <String>[
    'order_index',
    'memory_hint',
    'related_concepts_json',
    'source_chunk_id',
    'source_locator_json',
    'concept',
    'knowledge_point',
    'exam_scene',
    'common_mistake',
    'grounded',
    'status',
  ];

  static const _importantIndexes = <String>[
    'idx_knowledge_spaces_v3_active',
    'idx_knowledge_materials_space',
    'idx_knowledge_cards_v3_space_due',
    'idx_tiantian_qa_sessions_space',
    'idx_music_playlist_tracks_playlist',
    'idx_music_playlist_tracks_track',
  ];

  static const _whiteNoisePlaylistName = '\u4e13\u6ce8\u767d\u566a\u97f3';
  static const _legacyWhiteNoisePlaylistName = '\u5b66\u4e60\u6b4c\u5355';

  Future<DatabaseHealthReport> inspect({bool checkFilePaths = true}) async {
    final issues = <DatabaseHealthIssue>[];

    await _guard(
      issues,
      area: DatabaseHealthArea.integrity,
      code: 'sqlite_integrity_check_failed',
      action: () => _checkSqliteIntegrity(issues),
    );
    await _guard(
      issues,
      area: DatabaseHealthArea.schema,
      code: 'schema_check_failed',
      action: () => _checkSchema(issues),
    );
    await _guard(
      issues,
      area: DatabaseHealthArea.performance,
      code: 'index_check_failed',
      action: () => _checkIndexes(issues),
    );
    await _guard(
      issues,
      area: DatabaseHealthArea.integrity,
      code: 'orphan_check_failed',
      action: () => _checkOrphans(issues),
    );
    await _guard(
      issues,
      area: DatabaseHealthArea.knowledge,
      code: 'duplicate_knowledge_check_failed',
      action: () => _checkDuplicateKnowledgeSpaces(issues),
    );
    await _guard(
      issues,
      area: DatabaseHealthArea.music,
      code: 'music_check_failed',
      action: () => _checkMusicSeeds(issues),
    );
    if (checkFilePaths) {
      await _guard(
        issues,
        area: DatabaseHealthArea.files,
        code: 'file_path_check_failed',
        action: () => _checkFilePaths(issues),
      );
    }

    return DatabaseHealthReport(
      schemaVersion: _db.schemaVersion,
      issues: List.unmodifiable(issues),
    );
  }

  Future<void> _checkSqliteIntegrity(List<DatabaseHealthIssue> issues) async {
    final quickCheck = await _db.customSelect('PRAGMA quick_check').get();
    final quickCheckValues = quickCheck.isEmpty
        ? const <Object?>[]
        : quickCheck.first.data.values.toList();
    final quickCheckValue = quickCheckValues.isEmpty
        ? null
        : quickCheckValues.first?.toString();
    if (quickCheckValue != null && quickCheckValue.toLowerCase() != 'ok') {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.error,
          area: DatabaseHealthArea.integrity,
          code: 'sqlite_quick_check_not_ok',
          message: 'SQLite quick_check reported a database integrity problem.',
          details: {'result': quickCheckValue},
        ),
      );
    }

    final foreignKeyRows = await _db
        .customSelect('PRAGMA foreign_key_check')
        .get();
    if (foreignKeyRows.isNotEmpty) {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.error,
          area: DatabaseHealthArea.integrity,
          code: 'sqlite_foreign_key_violations',
          message: 'SQLite reported foreign key violations.',
          details: {
            'count': foreignKeyRows.length,
            'sample': foreignKeyRows.take(5).map((row) => row.data).toList(),
          },
        ),
      );
    }
  }

  Future<void> _checkSchema(List<DatabaseHealthIssue> issues) async {
    for (final table in _knowledgeTables) {
      if (!await _tableExists(table)) {
        issues.add(
          DatabaseHealthIssue(
            severity: DatabaseHealthSeverity.error,
            area: DatabaseHealthArea.schema,
            code: 'missing_table',
            message: 'A required Knowledge V3 table is missing.',
            details: {'table': table},
          ),
        );
      }
    }

    if (await _tableExists('knowledge_cards_v3')) {
      final columns = await _columnsFor('knowledge_cards_v3');
      for (final column in _knowledgeCardColumns) {
        if (!columns.contains(column)) {
          issues.add(
            DatabaseHealthIssue(
              severity: DatabaseHealthSeverity.error,
              area: DatabaseHealthArea.schema,
              code: 'missing_column',
              message: 'knowledge_cards_v3 is missing a required column.',
              details: {'table': 'knowledge_cards_v3', 'column': column},
            ),
          );
        }
      }
    }
  }

  Future<void> _checkIndexes(List<DatabaseHealthIssue> issues) async {
    for (final index in _importantIndexes) {
      if (!await _indexExists(index)) {
        issues.add(
          DatabaseHealthIssue(
            severity: DatabaseHealthSeverity.warning,
            area: DatabaseHealthArea.performance,
            code: 'missing_index',
            message: 'An important performance index is missing.',
            details: {'index': index},
          ),
        );
      }
    }
  }

  Future<void> _checkOrphans(List<DatabaseHealthIssue> issues) async {
    await _checkOrphanCount(
      issues,
      childTable: 'knowledge_materials',
      childColumn: 'space_id',
      parentTable: 'knowledge_spaces_v3',
      parentColumn: 'id',
      code: 'orphan_knowledge_materials',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'knowledge_cards_v3',
      childColumn: 'space_id',
      parentTable: 'knowledge_spaces_v3',
      parentColumn: 'id',
      code: 'orphan_knowledge_cards_space',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'knowledge_cards_v3',
      childColumn: 'material_id',
      parentTable: 'knowledge_materials',
      parentColumn: 'id',
      code: 'orphan_knowledge_cards_material',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'tiantian_qa_sessions',
      childColumn: 'space_id',
      parentTable: 'knowledge_spaces_v3',
      parentColumn: 'id',
      code: 'orphan_tiantian_sessions',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'tiantian_qa_messages',
      childColumn: 'session_id',
      parentTable: 'tiantian_qa_sessions',
      parentColumn: 'id',
      code: 'orphan_tiantian_messages',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'music_playlist_tracks',
      childColumn: 'playlist_id',
      parentTable: 'music_playlists',
      parentColumn: 'id',
      code: 'orphan_music_playlist_tracks_playlist',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'music_playlist_tracks',
      childColumn: 'track_id',
      parentTable: 'music_tracks',
      parentColumn: 'id',
      code: 'orphan_music_playlist_tracks_track',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'journal_assets',
      childColumn: 'journal_id',
      parentTable: 'daily_journals',
      parentColumn: 'id',
      code: 'orphan_journal_assets',
    );
    await _checkOrphanCount(
      issues,
      childTable: 'focus_sessions',
      childColumn: 'related_study_id',
      parentTable: 'study_records',
      parentColumn: 'id',
      code: 'orphan_focus_sessions_study',
    );
  }

  Future<void> _checkDuplicateKnowledgeSpaces(
    List<DatabaseHealthIssue> issues,
  ) async {
    if (!await _tableExists('knowledge_spaces_v3')) return;

    final rows = await _db.customSelect('''
          SELECT name, COUNT(*) AS count
          FROM knowledge_spaces_v3
          WHERE is_archived = 0
          GROUP BY name
          HAVING COUNT(*) > 1
        ''').get();

    for (final row in rows) {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.warning,
          area: DatabaseHealthArea.knowledge,
          code: 'duplicate_active_knowledge_space_name',
          message: 'Multiple active knowledge spaces share the same name.',
          details: {
            'name': row.read<String>('name'),
            'count': row.read<int>('count'),
          },
        ),
      );
    }
  }

  Future<void> _checkMusicSeeds(List<DatabaseHealthIssue> issues) async {
    if (!await _tableExists('music_playlists')) return;

    for (final name in [
      _whiteNoisePlaylistName,
      _legacyWhiteNoisePlaylistName,
    ]) {
      final count = await _count(
        'SELECT COUNT(*) AS count FROM music_playlists WHERE name = ?',
        variables: [Variable<String>(name)],
      );
      if (count > 1) {
        issues.add(
          DatabaseHealthIssue(
            severity: DatabaseHealthSeverity.warning,
            area: DatabaseHealthArea.music,
            code: 'duplicate_music_playlist_name',
            message: 'Multiple music playlists share a default playlist name.',
            details: {'name': name, 'count': count},
          ),
        );
      }
    }

    final defaultCount = await _count(
      'SELECT COUNT(*) AS count FROM music_playlists WHERE name = ?',
      variables: [Variable<String>(_whiteNoisePlaylistName)],
    );
    final legacyCount = await _count(
      'SELECT COUNT(*) AS count FROM music_playlists WHERE name = ?',
      variables: [Variable<String>(_legacyWhiteNoisePlaylistName)],
    );
    if (defaultCount > 0 && legacyCount > 0) {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.warning,
          area: DatabaseHealthArea.music,
          code: 'white_noise_playlist_split',
          message:
              'White-noise seeds appear to be split across current and legacy playlists.',
          details: {
            'currentPlaylist': _whiteNoisePlaylistName,
            'currentCount': defaultCount,
            'legacyPlaylist': _legacyWhiteNoisePlaylistName,
            'legacyCount': legacyCount,
          },
        ),
      );
    }
  }

  Future<void> _checkFilePaths(List<DatabaseHealthIssue> issues) async {
    await _checkAppSettingPath(
      issues,
      key: 'avatar_path',
      label: 'User avatar',
    );
    await _checkTableFilePaths(
      issues,
      table: 'journal_assets',
      idColumn: 'id',
      pathColumn: 'local_path',
      titleColumn: null,
    );
    await _checkTableFilePaths(
      issues,
      table: 'music_tracks',
      idColumn: 'id',
      pathColumn: 'file_path',
      titleColumn: 'title',
    );
  }

  Future<void> _checkAppSettingPath(
    List<DatabaseHealthIssue> issues, {
    required String key,
    required String label,
  }) async {
    if (!await _tableExists('app_settings')) return;
    final row = await _db
        .customSelect(
          'SELECT value FROM app_settings WHERE key = ? LIMIT 1',
          variables: [Variable<String>(key)],
        )
        .getSingleOrNull();
    final path = row?.readNullable<String>('value')?.trim();
    if (!_shouldCheckFile(path)) return;
    if (!await File(path!).exists()) {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.warning,
          area: DatabaseHealthArea.files,
          code: 'missing_file_path',
          message: '$label points to a file that does not exist.',
          details: {'key': key, 'path': path},
        ),
      );
    }
  }

  Future<void> _checkTableFilePaths(
    List<DatabaseHealthIssue> issues, {
    required String table,
    required String idColumn,
    required String pathColumn,
    String? titleColumn,
  }) async {
    if (!await _tableExists(table)) return;
    final titleSql = titleColumn == null ? '' : ', $titleColumn';
    final rows = await _db
        .customSelect('SELECT $idColumn, $pathColumn$titleSql FROM $table')
        .get();

    final missing = <Map<String, Object?>>[];
    for (final row in rows) {
      final path = row.readNullable<String>(pathColumn)?.trim();
      if (!_shouldCheckFile(path)) continue;
      if (!await File(path!).exists()) {
        missing.add({
          'id': row.read<int>(idColumn),
          'path': path,
          if (titleColumn != null)
            'title': row.readNullable<String>(titleColumn),
        });
      }
      if (missing.length >= 10) break;
    }

    if (missing.isNotEmpty) {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.warning,
          area: DatabaseHealthArea.files,
          code: 'missing_file_path',
          message: 'One or more stored file paths do not exist.',
          details: {'table': table, 'samples': missing},
        ),
      );
    }
  }

  Future<void> _checkOrphanCount(
    List<DatabaseHealthIssue> issues, {
    required String childTable,
    required String childColumn,
    required String parentTable,
    required String parentColumn,
    required String code,
  }) async {
    if (!await _tableExists(childTable) || !await _tableExists(parentTable)) {
      return;
    }

    final count = await _count('''
      SELECT COUNT(*) AS count
      FROM $childTable child
      LEFT JOIN $parentTable parent
        ON child.$childColumn = parent.$parentColumn
      WHERE child.$childColumn IS NOT NULL
        AND parent.$parentColumn IS NULL
    ''');
    if (count == 0) return;

    issues.add(
      DatabaseHealthIssue(
        severity: DatabaseHealthSeverity.error,
        area: DatabaseHealthArea.integrity,
        code: code,
        message: 'Rows reference missing parent records.',
        details: {
          'childTable': childTable,
          'childColumn': childColumn,
          'parentTable': parentTable,
          'parentColumn': parentColumn,
          'count': count,
        },
      ),
    );
  }

  Future<bool> _tableExists(String table) async {
    final row = await _db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable<String>(table)],
        )
        .getSingleOrNull();
    return row != null;
  }

  Future<Set<String>> _columnsFor(String table) async {
    final rows = await _db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  Future<bool> _indexExists(String index) async {
    final row = await _db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?",
          variables: [Variable<String>(index)],
        )
        .getSingleOrNull();
    return row != null;
  }

  Future<int> _count(
    String sql, {
    List<Variable> variables = const <Variable>[],
  }) async {
    final row = await _db.customSelect(sql, variables: variables).getSingle();
    return row.read<int>('count');
  }

  bool _shouldCheckFile(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return false;
    final lower = value.toLowerCase();
    return !lower.startsWith('assets/') &&
        !lower.startsWith('asset:') &&
        !lower.startsWith('builtin:') &&
        !lower.startsWith('http://') &&
        !lower.startsWith('https://');
  }

  Future<void> _guard(
    List<DatabaseHealthIssue> issues, {
    required DatabaseHealthArea area,
    required String code,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (error) {
      issues.add(
        DatabaseHealthIssue(
          severity: DatabaseHealthSeverity.error,
          area: area,
          code: code,
          message: 'Database health inspection failed for this check.',
          details: {'error': error.toString()},
        ),
      );
    }
  }
}
