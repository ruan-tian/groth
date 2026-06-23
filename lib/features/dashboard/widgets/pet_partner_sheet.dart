import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/pet_assets.dart';
import '../../../core/database/app_database.dart';
import '../../pet/providers/pet_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/domain/pet/pet_ai_result.dart';
import '../../pet/utils/pet_data_collector.dart';
import '../../pet/widgets/pet_ai_data_preview_sheet.dart';
import '../../pet/pages/pet_ai_analysis_page.dart';
import '../../../shared/widgets/common/error_retry_widget.dart';

/// 宠物伙伴详情底部弹窗
///
/// 白色20px圆角矩形弹窗，展示：
/// - 猫咪头像占位 + 等级 + 亲密度条
/// - 今日心情显示
/// - AI小语文本框（浅灰色背景）
/// - 本周成长亮点数据
/// - 底部"查看详细分析"按钮
class PetPartnerSheet extends ConsumerWidget {
  const PetPartnerSheet({super.key});

  /// 显示宠物伙伴详情弹窗
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PetPartnerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final petProfile = ref.watch(petProfileProvider);
    final petState = ref.watch(petStateProvider);
    final dashboardData = ref.watch(dashboardProvider);

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: context.growthColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部拖拽指示器
          _buildDragHandle(context),

          // 头部：猫咪头像 + 等级 + 亲密度条
          _buildHeader(context, petProfile, petState, dashboardData),

          Divider(height: 1, color: context.growthColors.divider),

          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今日心情显示
                  _buildMoodSection(context, petState),

                  const SizedBox(height: 16),

                  // AI小语文本框
                  _buildAiMessageSection(context, petState),

                  const SizedBox(height: 16),

                  // 本周成长亮点数据
                  _buildWeeklyHighlights(context, dashboardData),
                ],
              ),
            ),
          ),

          // 快速分析入口
          _buildAnalysisSection(context, ref),
        ],
      ),
    );
  }

  /// 顶部拖拽指示器
  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.growthColors.textHint.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 头部：猫咪头像 + 等级 + 亲密度条
  Widget _buildHeader(
    BuildContext context,
    AsyncValue<PetProfile?> profileAsync,
    AsyncValue<PetState?> stateAsync,
    AsyncValue<DashboardData?> dashboardAsync,
  ) {
    return profileAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (_, e) => const SizedBox(height: 100),
      data: (profile) {
        final name = profile?.name ?? '甜甜';
        final level = dashboardAsync.valueOrNull?.currentLevel ?? 1;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 猫咪头像
              _buildPetAvatar(context, level),
              const SizedBox(width: 16),

              // 等级 + 亲密度条
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.growthColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.$level ${getPetLevelName(level)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.growthColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIntimacyBar(context, level),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 猫咪头像
  Widget _buildPetAvatar(BuildContext context, int level) {
    return GestureDetector(
      onTap: () => context.push('/pet-center'),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: context.growthColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.growthColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            PetAssets.commonHappy,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                '🐱',
                style: TextStyle(fontSize: 36 + (level * 0.2).clamp(0, 12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 亲密度条
  Widget _buildIntimacyBar(BuildContext context, int level) {
    final intimacy = (level * 10).clamp(0, 100);
    final progress = intimacy / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '亲密度',
              style: TextStyle(
                fontSize: 12,
                color: context.growthColors.textSecondary,
              ),
            ),
            Text(
              '$intimacy%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.growthColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: context.growthColors.primary.withValues(
              alpha: 0.15,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(
              context.growthColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// 今日心情显示
  Widget _buildMoodSection(
    BuildContext context,
    AsyncValue<PetState?> stateAsync,
  ) {
    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const ErrorRetryWidget(),
      data: (state) {
        final stateType = _getPetStateType(state?.currentState ?? 'idle');
        final moodEmoji = _getMoodEmoji(stateType);
        final moodText = _getMoodText(stateType);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.growthColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(moodEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日心情',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.growthColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moodText,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.growthColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// AI小语文本框（浅灰色背景）
  Widget _buildAiMessageSection(
    BuildContext context,
    AsyncValue<PetState?> stateAsync,
  ) {
    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const ErrorRetryWidget(),
      data: (state) {
        final stateType = _getPetStateType(state?.currentState ?? 'idle');
        final message = getPetMessage(stateType);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.growthColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '甜甜说',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.growthColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: context.growthColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 本周成长亮点数据
  Widget _buildWeeklyHighlights(
    BuildContext context,
    AsyncValue<DashboardData?> dashboardAsync,
  ) {
    return dashboardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const ErrorRetryWidget(),
      data: (dashboard) {
        if (dashboard == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周成长亮点',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.growthColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHighlightCard(
                    context,
                    icon: Icons.menu_book_rounded,
                    color: context.growthColors.study,
                    label: '学习时长',
                    value: '${dashboard.todayStudyMinutes}分钟',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHighlightCard(
                    context,
                    icon: Icons.fitness_center_rounded,
                    color: context.growthColors.fitness,
                    label: '健身时长',
                    value: '${dashboard.todayFitnessMinutes}分钟',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHighlightCard(
                    context,
                    icon: Icons.edit_note_rounded,
                    color: context.growthColors.diet,
                    label: '日记篇数',
                    value: '${dashboard.todayJournalCount}篇',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHighlightCard(
                    context,
                    icon: Icons.star_rounded,
                    color: context.growthColors.primary,
                    label: '总经验值',
                    value: '${dashboard.totalExp} EXP',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 亮点数据卡片
  Widget _buildHighlightCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.growthColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 快速分析入口
  Widget _buildAnalysisSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速分析',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.growthColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisButton(
                  context,
                  ref,
                  PetAIAnalysisType.study,
                  '学习分析',
                  context.growthColors.study,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalysisButton(
                  context,
                  ref,
                  PetAIAnalysisType.fitness,
                  '健身分析',
                  context.growthColors.fitness,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisButton(
                  context,
                  ref,
                  PetAIAnalysisType.diet,
                  '饮食分析',
                  context.growthColors.diet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalysisButton(
                  context,
                  ref,
                  PetAIAnalysisType.sleep,
                  '睡眠分析',
                  context.growthColors.sleep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton(
    BuildContext context,
    WidgetRef ref,
    PetAIAnalysisType type,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _startAnalysis(context, ref, type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis(
    BuildContext context,
    WidgetRef ref,
    PetAIAnalysisType type,
  ) async {
    final collector = PetDataCollector(ProviderScope.containerOf(context));
    Map<String, dynamic> data;
    try {
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据收集失败，请重试'),
            backgroundColor: context.growthColors.danger,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    PetAIDataPreviewSheet.show(
      context: context,
      analysisType: type,
      dataSummary: data,
      onConfirm: () {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (_) => PetAIAnalysisPage(initialTab: type.index),
          ),
        );
      },
    );
  }

  /// 获取宠物状态类型
  PetStateType _getPetStateType(String state) {
    switch (state) {
      case 'peek':
        return PetStateType.peek;
      case 'happy':
        return PetStateType.happy;
      case 'sleepy':
        return PetStateType.sleepy;
      default:
        return PetStateType.idle;
    }
  }

  /// 获取心情表情
  String _getMoodEmoji(PetStateType state) {
    switch (state) {
      case PetStateType.idle:
        return '😊';
      case PetStateType.peek:
        return '😸';
      case PetStateType.happy:
        return '😻';
      case PetStateType.sleepy:
        return '😿';
    }
  }

  /// 获取心情文字
  String _getMoodText(PetStateType state) {
    switch (state) {
      case PetStateType.idle:
        return '今天心情不错，继续加油吧！';
      case PetStateType.peek:
        return '有点想你了，快来记录一下吧～';
      case PetStateType.happy:
        return '太开心了！你完成了好多任务！';
      case PetStateType.sleepy:
        return '好久没见到你了，有点困...';
    }
  }
}
