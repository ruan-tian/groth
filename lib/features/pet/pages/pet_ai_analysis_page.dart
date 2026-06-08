import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/pet_scene_provider.dart';
import '../models/pet_ai_result.dart';
import '../models/pet_scene_model.dart';
import '../services/pet_ai_service.dart';
import '../utils/pet_assets.dart';
import '../utils/pet_data_collector.dart';
import '../widgets/pet_ai_data_preview_sheet.dart';
import '../widgets/pet_ai_result_sheet.dart';

class PetAIAnalysisPage extends ConsumerStatefulWidget {
  const PetAIAnalysisPage({super.key, this.initialTab});

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
        final index = widget.initialTab!.clamp(
          0,
          PetAIAnalysisType.values.length - 1,
        );
        _startAnalysis(PetAIAnalysisType.values[index]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PetAIState>(petAIProvider, (previous, current) {
      if (current.result != null && previous?.result != current.result) {
        final type = current.analysisType;
        if (type != null) {
          final module = _moduleFromType(type);
          ref
              .read(petSceneProvider(module).notifier)
              .setReport(
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
      backgroundColor: const Color(0xFFFFF7EF),
      appBar: AppBar(
        title: const Text('甜甜分析'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _AiHeroCard(),
          const SizedBox(height: 16),
          _AnalysisGrid(aiState: aiState, onTap: _startAnalysis),
          const SizedBox(height: 16),
          const _PrivacyCard(),
          if (aiState.isLoading) ...[
            const SizedBox(height: 16),
            const _LoadingCard(),
          ],
          if (aiState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorCard(error: aiState.error!),
          ],
          if (aiState.result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: aiState.result!),
          ],
        ],
      ),
    );
  }

  PetModuleType _moduleFromType(PetAIAnalysisType type) {
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

  Future<void> _startAnalysis(PetAIAnalysisType type) async {
    HapticFeedback.selectionClick();
    final collector = PetDataCollector(ProviderScope.containerOf(ref.context));
    final Map<String, dynamic> data;
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

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard();

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(PetAssets.aiThinking, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '让甜甜读懂你的成长',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  '选择一个方向，先确认数据预览，再生成分析建议。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisGrid extends StatelessWidget {
  const _AnalysisGrid({required this.aiState, required this.onTap});

  final PetAIState aiState;
  final void Function(PetAIAnalysisType type) onTap;

  @override
  Widget build(BuildContext context) {
    final entries = const [
      _AnalysisEntry(
        type: PetAIAnalysisType.study,
        asset: PetAssets.studyReading,
        title: '学习分析',
        subtitle: '节奏、科目和复习建议',
        color: AppColors.study,
      ),
      _AnalysisEntry(
        type: PetAIAnalysisType.fitness,
        asset: PetAssets.fitnessDone,
        title: '健身分析',
        subtitle: '训练量、强度和恢复',
        color: AppColors.fitness,
      ),
      _AnalysisEntry(
        type: PetAIAnalysisType.diet,
        asset: PetAssets.dietPlate,
        title: '饮食分析',
        subtitle: '餐次、饮水和健康评分',
        color: AppColors.diet,
      ),
      _AnalysisEntry(
        type: PetAIAnalysisType.sleep,
        asset: PetAssets.sleepSleeping,
        title: '睡眠分析',
        subtitle: '时长、质量和作息',
        color: AppColors.sleep,
      ),
      _AnalysisEntry(
        type: PetAIAnalysisType.weeklyReport,
        asset: PetAssets.eventWeeklyRpt,
        title: '成长周报',
        subtitle: '一周亮点和调整方向',
        color: AppColors.primary,
      ),
      _AnalysisEntry(
        type: PetAIAnalysisType.monthlyReport,
        asset: PetAssets.eventMonthlyRpt,
        title: '成长月报',
        subtitle: '长期趋势和里程碑',
        color: AppColors.accent,
      ),
    ];

    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(
            asset: PetCenterAssets.decoTarget,
            title: '分析入口',
            subtitle: 'AI 不会自动发送数据，每次都需要你确认',
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.48,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _AnalysisCard(
                entry: entry,
                disabled: aiState.isLoading,
                onTap: () => onTap(entry.type),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.entry,
    required this.disabled,
    required this.onTap,
  });

  final _AnalysisEntry entry;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.58 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: entry.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                entry.asset,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return const _PaperCard(
      child: _Header(
        asset: PetAssets.aiPrivacy,
        title: '隐私确认',
        subtitle: '分析前会弹出数据预览；只有你点击确认后，才会调用已配置的 AI 服务。',
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _PaperCard(
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFFE89B68)),
          SizedBox(height: 14),
          Text(
            '甜甜正在认真分析中...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      child: Row(
        children: [
          Image.asset(PetAssets.aiNetworkError, width: 48, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final PetAIResult result;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => PetAIResultSheet.show(context: context, result: result),
      child: _PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(
              asset: PetAssets.aiReport,
              title: '分析完成',
              subtitle: '点击卡片查看完整建议',
            ),
            const SizedBox(height: 12),
            Text(
              result.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              result.petMessage,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB97A52).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _AnalysisEntry {
  const _AnalysisEntry({
    required this.type,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final PetAIAnalysisType type;
  final String asset;
  final String title;
  final String subtitle;
  final Color color;
}
