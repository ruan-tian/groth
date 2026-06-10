import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/pet_assets.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/pet_provider.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../core/domain/pet/pet_ai_result.dart';
import '../../pet/utils/pet_data_collector.dart';
import '../../pet/widgets/pet_ai_data_preview_sheet.dart';
import '../../pet/pages/pet_ai_analysis_page.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x146B5CEA),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部拖拽指示器
          _buildDragHandle(),

          // 头部：猫咪头像 + 等级 + 亲密度条
          _buildHeader(context, petProfile, petState, dashboardData),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今日心情显示
                  _buildMoodSection(petState),

                  const SizedBox(height: 16),

                  // AI小语文本框
                  _buildAiMessageSection(petState),

                  const SizedBox(height: 16),

                  // 本周成长亮点数据
                  _buildWeeklyHighlights(dashboardData),
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
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.4),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.$level ${getPetLevelName(level)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIntimacyBar(level),
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
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
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
  Widget _buildIntimacyBar(int level) {
    final intimacy = (level * 10).clamp(0, 100);
    final progress = intimacy / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '亲密度',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              '$intimacy%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  /// 今日心情显示
  Widget _buildMoodSection(AsyncValue<PetState?> stateAsync) {
    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
      data: (state) {
        final stateType = _getPetStateType(state?.currentState ?? 'idle');
        final moodEmoji = _getMoodEmoji(stateType);
        final moodText = _getMoodText(stateType);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
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
                    const Text(
                      '今日心情',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moodText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
  Widget _buildAiMessageSection(AsyncValue<PetState?> stateAsync) {
    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
      data: (state) {
        final stateType = _getPetStateType(state?.currentState ?? 'idle');
        final message = getPetMessage(stateType);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Text(
                    '甜甜说',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
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
  Widget _buildWeeklyHighlights(AsyncValue<DashboardData?> dashboardAsync) {
    return dashboardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
      data: (dashboard) {
        if (dashboard == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本周成长亮点',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHighlightCard(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.study,
                    label: '学习时长',
                    value: '${dashboard.todayStudyMinutes}分钟',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHighlightCard(
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.fitness,
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
                    icon: Icons.edit_note_rounded,
                    color: AppColors.diet,
                    label: '日记篇数',
                    value: '${dashboard.todayJournalCount}篇',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHighlightCard(
                    icon: Icons.star_rounded,
                    color: AppColors.primary,
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
  Widget _buildHighlightCard({
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
          const Text(
            '快速分析',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
                  AppColors.study,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalysisButton(
                  context,
                  ref,
                  PetAIAnalysisType.fitness,
                  '健身分析',
                  AppColors.fitness,
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
                  AppColors.diet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalysisButton(
                  context,
                  ref,
                  PetAIAnalysisType.sleep,
                  '睡眠分析',
                  const Color(0xFF7058F5),
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
          SnackBar(content: Text('数据收集失败: $e'), backgroundColor: Colors.red),
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
