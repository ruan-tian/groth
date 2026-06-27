part of '../pages/ai_analysis_page.dart';

class _DietAnalysisTab extends ConsumerWidget {
  const _DietAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final inputData = ref.watch(aiAnalysisInputProvider);

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
                  inputData.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (e, _) => _buildErrorCard('加载饮食记录失败: $e'),
                    data: (input) {
                      final records = input.dietRecords;
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无饮食记录，请先添加一些饮食记录。');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDietDataPreview(context, records),
                          const SizedBox(height: 14),
                          _buildDietRecordsCard(context, records, colors),
                        ],
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
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisButton(
            context: context,
            icon: Icons.restaurant,
            onPressed: (analysisState.isLoading || analysisState.isStreaming)
                ? null
                : () => _startDietAnalysis(context, ref),
            colors: colors,
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

    final records = await ref.read(aiAnalysisInputProvider.future).then((d) => d.dietRecords);
    if (records.isEmpty) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(const AiAnalysisState(error: '暂无饮食记录可分析。'));
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeDietStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
          ),
        );
  }

  /// 数据预览卡片：标题行 + 数据概览
  Widget _buildDietDataPreview(
    BuildContext context,
    List<DietRecord> records,
  ) {
    final colors = context.growthColors;
    final avgScore =
        records.fold<double>(0, (s, r) => s + r.healthScore) / records.length;

    // 按餐次分组
    final mealTypeCount = <String, int>{};
    for (final r in records) {
      mealTypeCount[r.mealType] = (mealTypeCount[r.mealType] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172033),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Color(0xFFB66A00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '最近 ${records.length} 条饮食记录',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '数据预览',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB66A00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F3), height: 1),
          const SizedBox(height: 8),
          // 数据概览行
          _buildInfoRow('记录条数', '${records.length} 条'),
          _buildInfoRow('平均健康评分', '${avgScore.toStringAsFixed(1)}/5'),
          _buildInfoRow(
            '餐次分布',
            mealTypeCount.entries
                .map((e) => '${_getMealTypeName(e.key)}${e.value}次')
                .join('、'),
          ),
        ],
      ),
    );
  }

  /// 记录卡片：独立卡片，展示最近饮食记录列表
  Widget _buildDietRecordsCard(
    BuildContext context,
    List<DietRecord> records,
    AppThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A172033),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '最近饮食记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${records.length} 条',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...records.take(5).map((r) => _buildDietRecordTile(context, r, colors)),
          if (records.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... 还有 ${records.length - 5} 条记录',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 单条饮食记录
  Widget _buildDietRecordTile(BuildContext context, DietRecord r, AppThemeColors colors) {
    return InkWell(
      onTap: () => _showDietDetail(context, r, colors),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  RecordIconAssets.dietByMealType(r.mealType),
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    _getMealIcon(r.mealType),
                    color: const Color(0xFFB66A00),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.foodText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.mealDate} · ${_getMealTypeName(r.mealType)} · 健康评分${r.healthScore}/5',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showDietDetail(
    BuildContext context,
    DietRecord record,
    AppThemeColors colors,
  ) {
    final detailItems = [
      DetailItem(
        label: '餐次',
        value: _getMealTypeName(record.mealType),
        icon: Icons.restaurant_rounded,
      ),
      DetailItem(
        label: '份量',
        value: _getPortionLabel(record.portionLevel),
        icon: Icons.straighten_rounded,
      ),
      DetailItem(
        label: '热量',
        value: _getCalorieLabel(record.calorieLevel),
        icon: Icons.local_fire_department_rounded,
      ),
      DetailItem(
        label: '蛋白质',
        value: _getProteinLabel(record.proteinLevel),
        icon: Icons.egg_outlined,
      ),
    ];

    final extraCards = <Widget>[];
    if (record.foodText.isNotEmpty) {
      extraCards.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '食物描述',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.foodText,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (record.note != null && record.note!.isNotEmpty) {
      extraCards.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '备注',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.note!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    RecordDetailSheet.show(
      context: context,
      title: record.mealDate,
      primaryMetricLabel: '健康评分',
      primaryMetricValue: '${record.healthScore}/5',
      primaryMetricIcon: Icons.star_rounded,
      detailItems: detailItems,
      accentColor: colors.diet,
      extraCards: extraCards.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: extraCards
                  .expand((w) => [w, const SizedBox(height: 12)])
                  .toList()
                ..removeLast(),
            ),
    );
  }

  String _getPortionLabel(String level) {
    switch (level) {
      case 'small':
        return '少量';
      case 'normal':
        return '正常';
      case 'large':
        return '大量';
      default:
        return level;
    }
  }

  String _getCalorieLabel(String level) {
    switch (level) {
      case 'low':
        return '低热量';
      case 'normal':
        return '正常';
      case 'high':
        return '高热量';
      default:
        return level;
    }
  }

  String _getProteinLabel(String level) {
    switch (level) {
      case 'low':
        return '低蛋白';
      case 'medium':
        return '中等';
      case 'high':
        return '高蛋白';
      default:
        return level;
    }
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
    final inputData = ref.watch(aiAnalysisInputProvider);

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
                  inputData.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (e, _) => _buildErrorCard('加载睡眠记录失败: $e'),
                    data: (input) {
                      final records = input.sleepRecords;
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无睡眠记录，请先添加一些睡眠记录。');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSleepDataPreview(
                            context,
                            records,
                            AsyncData(input.weeklyAvgSleepDuration),
                            AsyncData(input.weeklyAvgSleepQuality),
                          ),
                          const SizedBox(height: 14),
                          _buildSleepRecordsCard(context, records, colors),
                        ],
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
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisButton(
            context: context,
            icon: Icons.bedtime,
            onPressed: (analysisState.isLoading || analysisState.isStreaming)
                ? null
                : () => _startSleepAnalysis(context, ref),
            colors: colors,
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

    final records = await ref.read(aiAnalysisInputProvider.future).then((d) => d.sleepRecords);
    if (records.isEmpty) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(const AiAnalysisState(error: '暂无睡眠记录可分析。'));
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeSleepStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
          ),
        );
  }

  /// 数据预览卡片：标题行 + 数据概览
  Widget _buildSleepDataPreview(
    BuildContext context,
    List<SleepRecord> records,
    AsyncValue<double?> avgDuration,
    AsyncValue<double?> avgQuality,
  ) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172033),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1FF),
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: const Icon(
                  Icons.bedtime,
                  color: Color(0xFF5B4BC4),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '最近 ${records.length} 条睡眠记录',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '数据预览',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B4BC4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F3), height: 1),
          const SizedBox(height: 8),
          // 数据概览行
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
        ],
      ),
    );
  }

  /// 记录卡片：独立卡片，展示最近睡眠记录列表
  Widget _buildSleepRecordsCard(
    BuildContext context,
    List<SleepRecord> records,
    AppThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A172033),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '最近睡眠记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${records.length} 条',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...records.take(5).map((r) => _buildSleepRecordTile(context, r, colors)),
          if (records.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... 还有 ${records.length - 5} 条记录',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 单条睡眠记录
  Widget _buildSleepRecordTile(BuildContext context, SleepRecord r, AppThemeColors colors) {
    final hours = r.durationMinutes ~/ 60;
    final minutes = r.durationMinutes % 60;
    return InkWell(
      onTap: () => _showSleepDetail(context, r, colors),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  RecordIconAssets.sleep,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.nightlight,
                    color: Color(0xFF5B4BC4),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.sleepDate} 睡眠',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.sleepTime}-${r.wakeTime} · ${hours}h${minutes}m · 质量${r.qualityLevel}/5',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showSleepDetail(
    BuildContext context,
    SleepRecord record,
    AppThemeColors colors,
  ) {
    final hours = record.durationMinutes ~/ 60;
    final minutes = record.durationMinutes % 60;

    final detailItems = [
      DetailItem(
        label: '入睡时间',
        value: record.sleepTime,
        icon: Icons.nightlight_round,
      ),
      DetailItem(
        label: '起床时间',
        value: record.wakeTime,
        icon: Icons.wb_sunny_rounded,
      ),
      DetailItem(
        label: '入睡用时',
        value: '${record.fallAsleepMinutes}分钟',
        icon: Icons.timer_outlined,
      ),
      DetailItem(
        label: '夜间醒来',
        value: '${record.wakeCount}次',
        icon: Icons.notifications_none_rounded,
      ),
    ];

    final extraCards = <Widget>[];
    if (record.dreamNote != null && record.dreamNote!.isNotEmpty) {
      extraCards.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.softPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '梦境',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.dreamNote!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (record.note != null && record.note!.isNotEmpty) {
      extraCards.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '备注',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.note!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    RecordDetailSheet.show(
      context: context,
      title: record.sleepDate,
      primaryMetricLabel: '睡眠时长',
      primaryMetricValue: '${hours}h ${minutes}m',
      primaryMetricIcon: Icons.nightlight_round,
      detailItems: detailItems,
      accentColor: colors.sleep,
      extraCards: extraCards.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: extraCards
                  .expand((w) => [w, const SizedBox(height: 12)])
                  .toList()
                ..removeLast(),
            ),
    );
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
    final inputData = ref.watch(aiAnalysisInputProvider);

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
                  inputData.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (e, _) => _buildErrorCard('加载成长数据失败: $e'),
                    data: (input) {
                      final data = input.dashboard;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGrowthDataPreview(context, data),
                          const SizedBox(height: 14),
                          _buildGrowthTrendCard(context, data, colors),
                        ],
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
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisButton(
            context: context,
            icon: Icons.auto_graph_rounded,
            onPressed: (analysisState.isLoading || analysisState.isStreaming)
                ? null
                : () => _showReportTypeSheet(context, ref),
            colors: colors,
          ),
        ],
      ),
    );
  }

  void _showReportTypeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportTypeSheet(
        onWeekly: () => _generateReport(context, ref, isWeekly: true),
        onMonthly: () => _generateReport(context, ref, isWeekly: false),
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

    final data = await ref.read(aiAnalysisInputProvider.future).then((d) => d.dashboard);
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
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          isWeekly
              ? () => aiService.generateWeeklyReportStream(
                  apiKey: config.apiKey,
                  baseUrl: config.baseUrl,
                  model: config.modelName,
                  weeklyData: weeklyData,
                )
              : () => aiService.generateMonthlyReportStream(
                  apiKey: config.apiKey,
                  baseUrl: config.baseUrl,
                  model: config.modelName,
                  monthlyData: weeklyData,
                ),
        );
  }

  /// 数据预览卡片：标题行 + 成长数据概览
  Widget _buildGrowthDataPreview(
    BuildContext context,
    DashboardData data,
  ) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D172033),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: const Icon(
                  Icons.auto_graph,
                  color: Color(0xFF4D6BE8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '成长数据概览',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '数据预览',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4D6BE8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F3), height: 1),
          const SizedBox(height: 8),
          // 数据概览行
          _buildInfoRow('当前等级', 'Lv.${data.currentLevel}'),
          _buildInfoRow('总经验值', '${data.totalExp} EXP'),
          _buildInfoRow('今日学习', '${data.todayStudyMinutes} 分钟'),
          _buildInfoRow('今日健身', '${data.todayFitnessMinutes} 分钟'),
          _buildInfoRow('今日日记', '${data.todayJournalCount} 篇'),
          _buildInfoRow('今日专注', '${data.todayFocusMinutes} 分钟'),
        ],
      ),
    );
  }

  /// 趋势卡片：独立卡片，展示最近 7 天趋势
  Widget _buildGrowthTrendCard(
    BuildContext context,
    DashboardData data,
    AppThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A172033),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近 7 天趋势',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...data.weeklyStats.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${s.date.month}/${s.date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildTrendTag(
                          '${s.studyMinutes}分',
                          const Color(0xFF4D6BE8),
                          const Color(0xFFEEF3FF),
                        ),
                        const SizedBox(width: 6),
                        _buildTrendTag(
                          '${s.fitnessMinutes}分',
                          const Color(0xFFC95F1E),
                          const Color(0xFFFFF1E7),
                        ),
                        const SizedBox(width: 6),
                        _buildTrendTag(
                          '+${s.expGained}EXP',
                          const Color(0xFFB66A00),
                          const Color(0xFFFFF7ED),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
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

class AiAnalysisResultCard extends StatelessWidget {
  const AiAnalysisResultCard({
    super.key,
    required this.result,
  });

  final String result;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A172033),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A172033),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
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

// =============================================================================
// 报告类型选择 Sheet
// =============================================================================

class _ReportTypeSheet extends StatelessWidget {
  const _ReportTypeSheet({
    required this.onWeekly,
    required this.onMonthly,
  });

  final VoidCallback onWeekly;
  final VoidCallback onMonthly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '选择报告类型',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 20),
          // 周报
          _ReportOption(
            icon: Icons.date_range,
            label: '生成周报',
            description: '分析最近一周的成长数据',
            color: colors.study,
            onTap: () {
              Navigator.pop(context);
              onWeekly();
            },
          ),
          const SizedBox(height: 12),
          // 月报
          _ReportOption(
            icon: Icons.calendar_month,
            label: '生成月报',
            description: '分析最近一个月的成长数据',
            color: colors.primary,
            onTap: () {
              Navigator.pop(context);
              onMonthly();
            },
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  const _ReportOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.body),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
