import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature UI files do not write settings directly', () {
    final root = Directory('lib/features');
    final offenders = <String>[];

    for (final file in root.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart')) continue;
      if (!path.contains('/pages/') && !path.contains('/widgets/')) continue;

      final text = file.readAsStringSync();
      if (text.contains('.setSetting(')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'UI code should route setting writes through a facade, provider, '
          'controller, or service so provider state and SQLite writes stay '
          'serialized and synchronized.',
    );
  });

  test('settings subpages do not import providers from settings page', () {
    final root = Directory('lib/features/settings');
    final offenders = <String>[];

    for (final file in root.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('/settings_page.dart')) continue;

      final text = file.readAsStringSync();
      if (text.contains("settings_page.dart' show") ||
          text.contains('settings_page.dart" show')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Settings subpages should read shared providers directly instead of '
          'importing provider declarations from the parent SettingsPage widget.',
    );
  });

  test('settings pages do not access the database provider directly', () {
    final root = Directory('lib/features/settings');
    final offenders = <String>[];

    for (final file in root.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart')) continue;
      if (!path.contains('/pages/') && !path.endsWith('/settings_page.dart')) {
        continue;
      }

      final text = file.readAsStringSync();
      if (text.contains("providers/database_provider.dart") ||
          text.contains('appDatabaseProvider')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Settings UI should use repositories, services, or shared providers '
          'instead of coupling page lifecycle directly to the SQLite database.',
    );
  });

  test('feature UI files do not access the database provider directly', () {
    final root = Directory('lib/features');
    final offenders = <String>[];

    for (final file in root.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart')) continue;
      if (!path.contains('/pages/') && !path.contains('/widgets/')) continue;

      final text = file.readAsStringSync();
      if (text.contains("providers/database_provider.dart") ||
          text.contains('appDatabaseProvider')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Feature UI should depend on repositories, services, or shared '
          'providers instead of binding widget lifecycle directly to SQLite.',
    );
  });
}
