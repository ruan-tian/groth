import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'design/design.dart';
import '../shared/providers/settings_provider.dart';

/// Growth OS 应用根 Widget
/// - ProviderScope 由 main.dart 提供
/// - MaterialApp.router + GoRouter + Material 3 主题
class GrowthOSApp extends ConsumerWidget {
  const GrowthOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Growth OS',
      debugShowCheckedModeBanner: false,

      // 主题
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,

      // 路由
      routerConfig: goRouter,
    );
  }
}
