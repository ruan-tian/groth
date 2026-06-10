import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/ai_service.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/study_provider.dart';
import '../../../shared/providers/fitness_provider.dart';
import '../../../shared/providers/diet_provider.dart';
import '../../../shared/providers/sleep_provider.dart';

part '../widgets/ai_analysis_tabs.dart';
part '../widgets/ai_analysis_more_tabs.dart';

// =============================================================================
// Providers
// =============================================================================

/// 当前启用的 AI 配置
final enabledAiConfigProvider = FutureProvider<AiConfig?>((ref) {
  final repo = ref.watch(aiConfigRepositoryProvider);
  return repo.getEnabledAiConfig();
});

/// AI 分析结果状态
final aiAnalysisStateProvider =
    StateNotifierProvider<AiAnalysisNotifier, AiAnalysisState>((ref) {
      return AiAnalysisNotifier();
    });

// =============================================================================
// 状态模型
// =============================================================================

/// AI 分析状态
class AiAnalysisState {
  const AiAnalysisState({this.isLoading = false, this.result, this.error});

  final bool isLoading;
  final String? result;
  final String? error;

  AiAnalysisState copyWith({bool? isLoading, String? result, String? error}) {
    return AiAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// AI 分析状态管理
class AiAnalysisNotifier extends StateNotifier<AiAnalysisState> {
  AiAnalysisNotifier() : super(const AiAnalysisState());

  Future<void> runAnalysis(Future<String> Function() task) async {
    state = const AiAnalysisState(isLoading: true);
    try {
      final result = await task();
      state = AiAnalysisState(result: result);
    } on AiServiceException catch (e) {
      state = AiAnalysisState(error: e.message);
    } catch (e) {
      state = AiAnalysisState(error: '分析失败: $e');
    }
  }

  void updateState(AiAnalysisState newState) {
    state = newState;
  }

  void reset() {
    state = const AiAnalysisState();
  }
}

// =============================================================================
// 页面
// =============================================================================

/// AI 分析页面
///
/// 提供学习分析、健身分析、饮食分析、睡眠分析、成长报告五个 Tab，
/// 每个 Tab 可预览待发送数据并触发 AI 分析。
class AiAnalysisPage extends ConsumerStatefulWidget {
  const AiAnalysisPage({super.key});

  @override
  ConsumerState<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends ConsumerState<AiAnalysisPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // 切换 Tab 时重置分析状态
    ref.read(aiAnalysisStateProvider.notifier).reset();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E1),
      appBar: AppBar(
        title: const Text(
          'AI 分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C3D2E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF5C3D2E),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF5C3D2E),
          unselectedLabelColor: const Color(0xFFB0A09A),
          indicatorColor: const Color(0xFFD4A574),
          tabs: const [
            Tab(text: '学习', icon: Icon(Icons.school, size: 18)),
            Tab(text: '健身', icon: Icon(Icons.fitness_center, size: 18)),
            Tab(text: '饮食', icon: Icon(Icons.restaurant, size: 18)),
            Tab(text: '睡眠', icon: Icon(Icons.bedtime, size: 18)),
            Tab(text: '成长报告', icon: Icon(Icons.auto_graph, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StudyAnalysisTab(),
          _FitnessAnalysisTab(),
          _DietAnalysisTab(),
          _SleepAnalysisTab(),
          _GrowthReportTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// 学习分析 Tab
// =============================================================================
