part of 'knowledge_workspace_page.dart';

class _SpaceEditorSheet extends ConsumerStatefulWidget {
  const _SpaceEditorSheet({this.space, required this.returnCreated});

  final KnowledgeSpaceV3? space;
  final bool returnCreated;

  @override
  ConsumerState<_SpaceEditorSheet> createState() => _SpaceEditorSheetState();
}

class _SpaceEditorSheetState extends ConsumerState<_SpaceEditorSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.space?.name ?? '',
  );
  late final TextEditingController _noteController = TextEditingController(
    text: widget.space?.note ?? '',
  );
  late String _type = widget.space?.type ?? 'exam';

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.space;
    return _SheetScaffold(
      title: space == null ? '新建空间' : '编辑空间',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(label: '空间名称', hint: '例如：考公、考研英语'),
          ),
          const SizedBox(height: 14),
          const Text('空间类型', style: _T.cardTitleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                ('exam', '备考'),
                ('language', '语言学习'),
                ('skill', '职业技能'),
                ('interest', '兴趣知识'),
                ('custom', '自定义'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: _type == item.$1,
                  onSelected: (_) => setState(() => _type = item.$1),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(
              label: '一句话备注（可选）',
              hint: '用于快速记住这个空间的用途',
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: _primaryButtonStyle(),
              child: Text(space == null ? '创建并进入' : '保存'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast(context, '请填写空间名称。');
      return;
    }
    final repo = ref.read(knowledgeV3RepositoryProvider);
    final space = widget.space;
    if (space == null) {
      final id = await repo.createSpace(
        name: name,
        type: _type,
        note: _noteController.text,
      );
      await repo.rememberSpace(id);
      ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = id;
      invalidateKnowledgeV3(ref, spaceId: id);
      if (mounted) Navigator.of(context).pop(widget.returnCreated ? id : null);
      return;
    }
    await repo.renameSpace(
      id: space.id,
      name: name,
      type: _type,
      note: _noteController.text,
    );
    await repo.rememberSpace(space.id);
    invalidateKnowledgeV3(ref, spaceId: space.id);
    if (mounted) Navigator.of(context).pop();
  }
}

