part of 'knowledge_workspace_page.dart';

class _GenerationSheet extends ConsumerStatefulWidget {
  const _GenerationSheet({required this.space, required this.materials});

  final KnowledgeSpaceV3 space;
  final List<KnowledgeMaterial> materials;

  @override
  ConsumerState<_GenerationSheet> createState() => _GenerationSheetState();
}

class _GenerationSheetState extends ConsumerState<_GenerationSheet> {
  bool _invalidated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(knowledgeGenerationControllerProvider.notifier)
          .start(space: widget.space, materials: widget.materials);
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(knowledgeGenerationControllerProvider);
    final controller = ref.read(knowledgeGenerationControllerProvider.notifier);
    return _SheetScaffold(
      title: '生成知识卡',
      child: _buildJob(context, job, controller),
    );
  }

  Widget _buildJob(
    BuildContext context,
    KnowledgeGenerationJobState job,
    KnowledgeGenerationController controller,
  ) {
    if (job.isRunning) {
      return _GenerationProgressView(progress: job.progress);
    }
    if (job.error != null) {
      final needsAiConfig = _needsAiConfig(job.error);
      return _ErrorBlock(
        message: _friendlyAiError(job.error),
        retryLabel: '返回',
        onRetry: () => Navigator.of(context).pop(),
        secondaryLabel: needsAiConfig ? '去配置 AI' : null,
        onSecondary: needsAiConfig ? () => context.push('/ai-config') : null,
      );
    }
    final count = job.resultIds?.length ?? job.progress.savedCount;
    if (!_invalidated) {
      _invalidated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) invalidateKnowledgeV3(ref, spaceId: widget.space.id);
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TiantianImage(asset: 'tiantian_success.webp', size: 92),
        const SizedBox(height: 16),
        Text('已生成 $count 张知识卡', style: _T.cardTitle),
        const SizedBox(height: 8),
        const Text('现在可以开始抽卡复习。', style: _T.body),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              controller.clearCompleted();
              Navigator.of(context).pop();
              _openReview(context, widget.space);
            },
            style: _primaryButtonStyle(),
            child: const Text('开始抽卡'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              controller.clearCompleted();
              Navigator.of(context).pop();
            },
            style: _secondaryButtonStyle(),
            child: const Text('回到空间'),
          ),
        ),
      ],
    );
  }
}

class _GenerationProgressView extends StatelessWidget {
  const _GenerationProgressView({required this.progress});

  final KnowledgeGenerationProgress progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.value * 100).round().clamp(1, 99);
    return Center(
      child: _PaperCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TiantianImage(asset: 'tiantian_focus.webp', size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(progress.message, style: _T.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        progress.materialTitle == null
                            ? '后台生成中，可以先返回空间继续浏览'
                            : '正在处理：${progress.materialTitle}',
                        style: _T.body,
                      ),
                    ],
                  ),
                ),
                Text('$percent%', style: _T.metric),
              ],
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: progress.value,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AppColors.softBlue,
              color: AppColors.study,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusPill(
                  text: _generationStageLabel(progress.stage),
                  color: progress.fallback
                      ? AppColors.warning
                      : AppColors.study,
                ),
                const SizedBox(width: 8),
                Text('已保存 ${progress.savedCount} 张', style: _T.metaStrong),
              ],
            ),
            if (progress.fallback) ...[
              const SizedBox(height: 10),
              Text('结构化输出不稳定，甜甜已自动切换兼容生成，不影响最终保存。', style: _T.body),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: _secondaryButtonStyle(height: 46),
                child: const Text('后台生成，先返回'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _generationStageLabel(String stage) {
  return switch (stage) {
    'prepare' => '准备资料',
    'outline' => '分析结构',
    'plan' => '制定计划',
    'cards' => '生成卡片',
    'save' => '保存卡片',
    'fallback' || 'fallback_cards' => '兼容生成',
    'backfill' => '查漏补卡',
    'done' => '完成',
    _ => '生成中',
  };
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      onTap: onTap,
      child: Row(
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _T.cardTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: _T.body),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
