part of 'knowledge_workspace_page.dart';

class _AnswerSheet extends ConsumerStatefulWidget {
  const _AnswerSheet({
    required this.space,
    required this.question,
    required this.materials,
  });

  final KnowledgeSpaceV3 space;
  final String question;
  final List<KnowledgeMaterial> materials;

  @override
  ConsumerState<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<_AnswerSheet> {
  late final Future<TiantianAnswer> _future = ref
      .read(knowledgeV3AiServiceProvider)
      .answerQuestion(
        space: widget.space,
        question: widget.question,
        materials: widget.materials,
      );
  final _followUpController = TextEditingController();

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '甜甜问答',
      child: FutureBuilder<TiantianAnswer>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _WorkingState(text: '甜甜正在阅读你选择的资料...');
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final answer = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.question, style: _T.cardTitle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(answer.answer, style: _T.answer),
                    const SizedBox(height: 18),
                    const Text('参考资料', style: _T.sectionTitle),
                    const SizedBox(height: 8),
                    for (final material in widget.materials)
                      _ReferenceTile(material: material),
                  ],
                ),
              ),
              _SaveAnswerAsCardButton(space: widget.space, answer: answer),
              const SizedBox(height: 10),
              _FollowUpBox(
                controller: _followUpController,
                hintText: '继续问甜甜...',
                onSend: () => _sendFollowUp(answer),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendFollowUp(TiantianAnswer answer) async {
    final question = _followUpController.text.trim();
    if (question.isEmpty) {
      _toast(context, '先输入要继续问的问题。');
      return;
    }
    final history = await ref.read(
      tiantianQaMessagesProvider(answer.sessionId).future,
    );
    if (!mounted) return;
    _followUpController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowUpAnswerSheet(
        space: widget.space,
        sessionId: answer.sessionId,
        question: question,
        materials: widget.materials,
        history: history,
      ),
    );
    if (mounted) {
      ref.invalidate(tiantianQaMessagesProvider(answer.sessionId));
    }
  }
}

class _FollowUpBox extends StatelessWidget {
  const _FollowUpBox({
    required this.controller,
    required this.hintText,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

class _FollowUpAnswerSheet extends ConsumerStatefulWidget {
  const _FollowUpAnswerSheet({
    required this.space,
    required this.sessionId,
    required this.question,
    required this.materials,
    required this.history,
  });

  final KnowledgeSpaceV3 space;
  final int sessionId;
  final String question;
  final List<KnowledgeMaterial> materials;
  final List<TiantianQaMessage> history;

  @override
  ConsumerState<_FollowUpAnswerSheet> createState() =>
      _FollowUpAnswerSheetState();
}

class _FollowUpAnswerSheetState extends ConsumerState<_FollowUpAnswerSheet> {
  late final Future<TiantianAnswer> _future = ref
      .read(knowledgeV3AiServiceProvider)
      .continueQuestion(
        space: widget.space,
        sessionId: widget.sessionId,
        question: widget.question,
        materials: widget.materials,
        history: widget.history,
      );

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '甜甜继续回答',
      child: FutureBuilder<TiantianAnswer>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _WorkingState(text: '甜甜正在接着想...');
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final answer = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.question, style: _T.cardTitle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(answer.answer, style: _T.answer),
                    const SizedBox(height: 18),
                    const Text('参考资料', style: _T.sectionTitle),
                    const SizedBox(height: 8),
                    for (final material in widget.materials)
                      _ReferenceTile(material: material),
                  ],
                ),
              ),
              _SaveAnswerAsCardButton(space: widget.space, answer: answer),
            ],
          );
        },
      ),
    );
  }
}

class _SaveAnswerAsCardButton extends ConsumerStatefulWidget {
  const _SaveAnswerAsCardButton({required this.space, required this.answer});

  final KnowledgeSpaceV3 space;
  final TiantianAnswer answer;

  @override
  ConsumerState<_SaveAnswerAsCardButton> createState() =>
      _SaveAnswerAsCardButtonState();
}

class _SaveAnswerAsCardButtonState
    extends ConsumerState<_SaveAnswerAsCardButton> {
  bool _saving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _saving || _saved ? null : _save,
        style: _primaryButtonStyle(),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_saved ? Icons.check_circle_rounded : Icons.style_rounded),
        label: Text(_saved ? '已转成知识卡' : '把这段回答做成知识卡'),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final ids = await ref
          .read(knowledgeV3AiServiceProvider)
          .saveAnswerAsCards(space: widget.space, answer: widget.answer);
      invalidateKnowledgeV3(ref, spaceId: widget.space.id);
      if (!mounted) return;
      setState(() => _saved = true);
      _toast(context, '已保存 ${ids.length} 张知识卡。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TiantianAskRequest {
  const _TiantianAskRequest({required this.question, required this.materials});

  final String question;
  final List<KnowledgeMaterial> materials;
}

class _TiantianAskComposerSheet extends StatefulWidget {
  const _TiantianAskComposerSheet({
    required this.initialQuestion,
    required this.materials,
  });

  final String initialQuestion;
  final List<KnowledgeMaterial> materials;

  @override
  State<_TiantianAskComposerSheet> createState() =>
      _TiantianAskComposerSheetState();
}

class _TiantianAskComposerSheetState extends State<_TiantianAskComposerSheet> {
  late final TextEditingController _questionController = TextEditingController(
    text: widget.initialQuestion.trim(),
  );
  late final Set<int> _selected = widget.materials
      .map((item) => item.id)
      .toSet();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '问甜甜',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _questionController,
            minLines: 3,
            maxLines: 5,
            autofocus: _questionController.text.isEmpty,
            decoration: _inputDecoration(
              label: '你想问什么？',
              hint: '例如：这份资料里最容易混淆的点是什么？',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Text('参考资料', style: _T.cardTitleSmall)),
              TextButton(
                onPressed: () => setState(() {
                  _selected
                    ..clear()
                    ..addAll(widget.materials.map((item) => item.id));
                }),
                child: const Text('全选'),
              ),
              TextButton(
                onPressed: () => setState(_selected.clear),
                child: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '发送前请确认。已选择 ${_selected.length} 份资料，甜甜只会使用这些资料回答。',
            style: _T.body,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final material in widget.materials)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(material.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(material.id);
                        } else {
                          _selected.remove(material.id);
                        }
                      });
                    },
                    title: Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_sizeLabel(material.content.length)),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _submit,
              style: _primaryButtonStyle(),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('确认并提问'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _toast(context, '先问甜甜一个问题吧。');
      return;
    }
    Navigator.of(context).pop(
      _TiantianAskRequest(
        question: question,
        materials: widget.materials
            .where((item) => _selected.contains(item.id))
            .toList(growable: false),
      ),
    );
  }
}

class _AiResultSheet extends StatefulWidget {
  const _AiResultSheet({
    required this.title,
    required this.workingText,
    required this.future,
    this.successActionLabel,
    this.onSuccessAction,
  });

  final String title;
  final String workingText;
  final Future<String> future;
  final String? successActionLabel;
  final VoidCallback? onSuccessAction;

  @override
  State<_AiResultSheet> createState() => _AiResultSheetState();
}

class _AiResultSheetState extends State<_AiResultSheet> {
  late final Future<String> _future = widget.future;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: widget.title,
      child: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _WorkingState(text: widget.workingText);
          }
          if (snapshot.hasError) {
            final needsAiConfig = _needsAiConfig(snapshot.error);
            return _ErrorBlock(
              message: _friendlyAiError(snapshot.error),
              retryLabel: '返回',
              onRetry: () => Navigator.of(context).pop(),
              secondaryLabel: needsAiConfig ? '去配置 AI' : null,
              onSecondary: needsAiConfig
                  ? () => context.push('/ai-config')
                  : null,
            );
          }
          final content = snapshot.data?.trim() ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content.isEmpty ? '甜甜没有整理出有效内容，请稍后重试。' : content,
                    style: _T.answer,
                  ),
                ),
              ),
              if (widget.successActionLabel != null &&
                  widget.onSuccessAction != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onSuccessAction,
                    style: _primaryButtonStyle(),
                    child: Text(widget.successActionLabel!),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.material});

  final KnowledgeMaterial material;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(material.title, style: _T.cardTitleSmall),
      subtitle: Text(_sizeLabel(material.content.length), style: _T.meta),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_preview(material.content, max: 600), style: _T.body),
        ),
      ],
    );
  }
}
