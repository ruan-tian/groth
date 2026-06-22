part of 'knowledge_workspace_page.dart';

class _QaSessionDetailSheet extends ConsumerStatefulWidget {
  const _QaSessionDetailSheet({required this.hit});

  final TiantianQaSearchHit hit;

  @override
  ConsumerState<_QaSessionDetailSheet> createState() =>
      _QaSessionDetailSheetState();
}

class _QaSessionDetailSheetState extends ConsumerState<_QaSessionDetailSheet> {
  final _followUpController = TextEditingController();

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      tiantianQaMessagesProvider(widget.hit.sessionId),
    );
    return _SheetScaffold(
      title: '问答记录',
      child: messages.when(
        data: (items) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = items[index];
                  final isUser = message.role == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.study : const Color(0xFFF7F9FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUser ? AppColors.study : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isUser ? Colors.white : AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            if (!isUser && message.savedAsCard) ...[
                              const SizedBox(height: 8),
                              _StatusPill(text: '已转成知识卡', color: AppColors.success),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _FollowUpBox(
              controller: _followUpController,
              hintText: '继续问这个话题...',
              onSend: () => _sendHistoryFollowUp(items),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorBlock(
          message: '问答记录加载失败',
          onRetry: () =>
              ref.invalidate(tiantianQaMessagesProvider(widget.hit.sessionId)),
        ),
      ),
    );
  }

  Future<void> _sendHistoryFollowUp(List<TiantianQaMessage> history) async {
    final question = _followUpController.text.trim();
    if (question.isEmpty) {
      _toast(context, '先输入要继续问的问题。');
      return;
    }
    final space = await ref.read(currentKnowledgeSpaceV3Provider.future);
    final materials = await _materialsFromHistory(history, space.id);
    if (!mounted) return;
    if (materials.isEmpty) {
      _toast(context, '这条记录缺少参考资料，请从空间主页重新选择资料提问。');
      return;
    }
    _followUpController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowUpAnswerSheet(
        space: space,
        sessionId: widget.hit.sessionId,
        question: question,
        materials: materials,
        history: history,
      ),
    );
    if (mounted) {
      ref.invalidate(tiantianQaMessagesProvider(widget.hit.sessionId));
    }
  }

  Future<List<KnowledgeMaterial>> _materialsFromHistory(
    List<TiantianQaMessage> history,
    int fallbackSpaceId,
  ) async {
    final ids = <int>{};
    for (final message in history) {
      final raw = message.sourcesJson;
      if (raw == null || raw.trim().isEmpty) continue;
      final decoded = _safeJsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map>()) {
          final id = item['id'];
          if (id is int) ids.add(id);
        }
      }
    }
    final repo = ref.read(knowledgeV3RepositoryProvider);
    final materials = <KnowledgeMaterial>[];
    for (final id in ids) {
      final material = await repo.getMaterial(id);
      if (material != null && !material.isArchived) materials.add(material);
    }
    if (materials.isNotEmpty) return materials;
    return repo.getMaterials(fallbackSpaceId);
  }
}

