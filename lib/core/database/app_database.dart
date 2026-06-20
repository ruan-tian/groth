import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'tables_extra.dart';
import 'pet_tables.dart';
import 'pet_messages.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    StudyRecords,
    FitnessRecords,
    FitnessExercises,
    FitnessWorkoutTemplates,
    FitnessWorkoutTemplateExercises,
    BodyMetrics,
    JournalFolders,
    DailyJournals,
    FocusSessions,
    KnowledgeCards,
    KnowledgeReviewLogs,
    KnowledgeCustomTemplates,
    KnowledgeCustomTemplateModules,
    KnowledgeSources,
    KnowledgeChunks,
    KnowledgeCardSourceLinks,
    GrowthExpLogs,
    AppSettings,
    AiConfigs,
    BackupRecords,
    DailyTasks,
    TaskTemplates,
    DietRecords,
    SleepRecords,
    PetProfiles,
    PetStates,
    PetDiaries,
    JournalAssets,
    PetMessages,
    DailyWeatherTable,
    ApiConfigs,
    WeatherSearchHistoryTable,
    MusicTracks,
    MusicPlaylists,
    MusicPlaylistTracks,
    AiChatMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'growth_os_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  int get schemaVersion => 28;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Index creation moved to background - see ensureIndexesReady()
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // 娣诲姞姣忔棩浠诲姟锟?
          await m.createTable(dailyTasks);
          // 娣诲姞浠诲姟妯℃澘锟?
          await m.createTable(taskTemplates);
        }
        if (from < 3) {
          // 娣诲姞楗璁板綍锟?
          await m.createTable(dietRecords);
          // 娣诲姞鐫＄湢璁板綍锟?
          await m.createTable(sleepRecords);
        }
        if (from < 4) {
          // 娣诲姞瀹犵墿锟?
          await m.createTable(petProfiles);
          await m.createTable(petStates);
        }
        if (from < 5) {
          // 娣诲姞鏃ヨ闄勪欢锟?
          await m.createTable(journalAssets);
          // 涓烘棩璁拌〃娣诲姞 Markdown 鏀寔锟?
          await m.addColumn(dailyJournals, dailyJournals.markdownContent);
          await m.addColumn(dailyJournals, dailyJournals.plainText);
        }
        if (from < 6) {
          // 娣诲姞瀵屾枃鏈紪杈戝櫒鏀寔锟?
          await m.addColumn(dailyJournals, dailyJournals.contentType);
          await m.addColumn(dailyJournals, dailyJournals.quillDeltaJson);
        }
        if (from < 7) {
          // 娣诲姞瀹犵墿娑堟伅锟?
          await m.createTable(petMessages);
        }
        if (from < 9) {
          // 娣诲姞澶╂皵璁板綍锟?
          await m.createTable(dailyWeatherTable);
        }
        if (from < 10) {
          // 娣诲姞 API 閰嶇疆锟?
          await m.createTable(apiConfigs);
        }
        if (from < 11) {
          // 娣诲姞澶╂皵鍩庡競鎼滅储鍘嗗彶锟?
          await m.createTable(weatherSearchHistoryTable);
        }
        if (from < 13) {
          // 涓烘瘡鏃ヤ换鍔¤〃娣诲姞浼樺厛绾у垪
          await m.addColumn(dailyTasks, dailyTasks.priority);
        }
        if (from < 14) {
          await m.createTable(petDiaries);
        }
        if (from < 15) {
          // 涓轰笓娉ㄨ褰曡〃娣诲姞杞鍜屽垎缁勫垪
          await m.addColumn(focusSessions, focusSessions.roundIndex);
          await m.addColumn(focusSessions, focusSessions.sessionGroupId);
        }
        if (from < 16) {
          await m.createTable(fitnessWorkoutTemplates);
          await m.createTable(fitnessWorkoutTemplateExercises);
          await m.addColumn(fitnessExercises, fitnessExercises.exerciseType);
          await m.addColumn(fitnessExercises, fitnessExercises.durationSeconds);
          await m.addColumn(fitnessExercises, fitnessExercises.sortOrder);
        }
        if (from < 17) {
          await m.createTable(musicTracks);
        }
        if (from < 19) {
          // 涓哄仴韬褰曡〃娣诲姞杩愬姩绫诲瀷锟?
          await m.addColumn(fitnessRecords, fitnessRecords.activityType);
        }
        if (from < 20) {
          await m.createTable(journalFolders);
          await m.addColumn(dailyJournals, dailyJournals.folderId);
        }
        if (from < 21) {
          await m.createTable(musicPlaylists);
          await m.createTable(musicPlaylistTracks);
        }
        if (from < 22) {
          await m.addColumn(musicTracks, musicTracks.sceneOverride);
        }
        if (from < 23) {
          await m.createTable(knowledgeCards);
          await m.createTable(knowledgeReviewLogs);
        }
        if (from < 24) {
          await m.addColumn(knowledgeCards, knowledgeCards.goalKey);
          await m.addColumn(knowledgeCards, knowledgeCards.goalName);
          await m.addColumn(knowledgeCards, knowledgeCards.moduleKey);
          await m.addColumn(knowledgeCards, knowledgeCards.moduleName);
        }
        if (from < 25) {
          await m.createTable(knowledgeCustomTemplates);
          await m.createTable(knowledgeCustomTemplateModules);
        }
        if (from < 26) {
          await m.createTable(knowledgeSources);
          await m.createTable(knowledgeChunks);
          await m.createTable(knowledgeCardSourceLinks);
        }
        if (from < 27) {
          await m.createTable(aiChatMessages);
        }
        if (from < 28) {
          await _createKnowledgeV3Tables();
          await _seedKnowledgeV3FromLegacy();
        }
        await _ensureKnowledgeV3Schema();
      },
    );
  }

  Future<void> _createPerformanceIndexes() async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_study_records_created_at ON study_records(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_fitness_records_created_at ON fitness_records(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_focus_sessions_created_at ON focus_sessions(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_deck ON knowledge_cards(deck_key, archived)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_goal ON knowledge_cards(goal_key, archived)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_module ON knowledge_cards(goal_key, module_key, archived)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_due ON knowledge_cards(due_at, archived)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_mastery ON knowledge_cards(archived, mastery_level)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_streak ON knowledge_cards(archived, correct_streak)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_due_mastery ON knowledge_cards(archived, due_at, mastery_level)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_review_logs_card ON knowledge_review_logs(card_id, reviewed_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_custom_templates_active ON knowledge_custom_templates(archived, sort_order, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_custom_template_modules_template ON knowledge_custom_template_modules(template_id, archived, sort_order, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_sources_scope ON knowledge_sources(goal_key, module_key, archived, updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_sources_created_at ON knowledge_sources(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_source ON knowledge_chunks(source_id, chunk_index)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_card_source_links_card ON knowledge_card_source_links(card_id, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_card_source_links_chunk ON knowledge_card_source_links(chunk_id)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_spaces_v3_active ON knowledge_spaces_v3(is_archived, sort_order, updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_materials_space ON knowledge_materials(space_id, is_archived, order_index, updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_v3_space_due ON knowledge_cards_v3(space_id, is_archived, due_at)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_cards_v3_space_mastery ON knowledge_cards_v3(space_id, is_archived, mastery_level)',
      'CREATE INDEX IF NOT EXISTS idx_knowledge_review_logs_v3_card ON knowledge_review_logs_v3(card_id, reviewed_at)',
      'CREATE INDEX IF NOT EXISTS idx_tiantian_qa_sessions_space ON tiantian_qa_sessions(space_id, updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_tiantian_qa_messages_session ON tiantian_qa_messages(session_id, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_growth_exp_logs_created_at ON growth_exp_logs(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_growth_exp_logs_source_created ON growth_exp_logs(source_type, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_body_metrics_created_at ON body_metrics(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_body_metrics_record_date ON body_metrics(record_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_journals_journal_date ON daily_journals(journal_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_journals_folder_id ON daily_journals(folder_id)',
      'CREATE INDEX IF NOT EXISTS idx_daily_journals_date_folder ON daily_journals(journal_date, folder_id)',
      'CREATE INDEX IF NOT EXISTS idx_journal_folders_sort ON journal_folders(sort_order, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_daily_tasks_task_date ON daily_tasks(task_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_tasks_template_id ON daily_tasks(template_id)',
      'CREATE INDEX IF NOT EXISTS idx_diet_records_meal_date ON diet_records(meal_date)',
      'CREATE INDEX IF NOT EXISTS idx_sleep_records_sleep_date ON sleep_records(sleep_date)',
      'CREATE INDEX IF NOT EXISTS idx_daily_weather_date_city ON daily_weather_table(date, city)',
      'CREATE INDEX IF NOT EXISTS idx_weather_search_history_city ON weather_search_history_table(city_name)',
      'CREATE INDEX IF NOT EXISTS idx_weather_search_history_created_at ON weather_search_history_table(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_fitness_exercises_record_id ON fitness_exercises(fitness_record_id)',
      'CREATE INDEX IF NOT EXISTS idx_template_exercises_template_id ON fitness_workout_template_exercises(template_id)',
      'CREATE INDEX IF NOT EXISTS idx_journal_assets_journal_id ON journal_assets(journal_id)',
      'CREATE INDEX IF NOT EXISTS idx_pet_messages_source ON pet_messages(source_type, source_range, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_pet_messages_is_read ON pet_messages(is_read)',
      'CREATE INDEX IF NOT EXISTS idx_pet_diaries_diary_date ON pet_diaries(diary_date)',
      'CREATE INDEX IF NOT EXISTS idx_music_tracks_created_at ON music_tracks(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_music_tracks_last_played_at ON music_tracks(last_played_at)',
      'CREATE INDEX IF NOT EXISTS idx_music_tracks_scene_override ON music_tracks(scene_override)',
      'CREATE INDEX IF NOT EXISTS idx_music_playlists_sort ON music_playlists(sort_order, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_music_playlist_tracks_playlist ON music_playlist_tracks(playlist_id, created_at)',
      'CREATE INDEX IF NOT EXISTS idx_music_playlist_tracks_track ON music_playlist_tracks(track_id)',
      'CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_session ON ai_chat_messages(session_id, created_at)',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }

  Future<void> _createKnowledgeV3Tables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_spaces_v3 (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'custom',
        note TEXT NULL,
        icon_asset_key TEXT NULL,
        color_seed TEXT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_materials (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL REFERENCES knowledge_spaces_v3(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'text',
        source_path TEXT NULL,
        url TEXT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ready',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_cards_v3 (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL REFERENCES knowledge_spaces_v3(id) ON DELETE CASCADE,
        material_id INTEGER NULL REFERENCES knowledge_materials(id) ON DELETE SET NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT NULL,
        card_type TEXT NOT NULL DEFAULT 'recall',
        importance INTEGER NOT NULL DEFAULT 3,
        difficulty INTEGER NOT NULL DEFAULT 3,
        source_title TEXT NULL,
        source_excerpt TEXT NULL,
        tags_json TEXT NULL,
        mastery_level INTEGER NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        last_reviewed_at INTEGER NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS knowledge_review_logs_v3 (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL REFERENCES knowledge_cards_v3(id) ON DELETE CASCADE,
        space_id INTEGER NOT NULL REFERENCES knowledge_spaces_v3(id) ON DELETE CASCADE,
        rating INTEGER NOT NULL,
        previous_mastery INTEGER NOT NULL,
        next_mastery INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        reviewed_at INTEGER NOT NULL,
        next_due_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL REFERENCES knowledge_spaces_v3(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        referenced_material_ids_json TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tiantian_qa_messages (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES tiantian_qa_sessions(id) ON DELETE CASCADE,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        sources_json TEXT NULL,
        saved_as_card INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensureKnowledgeV3Schema() async {
    await _ensureColumnExists(
      table: 'knowledge_cards_v3',
      column: 'order_index',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _ensureColumnExists({
    required String table,
    required String column,
    required String definition,
  }) async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(table)],
    ).getSingleOrNull();
    if (exists == null) return;
    final columns = await customSelect('PRAGMA table_info($table)').get();
    final hasColumn = columns.any((row) => row.read<String>('name') == column);
    if (!hasColumn) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }

  Future<void> _seedKnowledgeV3FromLegacy() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final countRow = await customSelect(
      'SELECT COUNT(*) AS count FROM knowledge_spaces_v3',
    ).getSingle();
    final existingCount = countRow.read<int>('count');
    if (existingCount > 0) return;

    final spaceIds = <String, int>{};

    Future<int> ensureSpace(String? key, String? name) async {
      final trimmedName = name?.trim();
      final displayName = trimmedName == null || trimmedName.isEmpty
          ? '默认知识空间'
          : trimmedName;
      final existing = spaceIds[displayName];
      if (existing != null) return existing;

      final id = await customInsert(
        '''
        INSERT INTO knowledge_spaces_v3
          (name, type, note, sort_order, is_archived, created_at, updated_at)
        VALUES (?, ?, ?, ?, 0, ?, ?)
        ''',
        variables: [
          Variable<String>(displayName),
          Variable<String>(_legacySpaceType(key)),
          const Variable<String>('由旧知识卡片数据迁移'),
          Variable<int>(spaceIds.length),
          Variable<int>(now),
          Variable<int>(now),
        ],
      );
      spaceIds[displayName] = id;
      return id;
    }

    final sources = await select(knowledgeSources).get();
    final materialIds = <int, int>{};
    for (final source in sources) {
      final spaceId = await ensureSpace(source.goalKey, source.goalName);
      final chunks =
          await (select(knowledgeChunks)
                ..where((t) => t.sourceId.equals(source.id))
                ..orderBy([(t) => OrderingTerm.asc(t.chunkIndex)]))
              .get();
      final content = chunks
          .map((chunk) => chunk.content.trim())
          .where((item) => item.isNotEmpty)
          .join('\n\n');
      final materialId = await customInsert(
        '''
        INSERT INTO knowledge_materials
          (space_id, title, content, source_type, source_path, status,
           is_archived, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, 'ready', ?, ?, ?)
        ''',
        variables: [
          Variable<int>(spaceId),
          Variable<String>(source.title),
          Variable<String>(content.isEmpty ? source.title : content),
          Variable<String>(source.type),
          Variable<String>(source.sourcePath),
          Variable<int>(source.archived ? 1 : 0),
          Variable<int>(source.createdAt),
          Variable<int>(source.updatedAt),
        ],
      );
      materialIds[source.id] = materialId;
    }

    final cards = await select(knowledgeCards).get();
    for (final card in cards) {
      final spaceId = await ensureSpace(card.goalKey, card.goalName);
      final links =
          await (select(knowledgeCardSourceLinks)
                ..where((t) => t.cardId.equals(card.id))
                ..limit(1))
              .get();
      final link = links.isEmpty ? null : links.first;
      await customInsert(
        '''
        INSERT INTO knowledge_cards_v3
          (space_id, material_id, question, answer, explanation, card_type,
           importance, difficulty, source_title, source_excerpt, tags_json,
           mastery_level, review_count, correct_streak, due_at,
           last_reviewed_at, order_index, is_archived, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, 'recall', 3, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable<int>(spaceId),
          Variable<int>(link == null ? null : materialIds[link.sourceId]),
          Variable<String>(card.question),
          Variable<String>(card.answer),
          Variable<String>(card.explanation),
          Variable<int>(card.masteryLevel <= 1 ? 4 : 3),
          Variable<String>(card.subject ?? card.title),
          Variable<String>(link?.quote),
          Variable<String>(card.tags),
          Variable<int>(card.masteryLevel),
          Variable<int>(card.reviewCount),
          Variable<int>(card.correctStreak),
          Variable<int>(card.dueAt),
          Variable<int>(card.lastReviewedAt),
          Variable<int>(card.id),
          Variable<int>(card.archived ? 1 : 0),
          Variable<int>(card.createdAt),
          Variable<int>(card.updatedAt),
        ],
      );
    }

    if (spaceIds.isEmpty) {
      await customInsert(
        '''
        INSERT INTO knowledge_spaces_v3
          (name, type, note, sort_order, is_archived, created_at, updated_at)
        VALUES ('默认知识空间', 'custom', '从这里开始导入资料，让甜甜帮你生成知识卡。', 0, 0, ?, ?)
        ''',
        variables: [Variable<int>(now), Variable<int>(now)],
      );
    }
  }

  String _legacySpaceType(String? key) {
    final value = key?.trim().toLowerCase();
    if (value == null || value.isEmpty) return 'custom';
    if (value.contains('english') || value.contains('language')) {
      return 'language';
    }
    if (value.contains('civil') ||
        value.contains('kaoyan') ||
        value.contains('exam')) {
      return 'exam';
    }
    if (value.contains('skill') || value.contains('cs')) {
      return 'skill';
    }
    return 'custom';
  }

  // Background index creation support
  bool _indexesReady = false;
  Completer<void>? _indexCompleter;

  Future<void> ensureIndexesReady() async {
    if (_indexesReady) return;

    // 锟斤拷锟斤拷锟斤拷诖锟斤拷锟斤拷锟斤拷却锟斤拷锟斤拷
    if (_indexCompleter != null) {
      return _indexCompleter!.future;
    }

    _indexCompleter = Completer<void>();
    try {
      await _createPerformanceIndexes();
      _indexesReady = true;
      _indexCompleter!.complete();
    } catch (e) {
      debugPrint('Index creation failed (non-fatal): $e');
      _indexCompleter!.completeError(e);
    }
  }
}
