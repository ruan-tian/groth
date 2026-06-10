part of '../pages/ai_analysis_page.dart';

class _DietAnalysisTab extends ConsumerWidget {
  const _DietAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final recentRecords = ref.watch(recentDietRecordsProvider(20));

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
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4A574),
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载饮食记录失败: $e'),
                    data: (records) {
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无饮食记录，请先添加一些饮食记录。');
                      }
                      return _buildDietDataPreview(records);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (analysisState.isLoading) ...[
                    _buildSectionTitle('分析中'),
                    const SizedBox(height: 8),
                    const _LoadingCard(),
                  ] else if (analysisState.error != null) ...[
                    _buildSectionTitle('分析失败'),
                    const SizedBox(height: 8),
                    _buildErrorCard(analysisState.error!),
                  ] else if (analysisState.result != null) ...[
                    _buildSectionTitle('分析结果'),
                    const SizedBox(height: 8),
                    _buildResultCard(analysisState.result!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: analysisState.isLoading
                  ? null
                  : () => _startDietAnalysis(ref),
              icon: const Icon(Icons.restaurant),
              label: const Text('开始分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                foregroundColor: Colors.white,
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

  Future<void> _startDietAnalysis(WidgetRef ref) async {
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
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runAnalysis(
          () => aiService.analyzeDiet(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
          ),
        );
  }

  Widget _buildDietDataPreview(List<DietRecord> records) {
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
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
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final recentRecords = ref.watch(recentSleepRecordsProvider(14));
    final weeklyAvgDuration = ref.watch(weeklyAvgSleepDurationProvider);
    final weeklyAvgQuality = ref.watch(weeklyAvgSleepQualityProvider);

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
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4A574),
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载睡眠记录失败: $e'),
                    data: (records) {
                      if (records.isEmpty) {
                        return _buildEmptyCard('暂无睡眠记录，请先添加一些睡眠记录。');
                      }
                      return _buildSleepDataPreview(
                        records,
                        weeklyAvgDuration,
                        weeklyAvgQuality,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (analysisState.isLoading) ...[
                    _buildSectionTitle('分析中'),
                    const SizedBox(height: 8),
                    const _LoadingCard(),
                  ] else if (analysisState.error != null) ...[
                    _buildSectionTitle('分析失败'),
                    const SizedBox(height: 8),
                    _buildErrorCard(analysisState.error!),
                  ] else if (analysisState.result != null) ...[
                    _buildSectionTitle('分析结果'),
                    const SizedBox(height: 8),
                    _buildResultCard(analysisState.result!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: analysisState.isLoading
                  ? null
                  : () => _startSleepAnalysis(ref),
              icon: const Icon(Icons.bedtime),
              label: const Text('开始分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                foregroundColor: Colors.white,
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

  Future<void> _startSleepAnalysis(WidgetRef ref) async {
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
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runAnalysis(
          () => aiService.analyzeSleep(
            apiKey: config.apiKey,
            baseUrl: config.baseUrl,
            model: config.modelName,
            records: records,
          ),
        );
  }

  Widget _buildSleepDataPreview(
    List<SleepRecord> records,
    AsyncValue<double?> avgDuration,
    AsyncValue<double?> avgQuality,
  ) {
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
          ],
        ),
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
    final analysisState = ref.watch(aiAnalysisStateProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

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
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4A574),
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('加载成长数据失败: $e'),
                    data: (data) => _buildGrowthDataPreview(data),
                  ),
                  const SizedBox(height: 16),
                  if (analysisState.isLoading) ...[
                    _buildSectionTitle('生成中'),
                    const SizedBox(height: 8),
                    const _LoadingCard(),
                  ] else if (analysisState.error != null) ...[
                    _buildSectionTitle('生成失败'),
                    const SizedBox(height: 8),
                    _buildErrorCard(analysisState.error!),
                  ] else if (analysisState.result != null) ...[
                    _buildSectionTitle('成长报告'),
                    const SizedBox(height: 8),
                    _buildResultCard(analysisState.result!),
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
                    onPressed: analysisState.isLoading
                        ? null
                        : () => _generateReport(ref, isWeekly: true),
                    icon: const Icon(Icons.date_range),
                    label: const Text('生成周报'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A574),
                      foregroundColor: Colors.white,
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
                    onPressed: analysisState.isLoading
                        ? null
                        : () => _generateReport(ref, isWeekly: false),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('生成月报'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A574),
                      foregroundColor: Colors.white,
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

  Future<void> _generateReport(WidgetRef ref, {required bool isWeekly}) async {
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
    await ref
        .read(aiAnalysisStateProvider.notifier)
        .runAnalysis(
          isWeekly
              ? () => aiService.generateWeeklyReport(
                  apiKey: config.apiKey,
                  baseUrl: config.baseUrl,
                  model: config.modelName,
                  weeklyData: weeklyData,
                )
              : () => aiService.generateMonthlyReport(
                  apiKey: config.apiKey,
                  baseUrl: config.baseUrl,
                  model: config.modelName,
                  monthlyData: weeklyData,
                ),
        );
  }

  Widget _buildGrowthDataPreview(DashboardData data) {
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
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
      color: Color(0xFF5C3D2E),
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
          style: const TextStyle(fontSize: 13, color: Color(0xFF8B6F5E)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C3D2E),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8C9A0).withValues(alpha: 0.3)),
    ),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 28,
              color: Color(0xFFD4A574),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8B6F5E),
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
      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget _buildResultCard(String result) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF35C976).withValues(alpha: 0.1),
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
                color: const Color(0xFF35C976).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF35C976),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '分析完成',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF35C976),
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
            color: Color(0xFF5C3D2E),
          ),
        ),
      ],
    ),
  );
}

/// 加载中卡片
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFFD4A574)),
            const SizedBox(height: 16),
            const Text(
              'AI 正在分析中，请稍候...',
              style: TextStyle(fontSize: 14, color: Color(0xFF8B6F5E)),
            ),
          ],
        ),
      ),
    );
  }
}
