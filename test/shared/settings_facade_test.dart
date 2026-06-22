import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/shared/providers/database_provider.dart';
import 'package:growth_os/shared/providers/repository_providers.dart';
import 'package:growth_os/shared/providers/settings_facade.dart';
import 'package:growth_os/shared/providers/settings_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(() => unawaited(db.close()));
          return db;
        }),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('setUserAvatarPath syncs provider and setting row', () async {
    final file = File('${Directory.systemTemp.path}/growth_os_avatar_test.png');
    await file.writeAsBytes(<int>[1, 2, 3]);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    await container.read(settingsFacadeProvider).setUserAvatarPath(file.path);

    expect(container.read(userAvatarPathProvider), file.path);
    expect(
      await container.read(settingRepositoryProvider).getSetting('avatar_path'),
      file.path,
    );
  });

  test('disabling auto AI analysis also disables journal upload', () async {
    final facade = container.read(settingsFacadeProvider);
    await facade.setAutoAiAnalysisEnabled(true);
    await facade.setJournalUploadEnabled(true);

    await facade.setAutoAiAnalysisEnabled(false);

    expect(container.read(autoAiAnalysisProvider), isFalse);
    expect(container.read(journalUploadProvider), isFalse);
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('auto_ai_analysis'),
      'false',
    );
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('journal_upload'),
      'false',
    );
  });
}
