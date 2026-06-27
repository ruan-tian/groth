import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/health/providers/water_plan_provider.dart';
import 'package:growth_os/shared/providers/database_provider.dart';
import 'package:growth_os/shared/providers/settings_provider.dart';

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

  test('records selected water amount and appends today record', () async {
    final controller = container.read(waterPlanProvider.notifier);
    await controller.initialize();

    controller.selectAmount(500);
    await controller.recordDrink(recordedAt: DateTime(2026, 6, 9, 8, 30));

    final state = container.read(waterPlanProvider);
    final waterMap = container.read(dailyWaterIntakeProvider);

    expect(state.currentWaterMl, 500);
    expect(state.records, hasLength(1));
    expect(state.records.first.amountMl, 500);
    expect(state.records.first.timeLabel, '08:30');
    expect(waterMap['2026-06-09'], 500);
  });

  test('updates goal, default amount, interval, and reminder switch', () async {
    final controller = container.read(waterPlanProvider.notifier);
    await controller.initialize();

    await controller.setGoal(2200);
    await controller.setDefaultAmount(400);
    await controller.setInterval(90);
    await controller.setReminderEnabled(false);

    final state = container.read(waterPlanProvider);

    expect(state.goalMl, 2200);
    expect(state.defaultAmountMl, 400);
    expect(state.selectedAmountMl, 400);
    expect(state.intervalMinutes, 90);
    expect(state.reminderEnabled, isFalse);
    expect(container.read(dailyWaterGoalProvider), 2200);
  });
}

