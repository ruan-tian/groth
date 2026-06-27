import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/record_icon_assets.dart';
import '../../../core/database/app_database.dart' show AiConfig;
import '../../../core/services/ai_service.dart';
import '../../../shared/widgets/common/record_detail_sheet.dart';
// ignore: unused_import — used by ai_analysis_tabs.dart part file
import '../../knowledge/repositories/knowledge_source_repository.dart';
// ignore: unused_import — used by ai_analysis_tabs.dart part file
import '../../knowledge/services/knowledge_context_service.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../knowledge/services/knowledge_card_ai_service.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../knowledge/providers/knowledge_card_ai_provider.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../knowledge/providers/knowledge_card_provider.dart';
import '../providers/ai_analysis_input_facade.dart';
import '../../dashboard/providers/dashboard_provider.dart';
// ignore: unused_import — used by ai_analysis_tabs.dart part file
import '../../study/providers/study_provider.dart';
// ignore: unused_import — used by ai_analysis_tabs.dart part file
import '../../fitness/providers/fitness_provider.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../health/providers/diet_provider.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../health/providers/sleep_provider.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../knowledge/models/knowledge_data.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../dashboard/models/dashboard_data.dart';
// ignore: unused_import — used by ai_analysis_tabs.dart part file
import '../../study/models/study_data.dart';
// ignore: unused_import — used by ai_analysis_tabs.dart part file
import '../../fitness/models/fitness_data.dart';
// ignore: unused_import — used by ai_analysis_more_tabs.dart part file
import '../../health/models/health_data.dart';

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
  const AiAnalysisState({
    this.isLoading = false,
    this.isStreaming = false,
    this.partialResult,
    this.result,
    this.error,
  });

  final bool isLoading;
  final bool isStreaming;
  final String? partialResult;
  final String? result;
  final String? error;

  AiAnalysisState copyWith({
    bool? isLoading,
    bool? isStreaming,
    String? partialResult,
    String? result,
    String? error,
  }) {
    return AiAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      partialResult: partialResult ?? this.partialResult,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// AI 分析状态管理
class AiAnalysisNotifier extends StateNotifier<AiAnalysisState> {
  AiAnalysisNotifier() : super(const AiAnalysisState());

  Future<void> runAnalysis(
    Future<String> Function() task,
  ) async {
    state = const AiAnalysisState(isLoading: true);
    try {
      final result = await task();
      state = AiAnalysisState(result: result);
    } on AiServiceException catch (e) {
      state = AiAnalysisState(error: e.message);
    } catch (e) {
      state = AiAnalysisState(error: '分析失败，请重试');
    }
  }

  Future<void> runStreamAnalysis(
    Stream<String> Function() task,
  ) async {
    state = const AiAnalysisState(isLoading: true);
    try {
      final buffer = StringBuffer();
      await for (final delta in task()) {
        buffer.write(delta);
        state = state.copyWith(
          isLoading: false,
          isStreaming: true,
          partialResult: buffer.toString(),
        );
      }
      state = AiAnalysisState(result: buffer.toString());
    } on AiServiceException catch (e) {
      state = AiAnalysisState(error: e.message);
    } catch (e) {
      state = AiAnalysisState(error: '分析失败，请重试');
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
    final colors = context.growthColors;
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text('AI 分析', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 自定义 Tab 区域
          _buildTabBar(context, colors),
          // 1px 分割线
          Container(height: 1, color: const Color(0xFFE8E4DA)),
          // 甜甜横幅
          _buildPetBanner(context, colors),
          // Tab 内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _StudyAnalysisTab(),
                _FitnessAnalysisTab(),
                _DietAnalysisTab(),
                _SleepAnalysisTab(),
                _GrowthReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, AppThemeColors colors) {
    const activeColor = Color(0xFF4D6BE8);
    const inactiveColor = Color(0xFF8A92A3);
    const tabs = [
      _TabData(Icons.school_rounded, '学习'),
      _TabData(Icons.fitness_center_rounded, '健身'),
      _TabData(Icons.restaurant_rounded, '饮食'),
      _TabData(Icons.bedtime_rounded, '睡眠'),
      _TabData(Icons.auto_graph_rounded, '成长报告'),
    ];

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final index = _tabController.index;
        final animationValue = _tabController.animation?.value ?? index.toDouble();
        return Container(
          height: 88,
          color: colors.paper,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = i == index;
              // 计算与当前 tab 的距离，用于渐变效果
              final distance = (animationValue - i).abs();
              final t = (1.0 - distance).clamp(0.0, 1.0);
              final interpolatedColor = Color.lerp(inactiveColor, activeColor, t)!;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tabs[i].icon, size: 26, color: interpolatedColor),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: interpolatedColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildPetBanner(BuildContext context, AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEFE7DB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A172033),
              offset: Offset(0, 6),
              blurRadius: 20,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '甜甜分析助手 ✨',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '我帮你整理好了最近的学习数据',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/ai/ai_assistant_pet.webp',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.pets_rounded,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData(this.icon, this.label);
  final IconData icon;
  final String label;
}

// =============================================================================
// 学习分析 Tab
// =============================================================================
