import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';

/// 全局数据库单例 Provider。
///
/// 整个应用共享同一个 [AppDatabase] 实例，由 Riverpod 保证只创建一次。
/// 读取时自动打开数据库连接，应用退出时由框架负责关闭。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  // 后台创建索引，不阻塞初始化
  WidgetsBinding.instance.addPostFrameCallback((_) {
    database.ensureIndexesReady();
  });
  
  ref.onDispose(() => database.close());
  return database;
});

/// [appDatabaseProvider] 的别名，保持向后兼容。
///
/// 新代码应优先使用 [appDatabaseProvider]。
final databaseProvider = appDatabaseProvider;

/// 数据库是否完全就绪（索引创建完成）
final databaseReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await db.ensureIndexesReady();
  return true;
});
