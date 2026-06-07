import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/pet_scene_provider.dart';
import '../models/pet_ai_result.dart';
import '../models/pet_scene_model.dart';
import '../services/pet_ai_service.dart';
import '../utils/pet_data_collector.dart';
import '../widgets/pet_ai_data_preview_sheet.dart';
import '../widgets/pet_ai_result_sheet.dart';

/// 宠物 AI 分析页面
///
/// 展示 AI 分析入口和历史分析结果。
class PetAIAnalysisPage extends ConsumerStatefulWidget {
  const PetAIAnalysisPage({super.key, this.initialTab});

  /// Initial tab index (0=study, 1=fitness, 2=diet, 3=sleep, 4=weekly, 5=monthly)
  final int? initialTab;

  @override
  ConsumerState<PetAIAnalysisPage> createState() => _PetAIAnalysisPageState();
}

class _PetAIAnalysisPageState extends ConsumerState<PetAIAnalysisPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final type = PetAIAnalysisType.values[widget.initialTab!];
        _startAnalysis(type);
      });
    }
  }

  PetModuleType _getModuleFromType(PetAIAnalysisType type) {
    switch (type) {
      case PetAIAnalysisType.study:
        return PetModuleType.study;
      case PetAIAnalysisType.fitness:
        return PetModuleType.fitness;
      case PetAIAnalysisType.diet:
        return PetModuleType.diet;
      case PetAIAnalysisType.sleep:
        return PetModuleType.sleep;
      case PetAIAnalysisType.weeklyReport:
      case PetAIAnalysisType.monthlyReport:
        return PetModuleType.study;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AI analysis state changes and update pet scene
    ref.listen<PetAIState>(petAIProvider, (previous, current) {
      if (current.result != null && previous?.result != current.result) {
        final type = current.analysisType;
        if (type != null) {
          final module = _getModuleFromType(type);
          ref.read(petSceneProvider(module).notifier).setReport(
                current.result!.petMessage,
                title: current.result!.title,
                highlights: current.result!.highlights,
                suggestions: current.result!.suggestions,
              );
        }
      }
    });

    final aiState = ref.watch(petAIProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('甜甜分析'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部介绍
            _buildHeader(),
            const SizedBox(height: 24),

            // 分析入口
            _buildAnalysisGrid(aiState),
            const SizedBox(height: 24),

            // 分析结果
            if (aiState.isLoading) _buildLoading(),
            if (aiState.error != null) _buildError(aiState.error!),
            if (aiState.result != null) _buildResult(aiState.result!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🐱', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '甜甜成长分析',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '让甜甜帮你分析成长数据，发现亮点和改进方向',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisGrid(PetAIState aiState) {
    final types = [
      _AnalysisEntry(type: PetAIAnalysisType.study, icon: Icons.menu_book_rounded, color: AppColors.study, label: '学习分析'),
      _AnalysisEntry(type: PetAIAnalysisType.fitness, icon: Icons.fitness_center_rounded, color: AppColors.fitness, label: '健身分析'),
      _AnalysisEntry(type: PetAIAnalysisType.diet, icon: Icons.restaurant_rounded, color: AppColors.diet, label: '饮食分析'),
      _AnalysisEntry(type: PetAIAnalysisType.sleep, icon: Icons.bedtime_rounded, color: AppColors.sleep, label: '睡眠分析'),
      _AnalysisEntry(type: PetAIAnalysisType.weeklyReport, icon: Icons.calendar_view_week_rounded, color: AppColors.primary, label: '成长周报'),
      _AnalysisEntry(type: PetAIAnalysisType.monthlyReport, icon: Icons.calendar_month_rounded, color: AppColors.accent, label: '成长月报'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final entry = types[index];
        return _buildAnalysisCard(entry, aiState.isLoading);
      },
    );
  }

  Widget _buildAnalysisCard(_AnalysisEntry entry, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : () => _startAnalysis(entry.type),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(entry.icon, color: entry.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('甜甜正在认真分析中...', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildResult(PetAIResult result) {
    return GestureDetector(
      onTap: () => PetAIResultSheet.show(context: context, result: result),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.petMessage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis(PetAIAnalysisType type) async {
    final collector = PetDataCollector(ProviderScope.containerOf(ref.context));
    Map<String, dynamic> data;
    switch (type) {
      case PetAIAnalysisType.study: data = await collector.collectStudyData(); break;
      case PetAIAnalysisType.fitness: data = await collector.collectFitnessData(); break;
      case PetAIAnalysisType.diet: data = await collector.collectDietData(); break;
      case PetAIAnalysisType.sleep: data = await collector.collectSleepData(); break;
      case PetAIAnalysisType.weeklyReport: data = await collector.collectWeeklyReportData(); break;
      case PetAIAnalysisType.monthlyReport: data = await collector.collectMonthlyReportData(); break;
    }

    if (!mounted) return;

    PetAIDataPreviewSheet.show(
      context: context,
      analysisType: type,
      dataSummary: data,
      onConfirm: () {
        ref.read(petAIProvider.notifier).analyze(type);
      },
    );
  }
}

class _AnalysisEntry {
  const _AnalysisEntry({required this.type, required this.icon, required this.color, required this.label});
  final PetAIAnalysisType type;
  final IconData icon;
  final Color color;
  final String label;
}
