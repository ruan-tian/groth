import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/domain/pet/pet_ai_result.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../utils/pet_data_collector.dart';
import '../utils/pet_prompt_builder.dart';
import '../utils/pet_ai_result_parser.dart';
import 'pet_ai_privacy_guard.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/providers/pet_ai_result_provider.dart';

/// 宠物 AI 分析状态
class PetAIState {
  const PetAIState({
    this.isLoading = false,
    this.result,
    this.error,
    this.analysisType,
  });

  final bool isLoading;
  final PetAIResult? result;
  final String? error;
  final PetAIAnalysisType? analysisType;

  PetAIState copyWith({
    bool? isLoading,
    PetAIResult? result,
    String? error,
    PetAIAnalysisType? analysisType,
  }) {
    return PetAIState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
      analysisType: analysisType ?? this.analysisType,
    );
  }
}

/// 宠物 AI 状态管理
class PetAINotifier extends StateNotifier<PetAIState> {
  PetAINotifier(this._ref) : super(const PetAIState());

  final Ref _ref;

  /// 执行 AI 分析
  Future<void> analyze(PetAIAnalysisType type) async {
    state = PetAIState(isLoading: true, analysisType: type);
    final moduleName = _getSourceType(type);
    PetEventBus.instance.emit(
      PetEvent(
        eventId: 'ai_start_${DateTime.now().millisecondsSinceEpoch}',
        source: PetEventSource.ai,
        type: PetEventType.aiAnalysisStarted,
        module: moduleName,
      ),
    );

    try {
      // 获取 AI 配置
      final aiConfigRepo = _ref.read(aiConfigRepositoryProvider);
      final config = await aiConfigRepo.getEnabledAiConfig();
      if (config == null) {
        if (!mounted) return;
        state = const PetAIState(error: '未配置 AI 服务，请先在设置中配置 AI API。');
        return;
      }

      // 收集数据
      final collector = PetDataCollector(_ref.container);
      var data = <String, dynamic>{};
      switch (type) {
        case PetAIAnalysisType.study:
          data = await collector.collectStudyData();
          break;
        case PetAIAnalysisType.fitness:
          data = await collector.collectFitnessData();
          break;
        case PetAIAnalysisType.diet:
          data = await collector.collectDietData();
          break;
        case PetAIAnalysisType.sleep:
          data = await collector.collectSleepData();
          break;
        case PetAIAnalysisType.weeklyReport:
          data = await collector.collectWeeklyReportData();
          break;
        case PetAIAnalysisType.monthlyReport:
          data = await collector.collectMonthlyReportData();
          break;
      }

      // 隐私脱敏
      final journalUpload = _ref.read(journalUploadProvider);
      data = PetAIPrivacyGuard.instance.sanitize(
        data: data,
        journalUploadEnabled: journalUpload,
      );

      // 调用 AI
      final aiService = _ref.read(aiServiceProvider);
      final systemPrompt = PetPromptBuilder.buildSystemPrompt();
      final userPrompt = PetPromptBuilder.buildUserPrompt(
        type: type,
        data: data,
      );

      final raw = await aiService.callApi(
        apiKey: config.apiKey,
        baseUrl: config.baseUrl,
        model: config.modelName,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      // 解析结果
      final result = PetAIResultParser.parse(raw, type: type);

      // 保存到数据库
      final db = _ref.read(databaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.petMessages)
          .insert(
            PetMessagesCompanion.insert(
              type: 'analysis',
              title: result.title,
              content: result.summary,
              petMessage: result.petMessage,
              sourceType: _getSourceType(type),
              sourceRange: const Value('last_7_days'),
              createdAt: now,
              highlights: Value(result.highlights.join('|||')),
              risks: Value(result.risks.join('|||')),
              suggestions: Value(result.suggestions.join('|||')),
            ),
          );

      // Invalidate the latest analysis provider so it refreshes
      _ref.invalidate(latestPetAnalysisProvider(_getSourceType(type)));

      if (!mounted) return;
      state = PetAIState(result: result, analysisType: type);
      PetEventBus.instance.emit(
        PetEvent.aiCompleted(
          eventId: 'ai_done_${DateTime.now().millisecondsSinceEpoch}',
          module: moduleName,
          shortMessage: result.petMessage,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      state = PetAIState(error: '分析失败，请重试', analysisType: type);
      PetEventBus.instance.emit(
        PetEvent(
          eventId: 'ai_fail_${DateTime.now().millisecondsSinceEpoch}',
          source: PetEventSource.ai,
          type: PetEventType.aiAnalysisFailed,
          module: moduleName,
          payload: {'error': e.toString()},
        ),
      );
    }
  }

  /// 流式 AI 分析
  ///
  /// 返回一个 Stream，逐步输出 AI 的回复内容。
  /// 适用于需要实时显示 AI 回复的场景。
  Stream<String> analyzeStream(PetAIAnalysisType type) async* {
    final aiConfigRepo = _ref.read(aiConfigRepositoryProvider);
    final config = await aiConfigRepo.getEnabledAiConfig();
    if (config == null) {
      throw Exception('未配置 AI 服务，请先在设置中配置 AI API。');
    }

    final collector = PetDataCollector(_ref.container);
    var data = <String, dynamic>{};
    switch (type) {
      case PetAIAnalysisType.study:
        data = await collector.collectStudyData();
        break;
      case PetAIAnalysisType.fitness:
        data = await collector.collectFitnessData();
        break;
      case PetAIAnalysisType.diet:
        data = await collector.collectDietData();
        break;
      case PetAIAnalysisType.sleep:
        data = await collector.collectSleepData();
        break;
      case PetAIAnalysisType.weeklyReport:
        data = await collector.collectWeeklyReportData();
        break;
      case PetAIAnalysisType.monthlyReport:
        data = await collector.collectMonthlyReportData();
        break;
    }

    // 隐私脱敏
    final journalUpload = _ref.read(journalUploadProvider);
    data = PetAIPrivacyGuard.instance.sanitize(
      data: data,
      journalUploadEnabled: journalUpload,
    );

    final aiService = _ref.read(aiServiceProvider);
    final systemPrompt = PetPromptBuilder.buildSystemPrompt();
    final userPrompt = PetPromptBuilder.buildUserPrompt(type: type, data: data);

    yield* aiService.streamApi(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      model: config.modelName,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );
  }

  /// 重置状态
  void reset() {
    state = const PetAIState();
  }

  String _getSourceType(PetAIAnalysisType type) {
    switch (type) {
      case PetAIAnalysisType.study:
        return 'study';
      case PetAIAnalysisType.fitness:
        return 'fitness';
      case PetAIAnalysisType.diet:
        return 'diet';
      case PetAIAnalysisType.sleep:
        return 'sleep';
      case PetAIAnalysisType.weeklyReport:
      case PetAIAnalysisType.monthlyReport:
        return 'growth';
    }
  }
}

/// 宠物 AI Provider
final petAIProvider = StateNotifierProvider<PetAINotifier, PetAIState>((ref) {
  return PetAINotifier(ref);
});
