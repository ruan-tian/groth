import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';

/// Shared application database instance.
///
/// Startup work such as index creation is coordinated by
/// `appBootstrapProvider`, not by this low-level provider.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Backward-compatible alias for older code.
final databaseProvider = appDatabaseProvider;

/// Database readiness means performance indexes have been created.
final databaseReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await db.ensureIndexesReady();
  return true;
});
