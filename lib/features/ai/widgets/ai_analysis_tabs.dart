part of '../pages/ai_analysis_page.dart';

class _StudyAnalysisTab extends ConsumerWidget {
  const _StudyAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final inputData = ref.watch(aiAnalysisInputProvider);
    final knowledgeContext = ref.watch(knowledgeContextServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 数据预览
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
                        color: context.growthColors.primary,
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载学习记录失败: $e'),
                    data: (input) {
                      final records = input.studyRecords;
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无学习记录，请先添加一些学习记录。');
                      }
                      return FutureBuilder<KnowledgeContextBundle>(
                        future: knowledgeContext.buildForStudyRecords(records),
                        builder: (context, snapshot) {
                          final bundle = snapshot.data;
                          return _buildStudyDataPreview(
                            context,
                            records,
                            bundle: bundle,
                            isLoadingContext:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          );
                        },
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
                      referenceContext: analysisState.referenceContext,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 分析按钮
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (analysisState.isLoading || analysisState.isStreaming)
                  ? null
                  : () => _startStudyAnalysis(context, ref),
              icon: const Icon(Icons.psychology),
              label: const Text('开始分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.growthColors.primary,
                foregroundColor: context.growthColors.textOnAccent,
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
    final knowledgeContext = ref.read(knowledgeContextServiceProvider);
    final bundle = await knowledgeContext.buildForStudyRecords(records);
    if (!context.mounted) return;
    final confirmedBundle = await showKnowledgeContextConfirmSheet(
      context: context,
      bundle: bundle,
    );
    if (confirmedBundle == null) return;
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runStreamAnalysis(
          () => aiService.analyzeStudyStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
            knowledgeContext: confirmedBundle.toPromptSection(),
          ),
          referenceContext: confirmedBundle,
        );
  }

  Widget _buildStudyDataPreview(
    BuildContext context,
    List<StudyRecord> records, {
    KnowledgeContextBundle? bundle,
    bool isLoadingContext = false,
  }) {
    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, size: 20),
                const SizedBox(width: 8),
                Text(
                  '最近 ${records.length} 条学习记录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('总学习时长', '$totalMinutes 分钟'),
            _buildInfoRow('记录条数', '${records.length} 条'),
            ..._buildKnowledgeContextRows(bundle, isLoading: isLoadingContext),
            const SizedBox(height: 8),
            ...records.take(3).map((r) {
              final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.book, size: 20),
                title: Text(r.title),
                subtitle: Text(
                  '${date.month}/${date.day} · ${r.durationMinutes}分钟'
                  '${r.subject != null ? ' · ${r.subject}' : ''}',
                ),
              );
            }),
            if (records.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... 还有 ${records.length - 3} 条记录',
                  style: TextStyle(
                    color: context.growthColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
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
                  inputData.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: context.growthColors.primary,
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载健身记录失败: $e'),
                    data: (input) {
                      final records = input.fitnessRecords;
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无健身记录，请先添加一些训练记录。');
                      }
                      final query = _fitnessContextQuery(records);
                      return FutureBuilder<KnowledgeContextBundle>(
                        future: knowledgeContext.buildForQuery(query),
                        builder: (context, snapshot) {
                          return _buildFitnessDataPreview(
                            context,
                            records,
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
                  : () => _startFitnessAnalysis(context, ref),
              icon: const Icon(Icons.fitness_center),
              label: const Text('开始分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.growthColors.primary,
                foregroundColor: context.growthColors.textOnAccent,
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
    final knowledgeContext = ref.read(knowledgeContextServiceProvider);
    final bundle = await knowledgeContext.buildForQuery(
      _fitnessContextQuery(records),
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
          () => aiService.analyzeFitnessStream(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
            knowledgeContext: confirmedBundle.toPromptSection(),
          ),
          referenceContext: confirmedBundle,
        );
  }

  Widget _buildFitnessDataPreview(
    BuildContext context,
    List<FitnessRecord> records, {
    KnowledgeContextBundle? bundle,
    bool isLoadingContext = false,
  }) {
    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    // 按部位分组
    final bodyPartCount = <String, int>{};
    for (final r in records) {
      bodyPartCount[r.bodyPart] = (bodyPartCount[r.bodyPart] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, size: 20),
                const SizedBox(width: 8),
                Text(
                  '最近 ${records.length} 条健身记录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('总训练时长', '$totalMinutes 分钟'),
            _buildInfoRow('训练次数', '${records.length} 次'),
            _buildInfoRow('训练部位', bodyPartCount.keys.join('、')),
            ..._buildKnowledgeContextRows(bundle, isLoading: isLoadingContext),
            const SizedBox(height: 8),
            ...records.take(3).map((r) {
              final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.run_circle, size: 20),
                title: Text(r.title ?? r.bodyPart),
                subtitle: Text(
                  '${date.month}/${date.day} · ${r.durationMinutes}分钟'
                  '${r.intensityLevel != null ? ' · 强度${r.intensityLevel}/5' : ''}',
                ),
              );
            }),
            if (records.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... 还有 ${records.length - 3} 条记录',
                  style: TextStyle(
                    color: context.growthColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fitnessContextQuery(List<FitnessRecord> records) {
    return _joinContextTerms([
      '健身 训练 恢复 强度 动作',
      for (final record in records.take(8)) record.bodyPart,
      for (final record in records.take(8)) record.title,
    ]);
  }
}

// =============================================================================
// 饮食分析 Tab
// =============================================================================