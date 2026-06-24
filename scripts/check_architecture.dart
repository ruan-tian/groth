import 'dart:io';

/// Growth OS Architecture Guard Script
///
/// Checks:
/// R1: core must not import features
/// R2: shared must not import features (re-exports allowed)
/// R3: pages must not import core/database
/// R4: core/repositories/ legacy re-export inventory
/// R5: shared/providers/ legacy re-export inventory
/// R6: features/*/pages must not use ref.read/watch(databaseProvider)
/// R7: features/*/providers direct databaseProvider usage (warning)
/// R8: feature A must not import feature B internals (whitelist excepted)
///
/// Run: dart scripts/check_architecture.dart
void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib/ directory not found. Run from project root.');
    exit(1);
  }

  var errors = <String>[];
  var warnings = <String>[];
  var legacyItems = <String>[];

  // R1: core -> features (forbidden)
  // Exception: core/services/ files that use constructor injection for feature repositories
  errors.addAll(_checkNoImport(
    directory: 'lib/core',
    forbiddenPattern: RegExp(r'''import\s+['"].*features/'''),
    ruleName: 'R1: core -> features',
    fileFilter: (path) {
      final fileName = path.split(Platform.pathSeparator).last;
      const exceptions = {
        'app_bootstrap_coordinator.dart',
        'weather_service.dart',
      };
      return !exceptions.contains(fileName);
    },
  ));

  // R2: shared -> features (forbidden, re-exports allowed)
  // Exception: repository_providers.dart, knowledge_source_provider.dart, knowledge_v3_provider.dart
  // are infrastructure files that create global providers for feature repositories.
  errors.addAll(_checkNoImport(
    directory: 'lib/shared',
    forbiddenPattern: RegExp(r'''import\s+['"].*features/'''),
    ruleName: 'R2: shared -> features',
    fileFilter: (path) {
      final fileName = path.split(Platform.pathSeparator).last;
      const exceptions = {
        'repository_providers.dart',
        'knowledge_source_provider.dart',
        'knowledge_v3_provider.dart',
      };
      return !exceptions.contains(fileName);
    },
  ));

  // R3: pages -> core/database (warning for type imports, error for direct DB access)
  // Type imports (Drift data classes/Companion) are acceptable as warning inventory.
  // Direct DB access (ref.read/watch(databaseProvider), db.transaction) is error.
  warnings.addAll(_checkNoImport(
    directory: 'lib/features',
    forbiddenPattern: RegExp(r'''import\s+['"].*core/database/'''),
    ruleName: 'R3: pages -> core/database (type import)',
    fileFilter: (path) => _normalized(path).contains('/pages/'),
  ));

  // R4: core/repositories/ legacy re-export inventory
  legacyItems.addAll(_checkLegacyRepos());

  // R5: shared/providers/ legacy re-export inventory
  legacyItems.addAll(_checkLegacyProviders());

  // R6: features/*/pages must not use ref.read/watch(databaseProvider)
  errors.addAll(_checkPagesDbAccess());

  // R7: features/*/providers direct databaseProvider usage (warning)
  warnings.addAll(_checkProvidersDbAccess());

  // R8: feature A -> feature B (whitelist excepted)
  errors.addAll(_checkCrossFeatureImport());

  // Report
  print('=== Growth OS Architecture Check ===\n');

  if (errors.isEmpty && warnings.isEmpty && legacyItems.isEmpty) {
    print('No violations found!');
  } else {
    if (errors.isNotEmpty) {
      print('ERRORS (${errors.length}):\n');
      for (final v in errors) {
        print('  [ERROR] $v');
      }
      print('');
    }
    if (warnings.isNotEmpty) {
      print('WARNINGS (${warnings.length}):\n');
      for (final v in warnings) {
        print('  [WARN]  $v');
      }
      print('');
    }
    if (legacyItems.isNotEmpty) {
      print('LEGACY RE-EXPORTS (${legacyItems.length}):\n');
      for (final v in legacyItems) {
        print('  [LEGACY] $v');
      }
      print('');
    }
  }

  // Only errors cause exit code 1; warnings and legacy are informational
  exit(errors.isEmpty ? 0 : 1);
}

// ─── Rules R1-R3: Forbidden import check ─────────────────────────────────────

List<String> _checkNoImport({
  required String directory,
  required RegExp forbiddenPattern,
  required String ruleName,
  bool Function(String path)? fileFilter,
}) {
  final violations = <String>[];
  final dir = Directory(directory);

  if (!dir.existsSync()) return violations;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (fileFilter != null && !fileFilter(entity.path)) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
        continue; // Skip comments
      }
      if (line.trim().startsWith('export ')) {
        continue; // Skip re-exports (allowed)
      }
      if (forbiddenPattern.hasMatch(line)) {
        final relativePath = _relative(entity.path);
        violations.add('$ruleName: $relativePath:${i + 1} -- ${line.trim()}');
      }
    }
  }

  return violations;
}

// ─── R4: core/repositories/ legacy re-export ─────────────────────────────────

List<String> _checkLegacyRepos() {
  final legacy = <String>[];
  final dir = Directory('lib/core/repositories');

  if (!dir.existsSync()) return legacy;

  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final fileName = entity.path.split(Platform.pathSeparator).last;
    if (fileName == 'setting_repository.dart') continue;

    // Check if it is a pure re-export file
    final content = entity.readAsStringSync();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final isReExport = lines.every(
      (l) => l.trim().startsWith('//') || l.trim().startsWith('export '),
    );

    if (isReExport) {
      legacy.add('core/repositories/$fileName -> re-export (migrate to features/)');
    }
  }

  return legacy;
}

// ─── R5: shared/providers/ legacy re-export ──────────────────────────────────

List<String> _checkLegacyProviders() {
  final legacy = <String>[];
  final dir = Directory('lib/shared/providers');

  if (!dir.existsSync()) return legacy;

  // Global providers allowed to stay in shared/providers/
  const globalProviders = {
    'database_provider.dart',
    'settings_provider.dart',
    'app_lifecycle_provider.dart',
    'current_date_provider.dart',
    'focus_audio_provider.dart',
    'repository_providers.dart',
    'service_providers.dart',
    'settings_facade.dart',
  };

  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final fileName = entity.path.split(Platform.pathSeparator).last;
    if (globalProviders.contains(fileName)) continue;

    // Check if it is a pure re-export file
    final content = entity.readAsStringSync();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final isReExport = lines.every(
      (l) => l.trim().startsWith('//') || l.trim().startsWith('export '),
    );

    if (isReExport) {
      legacy.add('shared/providers/$fileName -> re-export (migrate to features/)');
    }
  }

  return legacy;
}

// ─── R6: features/*/pages must not use ref.read/watch(databaseProvider) ──────

List<String> _checkPagesDbAccess() {
  final violations = <String>[];
  final featuresDir = Directory('lib/features');

  if (!featuresDir.existsSync()) return violations;

  final dbPattern = RegExp(
    r'''ref\.(read|watch)\s*\(\s*(databaseProvider|appDatabaseProvider)\s*\)''',
  );

  for (final entity in featuresDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (!_normalized(entity.path).contains('/pages/')) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('//')) continue;
      if (dbPattern.hasMatch(line)) {
        final relativePath = _relative(entity.path);
        violations.add(
          'R6: pages direct DB access: $relativePath:${i + 1} -- ${line.trim()}',
        );
      }
    }
  }

  return violations;
}

// ─── R7: features/*/providers direct databaseProvider (warning) ──────────────
// Only warns about direct DB queries, not repository creation patterns

List<String> _checkProvidersDbAccess() {
  final warnings = <String>[];
  final featuresDir = Directory('lib/features');

  if (!featuresDir.existsSync()) return warnings;

  final dbPattern = RegExp(
    r'''ref\.(read|watch)\s*\(\s*(databaseProvider|appDatabaseProvider)\s*\)''',
  );

  // Exclude repository creation patterns like: return XxxRepository(ref.watch(databaseProvider))
  final repoCreationPattern = RegExp(
    r'''Repository\s*\(\s*ref\.(read|watch)\s*\(\s*(databaseProvider|appDatabaseProvider)\s*\)\s*\)''',
  );

  for (final entity in featuresDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (!_normalized(entity.path).contains('/providers/')) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('//')) continue;
      if (dbPattern.hasMatch(line) && !repoCreationPattern.hasMatch(line)) {
        final relativePath = _relative(entity.path);
        warnings.add(
          'R7: provider direct DB access: $relativePath:${i + 1} -- ${line.trim()}',
        );
      }
    }
  }

  return warnings;
}

// ─── R8: feature A -> feature B (whitelist excepted) ─────────────────────────

List<String> _checkCrossFeatureImport() {
  final violations = <String>[];
  final featuresDir = Directory('lib/features');

  if (!featuresDir.existsSync()) return violations;

  // Get all feature directories
  final featureDirs = featuresDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .toList();

  // Whitelist: allowed cross-feature dependencies
  // key: source feature, value: allowed target path prefixes
  const whitelist = <String, List<String>>{
    'ai': ['services', 'providers'],
    'focus': ['models', 'providers', 'utils'], // White noise - FocusMusicFacade created, to be integrated
    'dashboard': ['utils', 'pages', 'providers'], // Quick actions - DashboardQuickActions created
    'settings': ['utils'], // Avatar assets - acceptable
    'fitness': ['providers'], // Dashboard refresh - FitnessDashboardFacade created
  };

  // Legacy exception files (documented, to be refactored later)
  // AI analysis page now uses AiAnalysisInputFacade for cross-module data
  const legacyExceptions = {
    'features/ai/pages/ai_analysis_page.dart',
  };

  for (final feature in featureDirs) {
    final featurePath = '${featuresDir.path}/$feature';
    final allowedTargets = whitelist[feature] ?? [];

    for (final entity in Directory(featurePath).listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final relativePath = _relative(entity.path);

      // Skip legacy exceptions
      if (legacyExceptions.contains(relativePath)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
          continue;
        }
        if (line.trim().startsWith('export ')) continue;

        // Check if importing another feature
        final importMatch =
            RegExp(r'''import\s+['"].*features/(\w+)/(.*)['"]''').firstMatch(line);
        if (importMatch == null) continue;

        final targetFeature = importMatch.group(1)!;
        final targetPath = importMatch.group(2)!;

        // Self-import is OK
        if (targetFeature == feature) continue;

        // Check whitelist
        final isWhitelisted = allowedTargets.any((prefix) {
          if (prefix.isEmpty) return false;
          // Support wildcard features/*/providers
          if (prefix.contains('*')) {
            final pattern = prefix.replaceAll('*', r'\w+');
            return RegExp('^$pattern').hasMatch(targetPath);
          }
          return targetPath.startsWith(prefix);
        });

        if (!isWhitelisted) {
          violations.add(
            'R8: cross-feature: $relativePath:${i + 1} -> $feature -> $targetFeature/$targetPath',
          );
        }
      }
    }
  }

  return violations;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Normalize path separators to forward slash (for Windows compatibility)
String _normalized(String path) => path.replaceAll('\\', '/');

String _relative(String path) {
  return _normalized(path).replaceFirst(RegExp(r'^\.?/?'), '');
}
