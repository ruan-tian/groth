import 'dart:io';

/// Growth OS 架构守卫脚本
///
/// 检查代码库是否遵守架构规则：
/// 1. core 不允许 import features
/// 2. shared 不允许 import features（re-export 除外）
/// 3. pages 不允许直接 import core/database
///
/// 运行方式：dart scripts/check_architecture.dart
void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib/ directory not found. Run from project root.');
    exit(1);
  }

  var violations = <String>[];

  // Rule 1: core -> features (禁止)
  violations.addAll(_checkNoImport(
    directory: 'lib/core',
    forbiddenPattern: RegExp(r'''import\s+['"].*features/'''),
    ruleName: 'core -> features',
  ));

  // Rule 2: shared -> features (禁止，re-export 除外)
  violations.addAll(_checkNoImport(
    directory: 'lib/shared',
    forbiddenPattern: RegExp(r'''import\s+['"].*features/'''),
    ruleName: 'shared -> features',
  ));

  // Rule 3: pages -> core/database (禁止)
  violations.addAll(_checkNoImport(
    directory: 'lib/features',
    forbiddenPattern: RegExp(r'''import\s+['"].*core/database/'''),
    ruleName: 'pages -> core/database',
    fileFilter: (path) => path.contains('/pages/'),
  ));

  // Report
  print('=== Growth OS Architecture Check ===\n');

  if (violations.isEmpty) {
    print('No violations found!');
  } else {
    print('Found ${violations.length} violation(s):\n');
    for (final v in violations) {
      print('  - $v');
    }
  }

  exit(violations.isEmpty ? 0 : 1);
}

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
        final relativePath = entity.path.replaceAll('\\', '/');
        violations.add('$ruleName: $relativePath:${i + 1} -- ${line.trim()}');
      }
    }
  }

  return violations;
}
