import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../utils/knowledge_card_assets.dart';

class KnowledgeSourceMetadataDraft {
  const KnowledgeSourceMetadataDraft({
    required this.title,
    required this.type,
    required this.goalKey,
    required this.moduleKey,
    this.sourcePath,
    this.goalName,
    this.moduleName,
    this.tags,
  });

  final String title;
  final String type;
  final String goalKey;
  final String moduleKey;
  final String? sourcePath;
  final String? goalName;
  final String? moduleName;
  final String? tags;
}

class KnowledgeSourceMetadataSheet extends StatefulWidget {
  const KnowledgeSourceMetadataSheet({
    super.key,
    required this.source,
    this.title = '编辑资料',
  });

  final KnowledgeSource source;
  final String title;

  static Future<KnowledgeSourceMetadataDraft?> show({
    required BuildContext context,
    required KnowledgeSource source,
    String title = '编辑资料',
  }) {
    return showModalBottomSheet<KnowledgeSourceMetadataDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          KnowledgeSourceMetadataSheet(source: source, title: title),
    );
  }

  @override
  State<KnowledgeSourceMetadataSheet> createState() =>
      _KnowledgeSourceMetadataSheetState();
}

class _KnowledgeSourceMetadataSheetState
    extends State<KnowledgeSourceMetadataSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _sourceController;
  late final TextEditingController _goalNameController;
  late final TextEditingController _moduleNameController;
  late final TextEditingController _tagsController;
  late String _type;
  late String _goalKey;
  late String _moduleKey;

  @override
  void initState() {
    super.initState();
    _goalKey = _resolveGoalKey(widget.source.goalKey);
    _moduleKey = _resolveModuleKey(_goalKey, widget.source.moduleKey);
    _type = widget.source.type;
    _titleController = TextEditingController(text: widget.source.title);
    _sourceController = TextEditingController(text: widget.source.sourcePath);
    _goalNameController = TextEditingController(text: widget.source.goalName);
    _moduleNameController = TextEditingController(
      text: widget.source.moduleName,
    );
    _tagsController = TextEditingController(text: widget.source.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    _goalNameController.dispose();
    _moduleNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final goal = KnowledgeCardAssets.goalForKey(_goalKey);
    final modules = goal.modules;
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.title,
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '这里只修改资料归类和说明，不会改动已经生成的知识卡内容。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('knowledge-source-edit-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '资料标题',
                hintText: '例如：操作系统进程管理笔记',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '资料类型'),
              items: const [
                DropdownMenuItem(value: 'markdown', child: Text('Markdown')),
                DropdownMenuItem(value: 'text', child: Text('纯文本')),
                DropdownMenuItem(value: 'paste', child: Text('粘贴内容')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: '来源说明（可选）',
                hintText: '例如：教材第 2 章、课堂笔记、文件名',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签（可选）',
                hintText: '用逗号分隔，例如：408, 高频',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: const Key('knowledge-source-edit-goal-field'),
              initialValue: _goalKey,
              decoration: const InputDecoration(labelText: '复习目标'),
              items: [
                for (final item in KnowledgeCardAssets.goalTemplates)
                  DropdownMenuItem(value: item.key, child: Text(item.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                final nextGoal = KnowledgeCardAssets.goalForKey(value);
                setState(() {
                  _goalKey = nextGoal.key;
                  _moduleKey = nextGoal.modules.first.key;
                  _goalNameController.clear();
                  _moduleNameController.clear();
                });
              },
            ),
            if (goal.key == 'custom') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _goalNameController,
                decoration: const InputDecoration(
                  labelText: '自定义目标名称（可选）',
                  hintText: '例如：蓝桥杯、期末复习、读书计划',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: ValueKey('knowledge-source-edit-module-field-$_goalKey'),
              initialValue: _moduleKey,
              decoration: const InputDecoration(labelText: '目标内模块'),
              items: [
                for (final item in modules)
                  DropdownMenuItem(value: item.key, child: Text(item.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _moduleKey = value;
                  _moduleNameController.clear();
                });
              },
            ),
            if (module.deckKey == 'custom') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _moduleNameController,
                decoration: const InputDecoration(
                  labelText: '自定义模块名称（可选）',
                  hintText: '例如：专业课、错题、论文笔记',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('knowledge-source-edit-save-button'),
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.study,
                foregroundColor: colors.textOnAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.save_rounded),
              label: const Text('保存资料设置'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('资料标题不能为空')));
      return;
    }

    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);
    Navigator.of(context).pop(
      KnowledgeSourceMetadataDraft(
        title: title,
        type: _type,
        goalKey: _goalKey,
        goalName: _goalKey == 'custom'
            ? _nullable(_goalNameController.text)
            : null,
        moduleKey: _moduleKey,
        moduleName: module.deckKey == 'custom'
            ? _nullable(_moduleNameController.text)
            : null,
        sourcePath: _nullable(_sourceController.text),
        tags: _nullable(_tagsController.text),
      ),
    );
  }

  String _resolveGoalKey(String goalKey) {
    final match = KnowledgeCardAssets.goalTemplates.any(
      (item) => item.key == goalKey,
    );
    return match ? goalKey : 'custom';
  }

  String _resolveModuleKey(String goalKey, String moduleKey) {
    final goal = KnowledgeCardAssets.goalForKey(goalKey);
    final match = goal.modules.any((item) => item.key == moduleKey);
    return match ? moduleKey : goal.modules.first.key;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
