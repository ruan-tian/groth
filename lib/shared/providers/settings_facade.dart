import 'dart:convert';

import 'package:flutter/material.dart';
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

  Future<void> setUserProfileField(String key, String value) async {
    await _settings.setSetting(key, value);
    switch (key) {
      case 'nickname':
        _ref.read(userNicknameProvider.notifier).state = value;
        _ref.invalidate(userNicknameInitProvider);
        break;
      case 'height':
        _ref.read(userHeightProvider.notifier).state = double.tryParse(value);
        _ref.invalidate(userHeightInitProvider);
        break;
    }
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider(key));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _ref.read(themeModeProvider.notifier).state = mode;
    await _settings.setSetting('theme_mode', mode.name);
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('theme_mode'));
    _ref.invalidate(themeInitProvider);
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

  Future<void> saveGoals(SettingsGoalSnapshot goals) async {
    _ref.read(dailyGoalsProvider.notifier).state = goals.dailyGoals;
    _ref.read(weeklyFitnessGoalProvider.notifier).state =
        goals.weeklyFitnessGoal;
    _ref.read(sleepGoalProvider.notifier).state = goals.sleepGoalHours;
    _ref.read(dailyCalorieGoalProvider.notifier).state = goals.dailyCalorieGoal;
    _ref.read(dailyWaterGoalProvider.notifier).state = goals.dailyWaterGoal;
    _ref.read(targetWeightProvider.notifier).state = goals.targetWeightKg;
    _ref.read(totalStudyHoursProvider.notifier).state = goals.totalStudyHours;

    final entries = <String, String>{
      'daily_goals': jsonEncode(
        goals.dailyGoals.map((goal) => goal.toJson()).toList(),
      ),
      'weekly_fitness_goal': goals.weeklyFitnessGoal.toString(),
      'sleep_goal_hours': goals.sleepGoalHours.toString(),
      'daily_calorie_goal': goals.dailyCalorieGoal.toString(),
      'daily_water_goal': goals.dailyWaterGoal.toString(),
      'target_weight': goals.targetWeightKg.toString(),
      'total_study_hours': goals.totalStudyHours.toString(),
    };

    for (final entry in entries.entries) {
      await _settings.setSetting(entry.key, entry.value);
      _ref.invalidate(settingProvider(entry.key));
    }
    _ref.invalidate(settingsProvider);
    _ref.invalidate(dailyGoalsInitProvider);
    _ref.invalidate(weeklyFitnessGoalInitProvider);
    _ref.invalidate(sleepGoalInitProvider);
    _ref.invalidate(dailyCalorieGoalInitProvider);
    _ref.invalidate(dailyWaterGoalInitProvider);
    _ref.invalidate(targetWeightInitProvider);
    _ref.invalidate(totalStudyHoursInitProvider);
  }
}

class SettingsGoalSnapshot {
  const SettingsGoalSnapshot({
    required this.dailyGoals,
    required this.weeklyFitnessGoal,
    required this.sleepGoalHours,
    required this.dailyCalorieGoal,
    required this.dailyWaterGoal,
    required this.targetWeightKg,
    required this.totalStudyHours,
  });

  final List<DailyGoal> dailyGoals;
  final int weeklyFitnessGoal;
  final int sleepGoalHours;
  final int dailyCalorieGoal;
  final int dailyWaterGoal;
  final double targetWeightKg;
  final int totalStudyHours;
}
