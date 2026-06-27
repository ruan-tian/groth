part of '../pages/ai_analysis_page.dart';

class _StudyAnalysisTab extends ConsumerWidget {
  const _StudyAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final inputData = ref.watch(aiAnalysisInputProvider);
    final colors = context.growthColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 数据预览 + 记录列表
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('数据预览'),
                  const SizedBox(height: 8),
                  inputData.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载学习记录失败: $e'),
                    data: (input) {
                      final records = input.studyRecords;
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无学习记录，请先添加一些学习记录。');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 数据预览卡片
                          _buildStudyDataPreview(context, records),
                          const SizedBox(height: 14),
                          // 记录卡片
                          _buildStudyRecordsCard(context, records, colors),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 分析结果
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

          // 分析按钮
          _buildAnalysisButton(
            context: context,
            icon: Icons.psychology,
            onPressed: (analysisState.isLoading || analysisState.isStreaming)
                ? null
                : () => _startStudyAnalysis(context, ref),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Future<void> _startStudyAnalysis(BuildContext context, WidgetRef ref) async {
    final config = await ref.read(enabledAiConfigProvider.future);
    if (config == null) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(
            const AiAnalysisState(error: '未配置 AI 服务，请先在设置中配置 AI API。'),
          );
      return;
    }

    final records = await ref.read(aiAnalysisInputProvider.future).then((d) => d.studyRecords);
    if (records.isEmpty) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(const AiAnalysisState(error: '暂无学习记录可分析。'));
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeStudyStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
          ),
        );
  }

  /// 数据预览卡片：标题行 + 数据概览
  Widget _buildStudyDataPreview(
    BuildContext context,
    List<StudyRecord> records,
  ) {
    final colors = context.growthColors;
    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
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
                  Icons.school,
                  color: Color(0xFF4D6BE8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '最近 ${records.length} 条学习记录',
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
          _buildInfoRow('总学习时长', '$totalMinutes 分钟'),
          _buildInfoRow('记录条数', '${records.length} 条'),
        ],
      ),
    );
  }

  /// 记录卡片：独立卡片，展示最近学习记录列表
  Widget _buildStudyRecordsCard(
    BuildContext context,
    List<StudyRecord> records,
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
                '最近学习记录',
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
          ...records.take(5).map((r) => _buildStudyRecordTile(context, r, colors)),
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

  /// 单条学习记录
  Widget _buildStudyRecordTile(BuildContext context, StudyRecord r, AppThemeColors colors) {
    final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
    final subtitle = '${date.month}/${date.day} · ${r.durationMinutes}分钟'
        '${r.subject != null ? ' · ${r.subject}' : ''}';
    return InkWell(
      onTap: () => _showStudyDetail(context, r, colors),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  RecordIconAssets.study,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.book,
                    color: Color(0xFF4D6BE8),
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
                    r.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

  void _showStudyDetail(
    BuildContext context,
    StudyRecord record,
    AppThemeColors colors,
  ) {
    final startDt = DateTime.fromMillisecondsSinceEpoch(record.startTime);
    final endDt = DateTime.fromMillisecondsSinceEpoch(record.endTime);
    final dateStr =
        '${startDt.year}年${startDt.month}月${startDt.day}日';

    final detailItems = [
      DetailItem(
        label: '科目',
        value: record.subject ?? '--',
        icon: Icons.book_outlined,
      ),
      DetailItem(
        label: '难度',
        value: record.difficultyLevel != null
            ? '${record.difficultyLevel}/5'
            : '--',
        icon: Icons.speed_rounded,
      ),
      DetailItem(
        label: '开始',
        value:
            '${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}',
        icon: Icons.play_circle_outline,
      ),
      DetailItem(
        label: '结束',
        value:
            '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}',
        icon: Icons.stop_circle_outlined,
      ),
    ];

    final noteCard = (record.note != null && record.note!.isNotEmpty)
        ? Container(
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
          )
        : null;

    RecordDetailSheet.show(
      context: context,
      title: dateStr,
      primaryMetricLabel: '学习时长',
      primaryMetricValue: '${record.durationMinutes} 分钟',
      detailItems: detailItems,
      accentColor: colors.study,
      extraCards: noteCard,
    );
  }
}

// =============================================================================
// 健身分析 Tab
// =============================================================================

class _FitnessAnalysisTab extends ConsumerWidget {
  const _FitnessAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final inputData = ref.watch(aiAnalysisInputProvider);
    final colors = context.growthColors;

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
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载健身记录失败: $e'),
                    data: (input) {
                      final records = input.fitnessRecords;
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无健身记录，请先添加一些训练记录。');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 数据预览卡片
                          _buildFitnessDataPreview(context, records),
                          const SizedBox(height: 14),
                          // 记录卡片
                          _buildFitnessRecordsCard(context, records, colors),
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
            icon: Icons.fitness_center,
            onPressed: (analysisState.isLoading || analysisState.isStreaming)
                ? null
                : () => _startFitnessAnalysis(context, ref),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Future<void> _startFitnessAnalysis(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final config = await ref.read(enabledAiConfigProvider.future);
    if (config == null) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(
            const AiAnalysisState(error: '未配置 AI 服务，请先在设置中配置 AI API。'),
          );
      return;
    }

    final records = await ref.read(aiAnalysisInputProvider.future).then((d) => d.fitnessRecords);
    if (records.isEmpty) {
      ref
          .read(aiAnalysisStateProvider.notifier)
          .updateState(const AiAnalysisState(error: '暂无健身记录可分析。'));
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeFitnessStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
          ),
        );
  }

  /// 数据预览卡片：标题行 + 数据概览
  Widget _buildFitnessDataPreview(
    BuildContext context,
    List<FitnessRecord> records,
  ) {
    final colors = context.growthColors;
    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    final bodyPartCount = <String, int>{};
    for (final r in records) {
      bodyPartCount[r.bodyPart] = (bodyPartCount[r.bodyPart] ?? 0) + 1;
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
                  color: const Color(0xFFFFF1E7),
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFFC95F1E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '最近 ${records.length} 条健身记录',
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
                  color: const Color(0xFFFFF1E7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '数据预览',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC95F1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0F3), height: 1),
          const SizedBox(height: 8),
          // 数据概览行
          _buildInfoRow('总训练时长', '$totalMinutes 分钟'),
          _buildInfoRow('训练次数', '${records.length} 次'),
          _buildInfoRow('训练部位', bodyPartCount.keys.join('、')),
        ],
      ),
    );
  }

  /// 记录卡片：独立卡片，展示最近健身记录列表
  Widget _buildFitnessRecordsCard(
    BuildContext context,
    List<FitnessRecord> records,
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
                '最近健身记录',
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
          ...records.take(5).map((r) => _buildFitnessRecordTile(context, r, colors)),
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

  /// 单条健身记录
  Widget _buildFitnessRecordTile(BuildContext context, FitnessRecord r, AppThemeColors colors) {
    final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
    final subtitle = '${date.month}/${date.day} · ${r.durationMinutes}分钟'
        '${r.intensityLevel != null ? ' · 强度${r.intensityLevel}/5' : ''}';
    return InkWell(
      onTap: () => _showFitnessDetail(context, r, colors),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  RecordIconAssets.fitness,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.run_circle,
                    color: Color(0xFFC95F1E),
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
                    r.title ?? r.bodyPart,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

  void _showFitnessDetail(
    BuildContext context,
    FitnessRecord record,
    AppThemeColors colors,
  ) {
    final startDt = DateTime.fromMillisecondsSinceEpoch(record.startTime);
    final endDt = DateTime.fromMillisecondsSinceEpoch(record.endTime);
    final dateStr =
        '${startDt.year}年${startDt.month}月${startDt.day}日';

    final detailItems = [
      DetailItem(
        label: '训练部位',
        value: record.bodyPart,
        icon: Icons.fitness_center,
      ),
      DetailItem(
        label: '模式',
        value: record.mode == 'professional' ? '专业' : '简单',
        icon: Icons.sports_gymnastics,
      ),
      DetailItem(
        label: '开始',
        value:
            '${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}',
        icon: Icons.play_circle_outline,
      ),
      DetailItem(
        label: '结束',
        value:
            '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}',
        icon: Icons.stop_circle_outlined,
      ),
    ];

    final noteCard = (record.note != null && record.note!.isNotEmpty)
        ? Container(
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
          )
        : null;

    RecordDetailSheet.show(
      context: context,
      title: dateStr,
      primaryMetricLabel: '训练时长',
      primaryMetricValue: '${record.durationMinutes} 分钟',
      detailItems: detailItems,
      accentColor: colors.fitness,
      extraCards: noteCard,
    );
  }

}

// =============================================================================
// 通用分析按钮
// =============================================================================

Widget _buildAnalysisButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback? onPressed,
  required AppThemeColors colors,
}) {
  return Container(
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF4D6BE8),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2E4D6BE8),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: const Text(
        '开始分析',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}

// =============================================================================
// 饮食分析 Tab
// =============================================================================
