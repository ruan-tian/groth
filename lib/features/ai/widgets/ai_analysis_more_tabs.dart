part of '../pages/ai_analysis_page.dart';

class _DietAnalysisTab extends ConsumerWidget {
  const _DietAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final recentRecords = ref.watch(recentDietRecordsProvider(20));
    final knowledgeContext = ref.watch(knowledgeContextServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('数据预览'),
                  const SizedBox(height: 8),
                  recentRecords.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (e, _) => _buildErrorCard('加载饮食记录失败: $e'),
                    data: (records) {
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无饮食记录，请先添加一些饮食记录。');
                      }
                      final query = _dietContextQuery(records);
                      return FutureBuilder<KnowledgeContextBundle>(
                        future: knowledgeContext.buildForQuery(query),
                        builder: (context, snapshot) {
                          return _buildDietDataPreview(
                            records,
                            colors,
                            bundle: snapshot.data,
                            isLoadingContext:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (analysisState.isLoading) ...[
                    _buildSectionTitle('分析中'),
                    const SizedBox(height: 8),
                    const _LoadingCard(),
                  ] else if (analysisState.isStreaming &&
                      analysisState.partialResult != null) ...[
                  _buildSectionTitle('分析中'),
                  const SizedBox(height: 8),
                  AiAnalysisResultCard(
                    result: analysisState.partialResult!,
                  ),
                  ] else if (analysisState.error != null) ...[
                    _buildSectionTitle('分析失败'),
                    const SizedBox(height: 8),
                    _buildErrorCard(analysisState.error!),
                  ] else if (analysisState.result != null) ...[
                    _buildSectionTitle('分析结果'),
                    const SizedBox(height: 8),
                    AiAnalysisResultCard(
                      result: analysisState.result!,
                      referenceContext: analysisState.referenceContext,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (analysisState.isLoading || analysisState.isStreaming)
                  ? null
                  : () => _startDietAnalysis(context, ref),
              icon: const Icon(Icons.restaurant),
              label: const Text('开始分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDietAnalysis(BuildContext context, WidgetRef ref) async {
    final config = await ref.read(enabledAiConfigProvider.future);
    if (config == null) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(
            const AiAnalysisState(error: '未配置 AI 服务，请先在设置中配置 AI API。'),
          );
      return;
    }

    final records = await ref.read(recentDietRecordsProvider(20).future);
    if (records.isEmpty) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(const AiAnalysisState(error: '暂无饮食记录可分析。'));
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    final knowledgeContext = ref.read(knowledgeContextServiceProvider);
    final bundle = await knowledgeContext.buildForQuery(
      _dietContextQuery(records),
    );
    if (!context.mounted) return;
    final confirmedBundle = await showKnowledgeContextConfirmSheet(
      context: context,
      bundle: bundle,
    );
    if (confirmedBundle == null) return;
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeDietStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
            knowledgeContext: confirmedBundle.toPromptSection(),
          ),
          referenceContext: confirmedBundle,
        );
  }

  Widget _buildDietDataPreview(
    List<DietRecord> records,
    AppThemeColors colors, {
    KnowledgeContextBundle? bundle,
    bool isLoadingContext = false,
  }) {
    final avgScore =
        records.fold<double>(0, (s, r) => s + r.healthScore) / records.length;

    // 按餐次分组
    final mealTypeCount = <String, int>{};
    for (final r in records) {
      mealTypeCount[r.mealType] = (mealTypeCount[r.mealType] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, size: 20),
                const SizedBox(width: 8),
                Text(
                  '最近 ${records.length} 条饮食记录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('记录条数', '${records.length} 条'),
            _buildInfoRow('平均健康评分', '${avgScore.toStringAsFixed(1)}/5'),
            _buildInfoRow(
              '餐次分布',
              mealTypeCount.entries
                  .map((e) => '${_getMealTypeName(e.key)}${e.value}次')
                  .join('、'),
            ),
            ..._buildKnowledgeContextRows(bundle, isLoading: isLoadingContext),
            const SizedBox(height: 8),
            ...records.take(3).map((r) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(_getMealIcon(r.mealType), size: 20),
                title: Text(r.foodText),
                subtitle: Text(
                  '${r.mealDate} · ${_getMealTypeName(r.mealType)} · 健康评分${r.healthScore}/5',
                ),
              );
            }),
            if (records.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... 还有 ${records.length - 3} 条记录',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dietContextQuery(List<DietRecord> records) {
    return _joinContextTerms([
      '饮食 营养 健康 记录',
      for (final record in records.take(10)) record.foodText,
      for (final record in records.take(10)) record.mealType,
      for (final record in records.take(10)) record.calorieLevel,
    ]);
  }

  String _getMealTypeName(String type) {
    switch (type) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      case 'snack':
        return '加餐';
      default:
        return type;
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
}

// =============================================================================
// 睡眠分析 Tab
// =============================================================================

class _SleepAnalysisTab extends ConsumerWidget {
  const _SleepAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final recentRecords = ref.watch(recentSleepRecordsProvider(14));
    final weeklyAvgDuration = ref.watch(weeklyAvgSleepDurationProvider);
    final weeklyAvgQuality = ref.watch(weeklyAvgSleepQualityProvider);
    final knowledgeContext = ref.watch(knowledgeContextServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('数据预览'),
                  const SizedBox(height: 8),
                  recentRecords.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (e, _) => _buildErrorCard('加载睡眠记录失败: $e'),
                    data: (records) {
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无睡眠记录，请先添加一些睡眠记录。');
                      }
                      final query = _sleepContextQuery(records);
                      return FutureBuilder<KnowledgeContextBundle>(
                        future: knowledgeContext.buildForQuery(query),
                        builder: (context, snapshot) {
                          return _buildSleepDataPreview(
                            records,
                            weeklyAvgDuration,
                            weeklyAvgQuality,
                            colors,
                            bundle: snapshot.data,
                            isLoadingContext:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (analysisState.isLoading) ...[
                    _buildSectionTitle('分析中'),
                    const SizedBox(height: 8),
                    const _LoadingCard(),
                  ] else if (analysisState.isStreaming &&
                      analysisState.partialResult != null) ...[
                  _buildSectionTitle('分析中'),
                  const SizedBox(height: 8),
                  AiAnalysisResultCard(
                    result: analysisState.partialResult!,
                  ),
                  ] else if (analysisState.error != null) ...[
                    _buildSectionTitle('分析失败'),
                    const SizedBox(height: 8),
                    _buildErrorCard(analysisState.error!),
                  ] else if (analysisState.result != null) ...[
                    _buildSectionTitle('分析结果'),
                    const SizedBox(height: 8),
                    AiAnalysisResultCard(
                      result: analysisState.result!,
                      referenceContext: analysisState.referenceContext,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (analysisState.isLoading || analysisState.isStreaming)
                  ? null
                  : () => _startSleepAnalysis(context, ref),
              icon: const Icon(Icons.bedtime),
              label: const Text('开始分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSleepAnalysis(BuildContext context, WidgetRef ref) async {
    final config = await ref.read(enabledAiConfigProvider.future);
    if (config == null) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(
            const AiAnalysisState(error: '未配置 AI 服务，请先在设置中配置 AI API。'),
          );
      return;
    }

    final records = await ref.read(recentSleepRecordsProvider(14).future);
    if (records.isEmpty) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(const AiAnalysisState(error: '暂无睡眠记录可分析。'));
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    final knowledgeContext = ref.read(knowledgeContextServiceProvider);
    final bundle = await knowledgeContext.buildForQuery(
      _sleepContextQuery(records),
    );
    if (!context.mounted) return;
    final confirmedBundle = await showKnowledgeContextConfirmSheet(
      context: context,
      bundle: bundle,
    );
    if (confirmedBundle == null) return;
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeSleepStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
            knowledgeContext: confirmedBundle.toPromptSection(),
          ),
          referenceContext: confirmedBundle,
        );
  }

  Widget _buildSleepDataPreview(
    List<SleepRecord> records,
    AsyncValue<double?> avgDuration,
    AsyncValue<double?> avgQuality,
    AppThemeColors colors, {
    KnowledgeContextBundle? bundle,
    bool isLoadingContext = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, size: 20),
                const SizedBox(width: 8),
                Text(
                  '最近 ${records.length} 条睡眠记录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            avgDuration.when(
              loading: () => _buildInfoRow('平均睡眠时长', '加载中...'),
              error: (_, _) => _buildInfoRow('平均睡眠时长', '--'),
              data: (d) => d != null
                  ? _buildInfoRow(
                      '平均睡眠时长',
                      '${(d ~/ 60)}小时${(d % 60).toInt()}分钟',
                    )
                  : _buildInfoRow('平均睡眠时长', '--'),
            ),
            avgQuality.when(
              loading: () => _buildInfoRow('平均睡眠质量', '加载中...'),
              error: (_, _) => _buildInfoRow('平均睡眠质量', '--'),
              data: (q) => q != null
                  ? _buildInfoRow('平均睡眠质量', '${q.toStringAsFixed(1)}/5')
                  : _buildInfoRow('平均睡眠质量', '--'),
            ),
            ..._buildKnowledgeContextRows(bundle, isLoading: isLoadingContext),
            const SizedBox(height: 8),
            ...records.take(5).map((r) {
              final hours = r.durationMinutes ~/ 60;
              final minutes = r.durationMinutes % 60;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.nightlight, size: 20),
                title: Text('${r.sleepDate} 睡眠'),
                subtitle: Text(
                  '${r.sleepTime}-${r.wakeTime} · ${hours}h${minutes}m · 质量${r.qualityLevel}/5',
                ),
              );
            }),
            if (records.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... 还有 ${records.length - 5} 条记录',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _sleepContextQuery(List<SleepRecord> records) {
    return _joinContextTerms([
      '睡眠 作息 入睡 夜醒 睡眠质量 恢复',
      for (final record in records.take(8)) record.sleepDate,
      for (final record in records.take(8)) record.bedTime,
      for (final record in records.take(8)) record.wakeTime,
    ]);
  }
}

// =============================================================================
// 成长报告 Tab
// =============================================================================

class _GrowthReportTab extends ConsumerWidget {
  const _GrowthReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final knowledgeContext = ref.watch(knowledgeContextServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('数据预览'),
                  const SizedBox(height: 8),
                  dashboardAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (e, _) => _buildErrorCard('加载成长数据失败: $e'),
                    data: (data) {
                      final query = _growthContextQuery(data);
                      return FutureBuilder<KnowledgeContextBundle>(
                        future: knowledgeContext.buildForQuery(query),
                        builder: (context, snapshot) {
                          return _buildGrowthDataPreview(
                            data,
                            colors,
                            bundle: snapshot.data,
                            isLoadingContext:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (analysisState.isLoading) ...[
                    _buildSectionTitle('生成中'),
                    const SizedBox(height: 8),
                    const _LoadingCard(),
                  ] else if (analysisState.isStreaming &&
                      analysisState.partialResult != null) ...[
                  _buildSectionTitle('生成中'),
                  const SizedBox(height: 8),
                  AiAnalysisResultCard(
                    result: analysisState.partialResult!,
                  ),
                  ] else if (analysisState.error != null) ...[
                    _buildSectionTitle('生成失败'),
                    const SizedBox(height: 8),
                    _buildErrorCard(analysisState.error!),
                  ] else if (analysisState.result != null) ...[
                    _buildSectionTitle('成长报告'),
                    const SizedBox(height: 8),
                    AiAnalysisResultCard(
                      result: analysisState.result!,
                      referenceContext: analysisState.referenceContext,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (analysisState.isLoading || analysisState.isStreaming)
                        ? null
                        : () => _generateReport(context, ref, isWeekly: true),
                    icon: const Icon(Icons.date_range),
                    label: const Text('生成周报'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (analysisState.isLoading || analysisState.isStreaming)
                        ? null
                        : () => _generateReport(context, ref, isWeekly: false),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('生成月报'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(
    BuildContext context,
    WidgetRef ref, {
    required bool isWeekly,
  }) async {
    final config = await ref.read(enabledAiConfigProvider.future);
    if (config == null) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(
            const AiAnalysisState(error: '未配置 AI 服务，请先在设置中配置 AI API。'),
          );
      return;
    }

    final data = await ref.read(dashboardProvider.future);
    final weeklyData = {
      '学习时长': '${data.todayStudyMinutes} 分钟',
      '健身时长': '${data.todayFitnessMinutes} 分钟',
      '日记篇数': data.todayJournalCount,
      '总经验值': data.totalExp,
      '当前等级': data.currentLevel,
      '每日统计': data.weeklyStats
          .map(
            (s) => {
              '日期': '${s.date.month}/${s.date.day}',
              '学习': '${s.studyMinutes}分钟',
              '健身': '${s.fitnessMinutes}分钟',
              '经验': s.expGained,
            },
          )
          .toList(),
    };

    final aiService = ref.read(aiServiceProvider);
    final knowledgeContext = ref.read(knowledgeContextServiceProvider);
    final bundle = await knowledgeContext.buildForQuery(
      _growthContextQuery(data),
    );
    if (!context.mounted) return;
    final confirmedBundle = await showKnowledgeContextConfirmSheet(
      context: context,
      bundle: bundle,
    );
    if (confirmedBundle == null) return;
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          isWeekly
              ? () => aiService.generateWeeklyReportStream(
                  apiKey: config.apiKey,
                  baseUrl: config.baseUrl,
                  model: config.modelName,
                  weeklyData: weeklyData,
                  knowledgeContext: confirmedBundle.toPromptSection(),
                )
              : () => aiService.generateMonthlyReportStream(
                  apiKey: config.apiKey,
                  baseUrl: config.baseUrl,
                  model: config.modelName,
                  monthlyData: weeklyData,
                  knowledgeContext: confirmedBundle.toPromptSection(),
                ),
          referenceContext: confirmedBundle,
        );
  }

  Widget _buildGrowthDataPreview(
    DashboardData data,
    AppThemeColors colors, {
    KnowledgeContextBundle? bundle,
    bool isLoadingContext = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph, size: 20),
                const SizedBox(width: 8),
                Text(
                  '成长概览',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('当前等级', 'Lv.${data.currentLevel}'),
            _buildInfoRow('总经验值', '${data.totalExp} EXP'),
            _buildInfoRow('今日学习', '${data.todayStudyMinutes} 分钟'),
            _buildInfoRow('今日健身', '${data.todayFitnessMinutes} 分钟'),
            _buildInfoRow('今日日记', '${data.todayJournalCount} 篇'),
            ..._buildKnowledgeContextRows(bundle, isLoading: isLoadingContext),
            const SizedBox(height: 8),
            const Text(
              '最近 7 天趋势',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...data.weeklyStats.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${s.date.month}/${s.date.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '学习${s.studyMinutes}分 健身${s.fitnessMinutes}分 +${s.expGained}EXP',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _growthContextQuery(DashboardData data) {
    return _joinContextTerms([
      '成长 复盘 目标 学习 健身 日记 饮食 睡眠 专注',
      '学习${data.todayStudyMinutes}',
      '健身${data.todayFitnessMinutes}',
      '日记${data.todayJournalCount}',
      '专注${data.todayFocusMinutes}',
      if (data.todayDietCount > 0) '饮食${data.todayDietCount}',
      if (data.todayAvgHealthScore != null) '健康${data.todayAvgHealthScore}',
      if (data.lastNightSleepDuration != null)
        '睡眠${data.lastNightSleepDuration}',
      if (data.lastNightSleepQuality != null)
        '睡眠质量${data.lastNightSleepQuality}',
    ]);
  }
}

// =============================================================================
// 通用组件
// =============================================================================

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyCard(String message) {
  return Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
    ),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildErrorCard(String message) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class AiAnalysisResultCard extends ConsumerWidget {
  const AiAnalysisResultCard({
    super.key,
    required this.result,
    this.referenceContext,
  });

  final String result;
  final KnowledgeContextBundle? referenceContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasReferences =
        referenceContext != null && referenceContext!.results.isNotEmpty;
    final citationSummary = hasReferences
        ? _CitationSummary.fromResult(result, referenceContext!.results.length)
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '分析完成',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              if (hasReferences)
                TextButton.icon(
                  key: const Key('ai-analysis-save-card-button'),
                  onPressed: () => _saveAsKnowledgeCards(context, ref),
                  icon: const Icon(Icons.style_rounded, size: 17),
                  label: const Text('转为知识卡'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            result,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasReferences) ...[
            const SizedBox(height: 14),
            _CitationStatusBar(summary: citationSummary!),
            const SizedBox(height: 10),
            _KnowledgeContextReferences(bundle: referenceContext!),
          ],
        ],
      ),
    );
  }

  Future<void> _saveAsKnowledgeCards(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bundle = referenceContext;
    if (bundle == null || bundle.results.isEmpty) return;

    final drafts = ref
        .read(aiAnalysisCardServiceProvider)
        .buildDraftsFromAnalysis(result);
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂未识别出可转成知识卡的内容')));
      return;
    }

    final duplicateReasons = await ref
        .read(knowledgeCardAiServiceProvider)
        .findDuplicateReasonsFromResults(
          results: bundle.results,
          drafts: drafts,
        );
    if (!context.mounted) return;

    final selected = await _AiAnalysisDraftPreviewSheet.show(
      context: context,
      drafts: drafts,
      duplicateReasons: duplicateReasons,
    );
    if (selected == null || selected.isEmpty) return;

    final ids = await ref
        .read(knowledgeCardAiServiceProvider)
        .saveDraftsFromResults(results: bundle.results, drafts: selected);
    if (!context.mounted) return;

    ref.invalidate(knowledgeCardsProvider);
    ref.invalidate(knowledgeReviewStatsProvider);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已保存 ${ids.length} 张知识卡')));
  }
}

class _CitationSummary {
  const _CitationSummary({required this.usedIndexes, required this.totalCount});

  final List<int> usedIndexes;
  final int totalCount;

  bool get hasCitations => usedIndexes.isNotEmpty;

  String get label {
    if (!hasCitations) return '未检测到片段编号';
    return '已引用：${usedIndexes.map((index) => '片段 $index').join('、')}';
  }

  static _CitationSummary fromResult(String result, int totalCount) {
    final matches = RegExp(r'【片段\s*(\d+)】').allMatches(result);
    final indexes = <int>{};
    for (final match in matches) {
      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index >= 1 && index <= totalCount) {
        indexes.add(index);
      }
    }
    final sorted = indexes.toList()..sort();
    return _CitationSummary(usedIndexes: sorted, totalCount: totalCount);
  }
}

class _CitationStatusBar extends StatelessWidget {
  const _CitationStatusBar({required this.summary});

  final _CitationSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final color = summary.hasCitations ? colors.success : colors.warning;
    return Container(
      key: const Key('ai-analysis-citation-status'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            summary.hasCitations
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary.label,
              style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载中卡片
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'AI 正在分析中，请稍候...',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}