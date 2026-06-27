part of 'knowledge_workspace_page.dart';

class _LibrarySheet extends ConsumerStatefulWidget {
  const _LibrarySheet({required this.space});

  final KnowledgeSpaceV3 space;

  @override
  ConsumerState<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends ConsumerState<_LibrarySheet> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(knowledgeMaterialsV3Provider(widget.space.id));
    final cards = ref.watch(knowledgeCardsV3Provider(widget.space.id));
    return _SheetScaffold(
      title: '知识库',
      child: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('资料')),
              ButtonSegment(value: 1, label: Text('知识卡')),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: _tab == 0 ? '搜索资料标题或内容' : '搜索知识卡',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: const Icon(Icons.tune_rounded),
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0
                ? materials.when(
                    data: (items) => _MaterialManageList(
                      items: _filterMaterials(items, _query),
                      onChanged: () =>
                          invalidateKnowledgeV3(ref, spaceId: widget.space.id),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('资料加载失败')),
                  )
                : cards.when(
                    data: (items) => _CardManageList(
                      items: _filterCards(items, _query),
                      fullItems: items,
                      onChanged: () =>
                          invalidateKnowledgeV3(ref, spaceId: widget.space.id),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('知识卡加载失败')),
                  ),
          ),
          const SizedBox(height: 12),
          materials.when(
            data: (items) => _LibraryPrimaryAction(
              tab: _tab,
              hasMaterials: items.isNotEmpty,
              onImport: () => _showImportSheet(context, ref, widget.space),
              onAddCard: () => _addCard(context, ref, widget.space),
              onGenerate: () async {
                if (items.isEmpty) {
                  _showImportSheet(context, ref, widget.space);
                  return;
                }
                final selected = await _confirmMaterialAction(
                  context,
                  materials: items,
                  title: '选择要生成知识卡的资料',
                  description: '甜甜将只参考你勾选的资料，自动整理核心知识点并生成抽卡复习内容。',
                  actionLabel: '确认生成',
                );
                if (!context.mounted || selected == null || selected.isEmpty) {
                  return;
                }
                await _showGenerationSheet(
                  context,
                  ref,
                  widget.space,
                  selected,
                );
                if (context.mounted) {
                  invalidateKnowledgeV3(ref, spaceId: widget.space.id);
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => _LibraryPrimaryAction(
              tab: _tab,
              hasMaterials: false,
              onImport: () => _showImportSheet(context, ref, widget.space),
              onAddCard: () => _addCard(context, ref, widget.space),
              onGenerate: () => _showImportSheet(context, ref, widget.space),
            ),
          ),
        ],
      ),
    );
  }

  List<KnowledgeMaterial> _filterMaterials(
    List<KnowledgeMaterial> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.content.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<KnowledgeCardV3> _filterCards(
    List<KnowledgeCardV3> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.question.toLowerCase().contains(q) ||
              item.answer.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }
}

class _LibraryPrimaryAction extends StatelessWidget {
  const _LibraryPrimaryAction({
    required this.tab,
    required this.hasMaterials,
    required this.onImport,
    required this.onAddCard,
    required this.onGenerate,
  });

  final int tab;
  final bool hasMaterials;
  final VoidCallback onImport;
  final VoidCallback onAddCard;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final isMaterialsTab = tab == 0;
    if (isMaterialsTab) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onImport,
          style: _primaryButtonStyle(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('\u6dfb\u52a0\u8d44\u6599'),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddCard,
            style: _secondaryButtonStyle(),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('\u624b\u52a8\u6dfb\u52a0'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onGenerate,
            style: _primaryButtonStyle(),
            icon: Icon(
              hasMaterials
                  ? Icons.auto_awesome_rounded
                  : Icons.upload_file_rounded,
            ),
            label: Text(
              hasMaterials ? 'AI \u751f\u6210' : '\u5bfc\u5165\u8d44\u6599',
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialManageList extends ConsumerWidget {
  const _MaterialManageList({required this.items, required this.onChanged});

  final List<KnowledgeMaterial> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _CenteredEmpty(title: '还没有资料', subtitle: '点击底部按钮添加资料。');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const _IconBubble(icon: Icons.description_outlined),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_sizeLabel(item.content.length)),
          onTap: () => _showMaterialDetail(context, ref, item),
          trailing: IconButton(
            tooltip: '资料操作',
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () async {
              final actions = [
                const _MenuAction(
                  value: 'view',
                  label: '查看',
                  icon: Icons.visibility_outlined,
                ),
                const _MenuAction(
                  value: 'append',
                  label: '续编',
                  icon: Icons.playlist_add_rounded,
                ),
                const _MenuAction(
                  value: 'edit',
                  label: '编辑',
                  icon: Icons.edit_rounded,
                ),
                if (index > 0)
                  const _MenuAction(
                    value: 'up',
                    label: '上移',
                    icon: Icons.arrow_upward_rounded,
                  ),
                if (index < items.length - 1)
                  const _MenuAction(
                    value: 'down',
                    label: '下移',
                    icon: Icons.arrow_downward_rounded,
                  ),
                const _MenuAction(
                  value: 'delete',
                  label: '删除',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                ),
              ];
              final value = await _showActionMenu(
                context,
                title: item.title,
                actions: actions,
              );
              if (!context.mounted || value == null) return;
              final repo = ref.read(knowledgeV3RepositoryProvider);
              if (value == 'view') {
                _showMaterialDetail(context, ref, item);
              } else if (value == 'append') {
                await _appendMaterial(context, ref, item);
                onChanged();
              } else if (value == 'edit') {
                await _editMaterial(context, ref, item);
                onChanged();
              } else if (value == 'up') {
                await repo.reorderMaterial(id: item.id, direction: -1);
                onChanged();
              } else if (value == 'down') {
                await repo.reorderMaterial(id: item.id, direction: 1);
                onChanged();
              } else if (value == 'delete') {
                final confirmed = await _confirmDelete(
                  context,
                  title: '删除资料',
                  message: '这份资料会从当前知识库移除，已生成的知识卡不会一起删除。',
                );
                if (confirmed) {
                  await repo.archiveMaterial(item.id);
                  onChanged();
                }
              }
            },
          ),
        );
      },
    );
  }
}

class _CardManageList extends ConsumerWidget {
  const _CardManageList({
    required this.items,
    required this.fullItems,
    required this.onChanged,
  });

  final List<KnowledgeCardV3> items;
  final List<KnowledgeCardV3> fullItems;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _CenteredEmpty(title: '还没有知识卡', subtitle: '先从资料生成知识卡。');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const _IconBubble(icon: Icons.style_outlined),
          title: Text(
            item.question,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.answer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _showCardDetail(context, ref, item),
          trailing: IconButton(
            tooltip: '知识卡操作',
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () async {
              final fullIndex = fullItems.indexWhere(
                (card) => card.id == item.id,
              );
              final actions = [
                const _MenuAction(
                  value: 'view',
                  label: '查看',
                  icon: Icons.visibility_outlined,
                ),
                const _MenuAction(
                  value: 'edit',
                  label: '编辑',
                  icon: Icons.edit_rounded,
                ),
                if (fullIndex > 0)
                  const _MenuAction(
                    value: 'up',
                    label: '上移',
                    icon: Icons.arrow_upward_rounded,
                  ),
                if (fullIndex >= 0 && fullIndex < fullItems.length - 1)
                  const _MenuAction(
                    value: 'down',
                    label: '下移',
                    icon: Icons.arrow_downward_rounded,
                  ),
                const _MenuAction(
                  value: 'delete',
                  label: '删除',
                  icon: Icons.delete_outline_rounded,
                  isDestructive: true,
                ),
              ];
              final value = await _showActionMenu(
                context,
                title: '知识卡操作',
                actions: actions,
              );
              if (!context.mounted || value == null) return;
              final repo = ref.read(knowledgeV3RepositoryProvider);
              if (value == 'view') {
                _showCardDetail(context, ref, item);
              } else if (value == 'edit') {
                await _editCard(context, ref, item);
                onChanged();
              } else if (value == 'up') {
                await repo.reorderCard(id: item.id, direction: -1);
                onChanged();
              } else if (value == 'down') {
                await repo.reorderCard(id: item.id, direction: 1);
                onChanged();
              } else if (value == 'delete') {
                final confirmed = await _confirmDelete(
                  context,
                  title: '删除知识卡',
                  message: '这张知识卡会从当前空间移除，复习记录保留在本地日志中。',
                );
                if (confirmed) {
                  await repo.archiveCard(item.id);
                  onChanged();
                }
              }
            },
          ),
        );
      },
    );
  }
}
