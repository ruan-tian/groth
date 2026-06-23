import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/database/knowledge_v3_schema.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_v3_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> columns(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test('ensureSchema creates the complete Knowledge V3 schema', () async {
    await KnowledgeV3SchemaService.ensureSchema(db);

    final tableRows = await db.customSelect('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table'
            AND name IN (
              'knowledge_spaces_v3',
              'knowledge_materials',
              'knowledge_cards_v3',
              'knowledge_review_logs_v3',
              'tiantian_qa_sessions',
              'tiantian_qa_messages'
            )
          ''').get();
    expect(tableRows, hasLength(6));

    final cardColumns = await columns('knowledge_cards_v3');
    expect(cardColumns, contains('source_chunk_id'));
    expect(cardColumns, contains('source_locator_json'));
    expect(cardColumns, contains('grounded'));
    expect(cardColumns, contains('status'));
    expect(cardColumns, contains('order_index'));
  });

  test('ensureSchema backfills missing Knowledge V3 card columns', () async {
    await db.customStatement('''
      CREATE TABLE knowledge_cards_v3 (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        space_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        due_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await KnowledgeV3SchemaService.ensureSchema(db);

    final cardColumns = await columns('knowledge_cards_v3');
    expect(cardColumns, contains('source_chunk_id'));
    expect(cardColumns, contains('related_concepts_json'));
    expect(cardColumns, contains('common_mistake'));
    expect(cardColumns, contains('grounded'));
    expect(cardColumns, contains('status'));
  });

  test('repository still creates the default knowledge space', () async {
    final space = await KnowledgeV3Repository(db).ensureDefaultSpace();

    expect(space.name, '\u9ed8\u8ba4\u77e5\u8bc6\u7a7a\u95f4');
  });

  test('ensureDefaultSpace does not reuse an arbitrary user space', () async {
    final repo = KnowledgeV3Repository(db);
    final customId = await repo.createSpace(name: 'Custom Space');

    final defaultSpace = await repo.ensureDefaultSpace();

    expect(defaultSpace.id, isNot(customId));
    expect(defaultSpace.name, '\u9ed8\u8ba4\u77e5\u8bc6\u7a7a\u95f4');
  });
}

