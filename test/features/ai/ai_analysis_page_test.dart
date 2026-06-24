import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/ai/pages/ai_analysis_page.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('AiAnalysisNotifier.runAnalysis sets result on success', () async {
    final notifier = AiAnalysisNotifier();
    await notifier.runAnalysis(() async => '分析结果');

    expect(notifier.state.result, '分析结果');
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNull);
  });

  test('AiAnalysisNotifier.runAnalysis sets error on failure', () async {
    final notifier = AiAnalysisNotifier();
    await notifier.runAnalysis(() async => throw Exception('boom'));

    expect(notifier.state.error, isNotNull);
    expect(notifier.state.result, isNull);
  });

  test('AiAnalysisNotifier.reset clears state', () async {
    final notifier = AiAnalysisNotifier();
    await notifier.runAnalysis(() async => '分析结果');
    notifier.reset();

    expect(notifier.state.result, isNull);
    expect(notifier.state.isLoading, isFalse);
  });
}
