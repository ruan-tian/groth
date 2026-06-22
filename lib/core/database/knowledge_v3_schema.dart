import 'package:drift/drift.dart';

class KnowledgeV3SchemaService {
  KnowledgeV3SchemaService._();

  static const _tableStatements = <String>[
    '''
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
    ''',
    '''
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
    ''',
    '''
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
        memory_hint TEXT NULL,
        related_concepts_json TEXT NULL,
        source_chunk_id TEXT NULL,
        source_locator_json TEXT NULL,
        concept TEXT NULL,
        knowledge_point TEXT NULL,
        exam_scene TEXT NULL,
        common_mistake TEXT NULL,
        grounded INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'auto_approved',
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
    ''',
    '''
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
    ''',
    '''
      CREATE TABLE IF NOT EXISTS tiantian_qa_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL REFERENCES knowledge_spaces_v3(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        referenced_material_ids_json TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS tiantian_qa_messages (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES tiantian_qa_sessions(id) ON DELETE CASCADE,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        sources_json TEXT NULL,
        saved_as_card INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''',
  ];

  static const _cardColumnDefinitions = <String, String>{
    'order_index': 'INTEGER NOT NULL DEFAULT 0',
    'memory_hint': 'TEXT NULL',
    'related_concepts_json': 'TEXT NULL',
    'source_chunk_id': 'TEXT NULL',
    'source_locator_json': 'TEXT NULL',
    'concept': 'TEXT NULL',
    'knowledge_point': 'TEXT NULL',
    'exam_scene': 'TEXT NULL',
    'common_mistake': 'TEXT NULL',
    'grounded': 'INTEGER NOT NULL DEFAULT 1',
    'status': "TEXT NOT NULL DEFAULT 'auto_approved'",
  };

  static Future<void> ensureSchema(GeneratedDatabase db) async {
    await createTables(db);
    await ensureCardColumns(db);
  }

  static Future<void> createTables(GeneratedDatabase db) async {
    for (final statement in _tableStatements) {
      await db.customStatement(statement);
    }
  }

  static Future<void> ensureCardColumns(GeneratedDatabase db) async {
    for (final entry in _cardColumnDefinitions.entries) {
      await ensureColumnExists(
        db,
        table: 'knowledge_cards_v3',
        column: entry.key,
        definition: entry.value,
      );
    }
  }

  static Future<void> ensureColumnExists(
    GeneratedDatabase db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final exists = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable<String>(table)],
        )
        .getSingleOrNull();
    if (exists == null) return;

    final columns = await db.customSelect('PRAGMA table_info($table)').get();
    final hasColumn = columns.any((row) => row.read<String>('name') == column);
    if (hasColumn) return;

    try {
      await db.customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (!message.contains('duplicate column name')) rethrow;
    }
  }
}
