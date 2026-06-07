import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/exp_service.dart';
import '../../core/services/statistics_service.dart';
import 'database_provider.dart';

/// AI 服务 Provider。
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
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
