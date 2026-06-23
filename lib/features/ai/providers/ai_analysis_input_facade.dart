import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../health/providers/diet_provider.dart';
import '../../health/providers/sleep_provider.dart';
import '../../study/providers/study_provider.dart';

/// Aggregated data for AI analysis across all modules.
///
/// This facade collects data from study, fitness, diet, sleep, and dashboard
/// modules so that the AI analysis page only needs to depend on this single
/// provider instead of importing 5 different module providers.
class AiAnalysisInputData {
  const AiAnalysisInputData({
    required this.studyRecords,
    required this.fitnessRecords,
    required this.dietRecords,
    required this.sleepRecords,
    required this.dashboard,
    required this.weeklyAvgSleepDuration,
    required this.weeklyAvgSleepQuality,
  });

  final List<StudyRecord> studyRecords;
  final List<FitnessRecord> fitnessRecords;
  final List<DietRecord> dietRecords;
  final List<SleepRecord> sleepRecords;
  final DashboardData dashboard;
  final double weeklyAvgSleepDuration;
  final double weeklyAvgSleepQuality;
}

/// Provider that aggregates data from all modules for AI analysis.
final aiAnalysisInputProvider = FutureProvider<AiAnalysisInputData>((ref) async {
  final studyRecords = await ref.watch(recentStudyRecordsProvider.future);
  final fitnessRecords = await ref.watch(recentFitnessRecordsProvider.future);
  final dietRecords = await ref.watch(recentDietRecordsProvider(10).future);
  final sleepRecords = await ref.watch(recentSleepRecordsProvider(7).future);
  final dashboard = await ref.watch(dashboardProvider.future);
  final weeklyAvgSleepDuration = await ref.watch(weeklyAvgSleepDurationProvider.future) ?? 0;
  final weeklyAvgSleepQuality = await ref.watch(weeklyAvgSleepQualityProvider.future) ?? 0;

  return AiAnalysisInputData(
    studyRecords: studyRecords,
    fitnessRecords: fitnessRecords,
    dietRecords: dietRecords,
    sleepRecords: sleepRecords,
    dashboard: dashboard,
    weeklyAvgSleepDuration: weeklyAvgSleepDuration,
    weeklyAvgSleepQuality: weeklyAvgSleepQuality,
  );
});
