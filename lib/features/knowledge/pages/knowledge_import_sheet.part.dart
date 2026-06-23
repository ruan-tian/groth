part of 'knowledge_workspace_page.dart';

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet({required this.initialSpace});

  final KnowledgeSpaceV3 initialSpace;

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  late KnowledgeSpaceV3 _space = widget.initialSpace;
  List<KnowledgeSpaceV3>? _spacesOverride;
  KnowledgeMaterial? _imported;
  bool _busy = false;

  @override
  void dispose() {
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchedSpaces = ref.watch(knowledgeSpacesV3Provider).valueOrNull;
    final spaces = _mergeSpaces(
      _spacesOverride ?? watchedSpaces ?? const [],
      _space,
    );
    return _SheetScaffold(
      title: _imported == null ? '导入资料' : '资料已导入',
      child: _imported == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('导入到空间', style: _T.cardTitleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _space.id,
                          items: [
                            for (final item in spaces)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                          ],
                          onChanged: (id) {
                            final target = _findSpace(spaces, id ?? _space.id);
                            if (target != null) setState(() => _space = target);
                          },
                          decoration: _inputDecoration(),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _createSpaceInsideImport,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('新建空间'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _contentController,
                          minLines: 5,
                          maxLines: 10,
                          onChanged: (_) => setState(() {}),
                          decoration:
                              _inputDecoration(
                                label: '粘贴文本或内容',
                                hint: '在此粘贴学习资料、笔记、文章、题目解析等内容，甜甜会自动解析并生成知识卡。',
                              ).copyWith(
                                alignLabelWithHint: true,
                                suffix: Text(
                                  '${_contentController.text.length} 字',
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ImportMethodButton(
                              icon: Icons.upload_file_rounded,
                              title: '文件',
                              subtitle: 'PDF/Word/TXT',
                              onTap: _pickFile,
                            ),
                            _ImportMethodButton(
                              icon: Icons.link_rounded,
                              title: '网页',
                              subtitle: '粘贴链接',
                              onTap: _importUrl,
                            ),
                            _ImportMethodButton(
                              icon: Icons.image_outlined,
                              title: '图片',
                              subtitle: 'OCR 识别',
                              onTap: _pickImage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy || _contentController.text.trim().isEmpty
                        ? null
                        : _importText,
                    style: _primaryButtonStyle(),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('开始导入'),
                  ),
                ),
              ],
            )
          : _ImportDone(
              material: _imported!,
              onGenerate: () async {
                Navigator.of(context).pop();
                await _showGenerationSheet(context, ref, _space, [_imported!]);
              },
              onLater: () => Navigator.of(context).pop(),
            ),
    );
  }

  Future<void> _importText() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _toast(context, '请先粘贴资料内容。');
      return;
    }
    await _saveMaterial(
      title: _autoMaterialTitle(content),
      content: content,
      sourceType: 'text',
    );
  }

  Future<void> _createSpaceInsideImport() async {
    final created = await _showSpaceEditor(context, ref, returnCreated: true);
    if (!mounted || created == null) return;
    final space = await ref
        .read(knowledgeV3RepositoryProvider)
        .getSpace(created);
    if (space == null) return;
    final current = ref.read(knowledgeSpacesV3Provider).valueOrNull ?? const [];
    setState(() {
      _space = space;
      _spacesOverride = _mergeSpaces(current, space);
    });
    ref.invalidate(knowledgeSpacesV3Provider);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final imported = await KnowledgeDocumentImporter().extractFromFile(
        File(path),
        ocrCallback: (imageBytes, mimeType) => ref
            .read(knowledgeV3AiServiceProvider)
            .ocrImageBytes(imageBytes: imageBytes, mimeType: mimeType),
      );
      if (!mounted) return;
      if (!imported.isSuccess) {
        _showImportError(imported, fallback: '这个文件暂时无法读取，可以试试复制文字粘贴。');
        return;
      }
      await _saveMaterial(
        title: imported.title,
        content: imported.content,
        sourceType: imported.type,
        sourcePath: imported.sourcePath,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final imported = await KnowledgeDocumentImporter().extractFromFile(
        File(path),
        ocrCallback: (imageBytes, mimeType) => ref
            .read(knowledgeV3AiServiceProvider)
            .ocrImageBytes(imageBytes: imageBytes, mimeType: mimeType),
      );
      if (!mounted) return;
      if (!imported.isSuccess) {
        _showImportError(imported, fallback: '图片文字识别失败，可以直接粘贴文字。');
        return;
      }
      await _saveMaterial(
        title: imported.title,
        content: imported.content,
        sourceType: imported.type,
        sourcePath: imported.sourcePath,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importUrl() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetScaffold(
        title: '导入网页',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('粘贴网页链接，甜甜会尝试读取正文内容。', style: _T.bodyLarge),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(hint: 'https://example.com/article'),
            ),
            const Spacer(),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton = OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: _secondaryButtonStyle(),
                  child: const Text('取消'),
                );
                final importButton = FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_urlController.text.trim()),
                  style: _primaryButtonStyle(),
                  child: const Text('抓取网页'),
                );
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      importButton,
                      const SizedBox(height: 8),
                      cancelButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 10),
                    Expanded(child: importButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    if (url == null || url.isEmpty) return;
    setState(() => _busy = true);
    try {
      final imported = await KnowledgeDocumentImporter().extractFromUrl(url);
      if (!mounted) return;
      if (!imported.isSuccess) {
        _showImportError(imported, fallback: '网页暂时无法读取，可以复制正文粘贴导入。');
        return;
      }
      await _saveMaterial(
        title: imported.title,
        content: imported.content,
        sourceType: imported.type,
        sourcePath: imported.sourcePath,
        url: url,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showImportError(
    DocumentImportResult imported, {
    required String fallback,
  }) {
    _toast(context, _compactImportError(imported.displayError ?? fallback));
  }

  Future<void> _saveMaterial({
    required String title,
    required String content,
    String sourceType = 'text',
    String? sourcePath,
    String? url,
  }) async {
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(knowledgeV3RepositoryProvider)
          .importMaterial(
            spaceId: _space.id,
            title: title,
            content: content,
            sourceType: sourceType,
            sourcePath: sourcePath,
            url: url,
          );
      final material = await ref
          .read(knowledgeV3RepositoryProvider)
          .getMaterial(id);
      if (!mounted || material == null) return;
      ref.read(selectedKnowledgeSpaceIdProvider.notifier).state = _space.id;
      await ref.read(knowledgeV3RepositoryProvider).rememberSpace(_space.id);
      invalidateKnowledgeV3(ref, spaceId: _space.id);
      setState(() => _imported = material);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ImportMethodButton extends StatelessWidget {
  const _ImportMethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.study, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.cardTitleSmall,
            ),
            const SizedBox(width: 5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.meta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportDone extends StatelessWidget {
  const _ImportDone({
    required this.material,
    required this.onGenerate,
    required this.onLater,
  });

  final KnowledgeMaterial material;
  final VoidCallback onGenerate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 10),
              Expanded(child: Text('资料已导入，可生成知识卡', style: _T.cardTitleSmall)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(material.title, style: _T.cardTitle),
              const SizedBox(height: 8),
              Text(
                '${_sizeLabel(material.content.length)} · 已保存到当前空间',
                style: _T.body,
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onGenerate,
            style: _primaryButtonStyle(),
            child: const Text('生成知识卡'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLater,
            style: _secondaryButtonStyle(),
            child: const Text('回到空间'),
          ),
        ),
      ],
    );
  }
}

