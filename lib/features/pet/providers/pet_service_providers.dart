import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/service_providers.dart';
import '../../../shared/services/settings_write_queue.dart';
import '../../plan/providers/task_provider.dart';
import '../services/pet_diary_data_collector.dart';
import '../services/pet_diary_service.dart';

/// PetDiaryDataCollector Provider.
final petDiaryDataCollectorProvider = Provider<PetDiaryDataCollector>((ref) {
  return PetDiaryDataCollector(
    studyRepo: ref.watch(studyRepositoryProvider),
    fitnessRepo: ref.watch(fitnessRepositoryProvider),
    dietRepo: ref.watch(dietRepositoryProvider),
    sleepRepo: ref.watch(sleepRepositoryProvider),
    taskRepo: ref.watch(dailyTaskRepositoryProvider),
    expRepo: ref.watch(expRepositoryProvider),
    weatherRepo: ref.watch(weatherRepositoryProvider),
  );
});

/// Pet diary generation service Provider.
final petDiaryServiceProvider = Provider<PetDiaryService>((ref) {
  final settingsWriter = SettingsWriteQueue(
    write: ref.read(settingRepositoryProvider).setSetting,
  );
  ref.onDispose(() {
    unawaited(settingsWriter.dispose());
  });
  return PetDiaryService(
    dataCollector: ref.watch(petDiaryDataCollectorProvider),
    diaryRepository: ref.watch(petDiaryRepositoryProvider),
    aiConfigRepository: ref.watch(aiConfigRepositoryProvider),
    settingRepository: ref.watch(settingRepositoryProvider),
    aiService: ref.watch(aiServiceProvider),
    settingWriter: settingsWriter.writeNow,
  );
});
