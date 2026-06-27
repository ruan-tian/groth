import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_providers.dart';
import '../models/study_mode.dart';

/// 番茄钟学习模式（默认高中生）
final focusStudyModeProvider = StateProvider<StudyMode>(
  (ref) => StudyMode.highSchool,
);

/// 从数据库初始化番茄钟学习模式
final focusStudyModeInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingRepositoryProvider);
  final value = await repo.getSetting('focus_study_mode');
  if (value != null) {
    ref.read(focusStudyModeProvider.notifier).state = StudyMode.fromName(value);
  }
});
