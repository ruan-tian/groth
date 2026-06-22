import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/app_bootstrap_coordinator.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/database_health_service.dart';
import '../../core/services/exp_service.dart';
import '../../core/services/statistics_service.dart';
import '../../features/ai/services/ai_analysis_card_service.dart';
import '../../features/ai/services/knowledge_context_service.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

// Re-export petDiaryServiceProvider for backward compatibility.
// New code should import from features/pet/providers/pet_service_providers.dart.
export '../../features/pet/providers/pet_service_providers.dart'
    show petDiaryServiceProvider;

/// AI 服务 Provider。
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

/// 本地知识库上下文 Provider。
final knowledgeContextServiceProvider = Provider<KnowledgeContextService>((
  ref,
) {
  return KnowledgeContextService(ref.watch(knowledgeSourceRepositoryProvider));
});

/// AI 分析结果转知识卡服务 Provider。
final aiAnalysisCardServiceProvider = Provider<AiAnalysisCardService>((ref) {
  return const AiAnalysisCardService();
});

/// 经验值计算服务 Provider。
///
/// [ExpService] 为纯计算类，无外部依赖。
final expServiceProvider = Provider<ExpService>((ref) {
  return ExpService();
});

/// 统计服务 Provider。
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatisticsService(db);
});

/// 备份与恢复服务 Provider。
final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db);
});

/// Read-only database diagnostics used by stabilization and support tooling.
final databaseHealthServiceProvider = Provider<DatabaseHealthService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DatabaseHealthService(db);
});

/// Coordinates app startup work that touches shared infrastructure.
final appBootstrapCoordinatorProvider = Provider<AppBootstrapCoordinator>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return AppBootstrapCoordinator(
    database: db,
    knowledgeV3Repository: ref.watch(knowledgeV3RepositoryProvider),
    databaseHealthService: ref.watch(databaseHealthServiceProvider),
  );
});

final appBootstrapProvider = FutureProvider<AppBootstrapResult>((ref) {
  return ref.watch(appBootstrapCoordinatorProvider).bootstrap();
});
