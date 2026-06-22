import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_v3_repository.dart';
import 'package:growth_os/core/services/app_bootstrap_coordinator.dart';
import 'package:growth_os/core/services/database_health_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('bootstraps a fresh database without schema errors', () async {
    final coordinator = AppBootstrapCoordinator(
      database: db,
      knowledgeV3Repository: KnowledgeV3Repository(db),
      databaseHealthService: DatabaseHealthService(db),
    );

    final result = await coordinator.bootstrap();
    final second = await coordinator.bootstrap();

    expect(result.isHealthy, isTrue);
    expect(second, same(result));
    expect(result.databaseHealthReport.errors, isEmpty);
  });
}
