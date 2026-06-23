import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/focus/models/study_mode.dart';
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

  test(
    'setUserProfileField syncs profile providers and setting rows',
    () async {
      final facade = container.read(settingsFacadeProvider);

      await facade.setUserProfileField('nickname', 'Tian');
      await facade.setUserProfileField('height', '172.5');

      expect(container.read(userNicknameProvider), 'Tian');
      expect(container.read(userHeightProvider), 172.5);
      expect(
        await container.read(settingRepositoryProvider).getSetting('nickname'),
        'Tian',
      );
      expect(
        await container.read(settingRepositoryProvider).getSetting('height'),
        '172.5',
      );
    },
  );

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

  test('setThemeMode syncs provider and setting row', () async {
    await container.read(settingsFacadeProvider).setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      await container.read(settingRepositoryProvider).getSetting('theme_mode'),
      'dark',
    );
  });

  test('single setting setters sync providers and setting rows', () async {
    final facade = container.read(settingsFacadeProvider);

    await facade.setDailyCalorieGoal(1900);
    await facade.setSleepGoalHours(7);
    await facade.setWeeklyFitnessGoal(3);
    await facade.setFocusStudyMode(StudyMode.college);

    expect(container.read(dailyCalorieGoalProvider), 1900);
    expect(container.read(sleepGoalProvider), 7);
    expect(container.read(weeklyFitnessGoalProvider), 3);
    expect(container.read(focusStudyModeProvider), StudyMode.college);
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('daily_calorie_goal'),
      '1900',
    );
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('sleep_goal_hours'),
      '7',
    );
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('weekly_fitness_goal'),
      '3',
    );
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('focus_study_mode'),
      StudyMode.college.name,
    );
  });

  test('dashboard card ids are saved through the facade', () async {
    await container.read(settingsFacadeProvider).saveDashboardCardIds([
      'study',
      'sleep',
      'focus',
    ]);

    expect(container.read(dashboardCardIdsProvider), [
      'study',
      'sleep',
      'focus',
    ]);
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('dashboard_cards'),
      '["study","sleep","focus"]',
    );
  });

  test('updateDailyGoal saves new and existing daily goals', () async {
    final facade = container.read(settingsFacadeProvider);
    const stretchName = '\u62c9\u4f38';
    const stretchUnit = '\u5206\u949f';

    await facade.updateDailyGoal(
      name: stretchName,
      target: 10,
      unit: stretchUnit,
    );
    await facade.updateDailyGoal(
      name: stretchName,
      target: 15,
      unit: stretchUnit,
    );

    final goals = container.read(dailyGoalsProvider);
    expect(goals.where((goal) => goal.name == stretchName), hasLength(1));
    expect(goals.firstWhere((goal) => goal.name == stretchName).target, 15);
    expect(
      await container.read(settingRepositoryProvider).getSetting('daily_goals'),
      contains(stretchName),
    );
  });

  test('saveGoals syncs goal providers and setting rows', () async {
    final goals = const SettingsGoalSnapshot(
      dailyGoals: [
        DailyGoal(name: '\u5b66\u4e60', target: 90, unit: '\u5206\u949f'),
        DailyGoal(name: '\u5065\u8eab', target: 40, unit: '\u5206\u949f'),
        DailyGoal(name: '\u5199\u65e5\u8bb0', target: 1, unit: '\u7bc7'),
      ],
      weeklyFitnessGoal: 4,
      sleepGoalHours: 7,
      dailyCalorieGoal: 1800,
      dailyWaterGoal: 2200,
      targetWeightKg: 64,
      totalStudyHours: 1200,
    );

    await container.read(settingsFacadeProvider).saveGoals(goals);

    expect(container.read(dailyGoalsProvider).first.target, 90);
    expect(container.read(weeklyFitnessGoalProvider), 4);
    expect(container.read(sleepGoalProvider), 7);
    expect(container.read(dailyCalorieGoalProvider), 1800);
    expect(container.read(dailyWaterGoalProvider), 2200);
    expect(container.read(targetWeightProvider), 64);
    expect(container.read(totalStudyHoursProvider), 1200);
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('weekly_fitness_goal'),
      '4',
    );
    expect(
      await container
          .read(settingRepositoryProvider)
          .getSetting('daily_water_goal'),
      '2200',
    );
  });
}
