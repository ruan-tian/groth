import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/health/providers/sleep_plan_provider.dart';
import 'package:growth_os/shared/providers/database_provider.dart';
import 'package:growth_os/shared/providers/repository_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('initializes with default sleep plan settings', () async {
    final controller = container.read(sleepPlanProvider.notifier);
    await controller.initialize();

    final state = container.read(sleepPlanProvider);
    expect(state.sleepTime, '22:30');
    expect(state.wakeTime, '07:00');
    expect(state.leadMinutes, 30);
    expect(state.reminderTime, '22:00');
    expect(state.targetDurationMinutes, 510);
    expect(state.reminderEnabled, isTrue);
  });

  test('updates target times, lead minutes, and reminder switch', () async {
    final controller = container.read(sleepPlanProvider.notifier);
    await controller.initialize();

    await controller.setSleepTime('23:10');
    await controller.setWakeTime('06:40');
    await controller.setLeadMinutes(45);
    await controller.setReminderEnabled(false);

    final state = container.read(sleepPlanProvider);
    expect(state.sleepTime, '23:10');
    expect(state.wakeTime, '06:40');
    expect(state.leadMinutes, 45);
    expect(state.reminderTime, '22:25');
    expect(state.targetDurationMinutes, 450);
    expect(state.reminderEnabled, isFalse);
  });

  test('ready and wake check-ins create one sleep record', () async {
    final controller = container.read(sleepPlanProvider.notifier);
    await controller.initialize();

    await controller.checkInReady(checkedAt: DateTime(2026, 6, 9, 22, 20));
    final saved = await controller.checkInWake(
      checkedAt: DateTime(2026, 6, 10, 6, 50),
    );

    expect(saved, isTrue);

    final record = await container
        .read(sleepRepositoryProvider)
        .getSleepRecordByDate(DateTime(2026, 6, 9));

    expect(record, isNotNull);
    expect(record!.sleepDate, '2026-06-09');
    expect(record.bedTime, '22:20');
    expect(record.sleepTime, '22:20');
    expect(record.wakeTime, '06:50');
    expect(record.durationMinutes, 510);
    expect(record.qualityLevel, 4);
  });

  test(
    'wake check-in without ready timestamp does not create a record',
    () async {
      final controller = container.read(sleepPlanProvider.notifier);
      await controller.initialize();

      final saved = await controller.checkInWake(
        checkedAt: DateTime(2026, 6, 10, 7),
      );
      final records = await container
          .read(sleepRepositoryProvider)
          .getRecentSleepRecords(limit: 10);

      expect(saved, isFalse);
      expect(records, isEmpty);
      expect(container.read(sleepPlanProvider).wokeAt, isNotNull);
    },
  );
}
