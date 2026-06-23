import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/knowledge/repositories/knowledge_v3_repository.dart';
import 'package:growth_os/core/services/database_health_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> prepareKnowledgeTables() async {
    await KnowledgeV3Repository(db).ensureDefaultSpace();
    await db.ensureIndexesReady();
  }

  test('healthy initialized database has no error-level issues', () async {
    await prepareKnowledgeTables();

    final report = await DatabaseHealthService(
      db,
    ).inspect(checkFilePaths: false);

    expect(report.schemaVersion, db.schemaVersion);
    expect(report.errors, isEmpty);
    expect(report.isHealthy, isTrue);
  });

  test('detects duplicate active knowledge space names', () async {
    await prepareKnowledgeTables();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.customInsert(
      '''
      INSERT INTO knowledge_spaces_v3
        (name, type, note, sort_order, is_archived, created_at, updated_at)
      VALUES (?, 'custom', NULL, 10, 0, ?, ?)
      ''',
      variables: [
        const Variable<String>('Duplicate Space'),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
    await db.customInsert(
      '''
      INSERT INTO knowledge_spaces_v3
        (name, type, note, sort_order, is_archived, created_at, updated_at)
      VALUES (?, 'custom', NULL, 11, 0, ?, ?)
      ''',
      variables: [
        const Variable<String>('Duplicate Space'),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );

    final report = await DatabaseHealthService(
      db,
    ).inspect(checkFilePaths: false);

    expect(
      report.issues.any(
        (issue) =>
            issue.code == 'duplicate_active_knowledge_space_name' &&
            issue.severity == DatabaseHealthSeverity.warning,
      ),
      isTrue,
    );
  });

  test('detects missing avatar file path', () async {
    await prepareKnowledgeTables();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: 'avatar_path',
            value: r'Z:\growth_os_missing_avatar_for_health_test.png',
            updatedAt: now,
          ),
        );

    final report = await DatabaseHealthService(db).inspect();

    expect(
      report.issues.any(
        (issue) =>
            issue.code == 'missing_file_path' &&
            issue.area == DatabaseHealthArea.files &&
            issue.details['key'] == 'avatar_path',
      ),
      isTrue,
    );
  });
}

