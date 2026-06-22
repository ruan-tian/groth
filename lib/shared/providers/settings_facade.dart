import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/setting_repository.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

final settingsFacadeProvider = Provider<SettingsFacade>((ref) {
  return SettingsFacade(ref, ref.watch(settingRepositoryProvider));
});

class SettingsFacade {
  SettingsFacade(this._ref, this._settings);

  final Ref _ref;
  final SettingRepository _settings;

  Future<void> setString(String key, String value) async {
    await _settings.setSetting(key, value);
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider(key));
  }

  Future<void> setUserAvatarPath(String? path) async {
    final normalized = normalizeUserAvatarPath(path);
    _ref.read(userAvatarPathProvider.notifier).state = normalized;
    await _settings.setSetting('avatar_path', normalized ?? '');
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('avatar_path'));
    _ref.invalidate(userAvatarInitProvider);
  }

  Future<void> setAutoAiAnalysisEnabled(bool enabled) async {
    _ref.read(autoAiAnalysisProvider.notifier).state = enabled;
    await _settings.setSetting('auto_ai_analysis', enabled.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('auto_ai_analysis'));
    _ref.invalidate(autoAiAnalysisInitProvider);

    if (!enabled) {
      await setJournalUploadEnabled(false);
    }
  }

  Future<void> setJournalUploadEnabled(bool enabled) async {
    _ref.read(journalUploadProvider.notifier).state = enabled;
    await _settings.setSetting('journal_upload', enabled.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('journal_upload'));
    _ref.invalidate(journalUploadInitProvider);
  }
}
