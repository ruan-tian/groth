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
}
