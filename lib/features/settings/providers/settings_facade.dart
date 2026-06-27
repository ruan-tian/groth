import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../focus/models/study_mode.dart';
import '../../../core/repositories/setting_repository.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/settings_provider.dart';

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
        break;
      case 'height':
        _ref.read(userHeightProvider.notifier).state = double.tryParse(value);
        break;
    }
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider(key));
    _ref.invalidate(userProfileSnapshotProvider);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _ref.read(themeModeProvider.notifier).state = mode;
    await _settings.setSetting('theme_mode', mode.name);
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('theme_mode'));
  }

  Future<void> setUserAvatarPath(String? path) async {
    final normalized = normalizeUserAvatarPath(path);
    _ref.read(userAvatarPathProvider.notifier).state = normalized;
    await _settings.setSetting('avatar_path', normalized ?? '');
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('avatar_path'));
    _ref.invalidate(userProfileSnapshotProvider);
  }

  Future<void> setAutoAiAnalysisEnabled(bool enabled) async {
    _ref.read(autoAiAnalysisProvider.notifier).state = enabled;
    await _settings.setSetting('auto_ai_analysis', enabled.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('auto_ai_analysis'));

    if (!enabled) {
      await setJournalUploadEnabled(false);
    }
  }

  Future<void> setJournalUploadEnabled(bool enabled) async {
    _ref.read(journalUploadProvider.notifier).state = enabled;
    await _settings.setSetting('journal_upload', enabled.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('journal_upload'));
  }

  Future<void> saveDashboardCardIds(List<String> ids) async {
    final normalized = ids.toList(growable: false);
    _ref.read(dashboardCardIdsProvider.notifier).state = normalized;
    await _settings.setSetting('dashboard_cards', jsonEncode(normalized));
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('dashboard_cards'));
  }

  Future<void> setDailyGoals(List<DailyGoal> goals) async {
    final normalized = goals.toList(growable: false);
    _ref.read(dailyGoalsProvider.notifier).state = normalized;
    await _settings.setSetting(
      'daily_goals',
      jsonEncode(normalized.map((goal) => goal.toJson()).toList()),
    );
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('daily_goals'));
  }

  Future<void> updateDailyGoal({
    required String name,
    required int target,
    required String unit,
  }) async {
    final goals = _ref.read(dailyGoalsProvider);
    var found = false;
    final next = goals.map((goal) {
      if (goal.name == name) {
        found = true;
        return DailyGoal(name: name, target: target, unit: unit);
      }
      return goal;
    }).toList();
    if (!found) {
      next.add(DailyGoal(name: name, target: target, unit: unit));
    }

    await setDailyGoals(next);
  }

  Future<void> setDailyCalorieGoal(int value) async {
    _ref.read(dailyCalorieGoalProvider.notifier).state = value;
    await _settings.setSetting('daily_calorie_goal', value.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('daily_calorie_goal'));
  }

  Future<void> setSleepGoalHours(int value) async {
    _ref.read(sleepGoalProvider.notifier).state = value;
    await _settings.setSetting('sleep_goal_hours', value.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('sleep_goal_hours'));
  }

  Future<void> setWeeklyFitnessGoal(int value) async {
    _ref.read(weeklyFitnessGoalProvider.notifier).state = value;
    await _settings.setSetting('weekly_fitness_goal', value.toString());
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('weekly_fitness_goal'));
  }

  Future<void> setFocusStudyMode(StudyMode mode) async {
    _ref.read(focusStudyModeProvider.notifier).state = mode;
    await _settings.setSetting('focus_study_mode', mode.name);
    _ref.invalidate(settingsProvider);
    _ref.invalidate(settingProvider('focus_study_mode'));
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
