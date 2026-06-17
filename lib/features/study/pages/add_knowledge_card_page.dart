import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_card_repository.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

class AddKnowledgeCardPage extends ConsumerStatefulWidget {
  const AddKnowledgeCardPage({
    super.key,
    this.initialGoalKey,
    this.initialGoalName,
    this.initialModuleKey,
    this.initialModuleName,
    this.initialDeckKey,
    this.initialCustomTemplateId,
    this.initialCustomModuleId,
    this.sourceStudyId,
    this.editCardId,
  });

  final String? initialGoalKey;
  final String? initialGoalName;
  final String? initialModuleKey;
  final String? initialModuleName;
  final String? initialDeckKey;
  final int? initialCustomTemplateId;
  final int? initialCustomModuleId;
  final int? sourceStudyId;
  final int? editCardId;

  @override
  ConsumerState<AddKnowledgeCardPage> createState() =>
      _AddKnowledgeCardPageState();
}

class _AddKnowledgeCardPageState extends ConsumerState<AddKnowledgeCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _moduleNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _explanationController = TextEditingController();
  final _tagsController = TextEditingController();

  late String _goalKey;
  late String _moduleKey;
  late String _deckKey;
  int? _selectedCustomTemplateId;
  int? _selectedCustomModuleId;
  bool _saving = false;
  bool _loadingInitial = false;
  int? _sourceStudyId;
  KnowledgeCard? _editingCard;

  @override
  void initState() {
    super.initState();
    _goalKey = KnowledgeCardAssets.goalForKey(widget.initialGoalKey).key;
    final module = KnowledgeCardAssets.moduleForKeys(
      _goalKey,
      widget.initialModuleKey,
    );
    _moduleKey = module.key;
    final initialDeckKey = widget.initialDeckKey == null
        ? module.deckKey
        : KnowledgeCardAssets.visualForKey(widget.initialDeckKey).key;
    _deckKey = _effectiveDeckKeyForModule(module, initialDeckKey);
    _goalNameController.text = widget.initialGoalName ?? '';
    _moduleNameController.text = widget.initialModuleName ?? '';
    _selectedCustomTemplateId = widget.initialCustomTemplateId;
    _selectedCustomModuleId = widget.initialCustomModuleId;
    _sourceStudyId = widget.sourceStudyId;
    if (widget.editCardId != null || widget.sourceStudyId != null) {
      _loadingInitial = true;
      Future.microtask(_loadInitialData);
    }
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _moduleNameController.dispose();
    _subjectController.dispose();
    _titleController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final customTemplates = ref.watch(knowledgeCustomTemplatesProvider);
    final customTemplateItems = customTemplates.valueOrNull;
    final selectedTemplateModule = _selectedCustomTemplateModule(
      customTemplateItems,
    );
    final goal = KnowledgeCardAssets.goalForKey(_goalKey);
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);
    final deckKey = _effectiveDeckKeyForModule(module, _deckKey);
    final visual = KnowledgeCardAssets.visualForKey(deckKey);
    final editing = _editingCard != null;
    final usesCustomGoal = _goalKey == 'custom';
    final usesCustomModule = module.deckKey == 'custom';
    final lockDeckStyle = !usesCustomModule || selectedTemplateModule != null;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          editing ? '编辑知识卡' : '添加知识卡',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!editing)
            IconButton(
              tooltip: '批量导入',
              onPressed: () => context.push(_bulkImportPath()),
              icon: Icon(Icons.upload_file_rounded, color: colors.study),
            ),
        ],
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: _loadingInitial
            ? Center(child: CircularProgressIndicator(color: colors.study))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _CoverPreview(
                      goal: goal,
                      deckVisual: visual,
                      goalName: _effectiveGoalName(goal),
                      moduleName: _effectiveModuleName(module),
                    ),
                    if (_sourceStudyId != null && !editing) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SourceNotice(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _FormCard(
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey('goal-$_goalKey'),
                          initialValue: _goalKey,
                          decoration: _decoration(context, '复习目标模板'),
                          dropdownColor: colors.card,
                          items: KnowledgeCardAssets.goalTemplates
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.key,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value != null) _selectGoal(value);
                          },
                        ),
                        if (usesCustomGoal) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _goalNameController,
                            decoration: _decoration(
                              context,
                              '自定义目标名称',
                              hint: '例如：蓝桥杯备考、软考、期末复习',
                            ),
                            validator: _customGoalValidator,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (usesCustomGoal)
                          customTemplates.when(
                            data: (items) => _CustomTemplatePickers(
                              templates: items,
                              selectedTemplateId: _selectedCustomTemplateId,
                              selectedModuleId: _selectedCustomModuleId,
                              onTemplateChanged: _selectCustomTemplate,
                              onModuleChanged: _selectCustomTemplateModule,
                              onManageTemplates: () => context.push(
                                '/plan/study/knowledge/templates',
                              ),
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => _InlineNotice(
                              icon: Icons.info_outline_rounded,
                              text: '自定义模板暂时读取失败，可以先手动填写目标和模块。',
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            key: ValueKey('module-$_goalKey-$_moduleKey'),
                            initialValue: _moduleKey,
                            decoration: _decoration(context, '目标下的子模块'),
                            dropdownColor: colors.card,
                            items: goal.modules
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.key,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) _selectModule(value);
                            },
                          ),
                        if (usesCustomModule &&
                            selectedTemplateModule == null) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _moduleNameController,
                            decoration: _decoration(
                              context,
                              '模块名称（可选）',
                              hint: '例如：408 数据结构、岗位专业知识、专业课一',
                            ),
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (!lockDeckStyle)
                          DropdownButtonFormField<String>(
                            key: ValueKey(_deckKey),
                            initialValue: _deckKey,
                            decoration: _decoration(context, '卡片封面风格（自定义模块可选）'),
                            dropdownColor: colors.card,
                            items: KnowledgeCardAssets.decks
                                .map(
                                  (deck) => DropdownMenuItem(
                                    value: deck.key,
                                    child: Text(deck.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _deckKey = value);
                              }
                            },
                          )
                        else
                          _LockedDeckStyleTile(
                            visual: visual,
                            moduleName:
                                selectedTemplateModule?.name ??
                                _effectiveModuleName(module),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _subjectController,
                          decoration: _decoration(
                            context,
                            '章节 / 知识单元（可选）',
                            hint: '例如：第二章 进程管理、民法总则、资料分析速算',
                            suffixIcon: usesCustomModule
                                ? IconButton(
                                    tooltip: '根据章节和标题匹配封面',
                                    onPressed: _matchDeckFromChapter,
                                    icon: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: colors.study,
                                    ),
                                  )
                                : null,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _titleController,
                          decoration: _decoration(context, '知识点标题'),
                          validator: _requiredValidator,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _questionController,
                          decoration: _decoration(
                            context,
                            '卡片正面问题',
                            hint: '例如：进程和线程有什么区别？',
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _answerController,
                          decoration: _decoration(
                            context,
                            '卡片背面答案',
                            hint: '写下你希望复习时回忆出的答案',
                          ),
                          minLines: 4,
                          maxLines: 8,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _explanationController,
                          decoration: _decoration(
                            context,
                            '补充解释（可选）',
                            hint: '例子、易错点、关联知识',
                          ),
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _tagsController,
                          decoration: _decoration(
                            context,
                            '标签（可选）',
                            hint: '用逗号分隔，例如：408, 高频, 易错',
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SubmitButton(
                      saving: _saving,
                      editing: editing,
                      onTap: _saving ? null : _saveCard,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    if (widget.editCardId != null) {
      await _loadEditingCard(widget.editCardId!);
    } else if (widget.sourceStudyId != null) {
      await _loadSourceStudyRecord(widget.sourceStudyId!);
    }
    if (mounted) setState(() => _loadingInitial = false);
  }

  Future<void> _loadEditingCard(int cardId) async {
    final card = await ref
        .read(knowledgeCardRepositoryProvider)
        .getCardById(cardId);
    if (!mounted) return;
    if (card == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有找到这张知识卡')));
      Navigator.of(context).pop();
      return;
    }

    _editingCard = card;
    _goalKey = KnowledgeCardAssets.goalForKey(card.goalKey).key;
    _selectedCustomTemplateId = null;
    _selectedCustomModuleId = null;
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, card.moduleKey);
    _goalNameController.text =
        card.goalName ?? (_goalKey == 'custom' ? '自定义目标' : '');
    _moduleKey = module.key;
    _moduleNameController.text =
        card.moduleName ??
        (module.deckKey == 'custom' ? card.subject ?? '自定义模块' : '');
    _deckKey = _effectiveDeckKeyForModule(
      module,
      KnowledgeCardAssets.visualForKey(card.deckKey).key,
    );
    _sourceStudyId = card.sourceStudyId;
    _subjectController.text = card.subject ?? '';
    _titleController.text = card.title;
    _questionController.text = card.question;
    _answerController.text = card.answer;
    _explanationController.text = card.explanation ?? '';
    _tagsController.text = _decodeTags(card.tags).join('，');
  }

  Future<void> _loadSourceStudyRecord(int studyId) async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.studyRecords)
      ..where((t) => t.id.equals(studyId));
    final record = await query.getSingleOrNull();
    if (!mounted || record == null) return;

    _sourceStudyId = record.id;
    _goalKey = 'custom';
    _selectedCustomTemplateId = null;
    _selectedCustomModuleId = null;
    _goalNameController.text = '学习记录复习';
    _moduleKey = 'custom';
    _moduleNameController.text = record.subject ?? '学习记录';
    _deckKey = KnowledgeCardAssets.keyForSubject(record.subject);
    _subjectController.text = record.chapter ?? '';
    _titleController.text = record.title;
    _questionController.text = '请回忆「${record.title}」的核心知识点是什么？';
    _answerController.text = record.gain ?? '';
    _explanationController.text = [
      if (record.problem != null && record.problem!.isNotEmpty)
        '遗留问题：${record.problem}',
      if (record.note != null && record.note!.isNotEmpty) '备注：${record.note}',
    ].join('\n\n');
    _tagsController.text = [
      if (record.subject != null && record.subject!.isNotEmpty) record.subject!,
      if (record.chapter != null && record.chapter!.isNotEmpty) record.chapter!,
    ].join('，');
  }

  KnowledgeCustomTemplateBundle? _selectedCustomTemplate(
    List<KnowledgeCustomTemplateBundle>? templates,
  ) {
    final id = _selectedCustomTemplateId;
    if (id == null || templates == null) return null;
    for (final item in templates) {
      if (item.template.id == id) return item;
    }
    return null;
  }

  KnowledgeCustomTemplateModule? _selectedCustomTemplateModule(
    List<KnowledgeCustomTemplateBundle>? templates,
  ) {
    final moduleId = _selectedCustomModuleId;
    final template = _selectedCustomTemplate(templates);
    if (moduleId == null || template == null) return null;
    for (final module in template.modules) {
      if (module.id == moduleId) return module;
    }
    return null;
  }

  void _matchDeckFromChapter() {
    final text = [
      _moduleNameController.text,
      _subjectController.text,
      _titleController.text,
    ].join(' ');
    final nextKey = KnowledgeCardAssets.keyForSubject(text);
    setState(() => _deckKey = nextKey);
  }

  void _selectGoal(String value) {
    final goal = KnowledgeCardAssets.goalForKey(value);
    final module = goal.modules.first;
    setState(() {
      _goalKey = goal.key;
      _moduleKey = module.key;
      _deckKey = _effectiveDeckKeyForModule(module, _deckKey);
      _selectedCustomTemplateId = null;
      _selectedCustomModuleId = null;
      if (goal.key != 'custom') {
        _goalNameController.clear();
      }
      if (module.deckKey != 'custom') {
        _moduleNameController.clear();
      }
    });
  }

  void _selectModule(String value) {
    final goal = KnowledgeCardAssets.goalForKey(_goalKey);
    final module = goal.modules.firstWhere(
      (item) => item.key == value,
      orElse: () => goal.modules.first,
    );
    setState(() {
      _moduleKey = module.key;
      _deckKey = _effectiveDeckKeyForModule(module, _deckKey);
      _selectedCustomTemplateId = null;
      _selectedCustomModuleId = null;
      if (module.deckKey != 'custom') {
        _moduleNameController.clear();
      }
    });
  }

  void _selectCustomTemplate(KnowledgeCustomTemplateBundle? bundle) {
    setState(() {
      _goalKey = 'custom';
      _moduleKey = 'custom';
      if (bundle == null) {
        _selectedCustomTemplateId = null;
        _selectedCustomModuleId = null;
        return;
      }

      _selectedCustomTemplateId = bundle.template.id;
      _goalNameController.text = bundle.template.name;
      final firstModule = bundle.modules.isEmpty ? null : bundle.modules.first;
      _selectCustomTemplateModuleValue(firstModule);
    });
  }

  void _selectCustomTemplateModule(KnowledgeCustomTemplateModule? module) {
    setState(() => _selectCustomTemplateModuleValue(module));
  }

  void _selectCustomTemplateModuleValue(KnowledgeCustomTemplateModule? module) {
    if (module == null) {
      _selectedCustomModuleId = null;
      _moduleNameController.clear();
      return;
    }
    _moduleKey = 'custom';
    _selectedCustomModuleId = module.id;
    _moduleNameController.text = module.name;
    _deckKey = KnowledgeCardAssets.visualForKey(module.deckKey).key;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return '这里还没有填写';
    return null;
  }

  String? _customGoalValidator(String? value) {
    if (_goalKey == 'custom' && (value == null || value.trim().isEmpty)) {
      return '给自定义目标起个名字';
    }
    return null;
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final goal = KnowledgeCardAssets.goalForKey(_goalKey);
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);
    final deckKey = _effectiveDeckKeyForModule(module, _deckKey);
    final goalName = _goalKey == 'custom'
        ? _nullableText(_goalNameController.text)
        : null;
    final moduleName = module.deckKey == 'custom'
        ? _nullableText(_moduleNameController.text)
        : null;
    final tags = _tagsController.text
        .split(RegExp(r'[,，、\s]+'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);

    final card = KnowledgeCardsCompanion(
      deckKey: Value(deckKey),
      goalKey: Value(goal.key),
      goalName: Value(goalName),
      moduleKey: Value(module.key),
      moduleName: Value(moduleName),
      subject: Value(_nullableText(_subjectController.text)),
      title: Value(_titleController.text.trim()),
      question: Value(_questionController.text.trim()),
      answer: Value(_answerController.text.trim()),
      explanation: Value(_nullableText(_explanationController.text)),
      tags: Value(tags.isEmpty ? null : jsonEncode(tags)),
      sourceStudyId: Value(_sourceStudyId),
      dueAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    try {
      final repo = ref.read(knowledgeCardRepositoryProvider);
      final editingCard = _editingCard;
      if (editingCard == null) {
        await repo.insertCard(card);
      } else {
        await repo.updateCardContent(
          id: editingCard.id,
          deckKey: deckKey,
          goalKey: goal.key,
          goalName: goalName,
          moduleKey: module.key,
          moduleName: moduleName,
          subject: _nullableText(_subjectController.text),
          title: _titleController.text.trim(),
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
          explanation: _nullableText(_explanationController.text),
          tags: tags.isEmpty ? null : jsonEncode(tags),
        );
      }
      ref.invalidate(knowledgeCardsProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
      ref.invalidate(knowledgeDeckSummariesProvider);
      ref.invalidate(dueKnowledgeCardsCountProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editingCard == null ? '知识卡已添加' : '知识卡已更新')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _bulkImportPath() {
    final goal = KnowledgeCardAssets.goalForKey(_goalKey);
    final module = KnowledgeCardAssets.moduleForKeys(_goalKey, _moduleKey);
    final params = <String, String>{
      'goalKey': goal.key,
      'moduleKey': module.key,
      'deckKey': _effectiveDeckKeyForModule(module, _deckKey),
    };
    final goalName = goal.key == 'custom'
        ? _nullableText(_goalNameController.text)
        : null;
    if (goalName != null) params['goalName'] = goalName;
    final moduleName = module.deckKey == 'custom'
        ? _nullableText(_moduleNameController.text)
        : null;
    if (moduleName != null) params['moduleName'] = moduleName;
    final subject = _nullableText(_subjectController.text);
    if (subject != null) params['subject'] = subject;
    return '/plan/study/knowledge/import?${Uri(queryParameters: params).query}';
  }

  String _effectiveDeckKeyForModule(
    KnowledgeGoalModuleVisual module,
    String preferredKey,
  ) {
    if (module.deckKey != 'custom') return module.deckKey;
    return KnowledgeCardAssets.visualForKey(preferredKey).key;
  }

  String _effectiveGoalName(KnowledgeGoalVisual goal) {
    if (goal.key != 'custom') return goal.name;
    final customName = _nullableText(_goalNameController.text);
    return customName ?? goal.name;
  }

  String _effectiveModuleName(KnowledgeGoalModuleVisual module) {
    if (module.deckKey != 'custom') return module.name;
    final customName = _nullableText(_moduleNameController.text);
    return customName ?? module.name;
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  InputDecoration _decoration(
    BuildContext context,
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    final colors = context.growthColors;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        borderSide: BorderSide(color: colors.study, width: 1.4),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.goal,
    required this.deckVisual,
    required this.goalName,
    required this.moduleName,
  });

  final KnowledgeGoalVisual goal;
  final KnowledgeDeckVisual deckVisual;
  final String goalName;
  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(goal.asset, fit: BoxFit.cover, cacheWidth: 900),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _PreviewPill(text: goalName, strong: true),
                      _PreviewPill(text: moduleName),
                      _PreviewPill(text: deckVisual.name),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.text, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: strong
              ? colors.study.withValues(alpha: 0.22)
              : colors.border.withValues(alpha: 0.70),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: strong ? colors.study : colors.textPrimary,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _LockedDeckStyleTile extends StatelessWidget {
  const _LockedDeckStyleTile({required this.visual, required this.moduleName});

  final KnowledgeDeckVisual visual;
  final String moduleName;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: colors.study, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '卡片封面风格：${visual.name}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '由「$moduleName」模块自动决定，避免目标模板内风格混乱。',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTemplatePickers extends StatelessWidget {
  const _CustomTemplatePickers({
    required this.templates,
    required this.selectedTemplateId,
    required this.selectedModuleId,
    required this.onTemplateChanged,
    required this.onModuleChanged,
    required this.onManageTemplates,
  });

  final List<KnowledgeCustomTemplateBundle> templates;
  final int? selectedTemplateId;
  final int? selectedModuleId;
  final ValueChanged<KnowledgeCustomTemplateBundle?> onTemplateChanged;
  final ValueChanged<KnowledgeCustomTemplateModule?> onModuleChanged;
  final VoidCallback onManageTemplates;

  @override
  Widget build(BuildContext context) {
    final selectedTemplate = _templateForId(selectedTemplateId);

    if (templates.isEmpty) {
      return _InlineNotice(
        icon: Icons.dashboard_customize_rounded,
        text: '还没有保存的自定义模板，可以手动填写，也可以先去模板库创建。',
        actionLabel: '管理模板',
        onAction: onManageTemplates,
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<int?>(
          key: ValueKey('custom-template-$selectedTemplateId'),
          initialValue: selectedTemplate?.template.id,
          decoration: const InputDecoration(labelText: '使用已保存模板（可选）'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('不使用模板，手动填写'),
            ),
            for (final item in templates)
              DropdownMenuItem<int?>(
                value: item.template.id,
                child: Text(item.template.name),
              ),
          ],
          onChanged: (value) => onTemplateChanged(_templateForId(value)),
        ),
        if (selectedTemplate != null) ...[
          const SizedBox(height: AppSpacing.md),
          if (selectedTemplate.modules.isEmpty)
            _InlineNotice(
              icon: Icons.view_module_outlined,
              text: '这个模板还没有模块，可以先手动填写模块，或回模板库添加模块。',
              actionLabel: '管理模板',
              onAction: onManageTemplates,
            )
          else
            DropdownButtonFormField<int?>(
              key: ValueKey(
                'custom-module-${selectedTemplate.template.id}-$selectedModuleId',
              ),
              initialValue: _moduleForId(
                selectedTemplate,
                selectedModuleId,
              )?.id,
              decoration: const InputDecoration(labelText: '模板内模块'),
              items: [
                for (final module in selectedTemplate.modules)
                  DropdownMenuItem<int?>(
                    value: module.id,
                    child: Text(module.name),
                  ),
              ],
              onChanged: (value) =>
                  onModuleChanged(_moduleForId(selectedTemplate, value)),
            ),
        ],
      ],
    );
  }

  KnowledgeCustomTemplateBundle? _templateForId(int? id) {
    if (id == null) return null;
    for (final item in templates) {
      if (item.template.id == id) return item;
    }
    return null;
  }

  KnowledgeCustomTemplateModule? _moduleForId(
    KnowledgeCustomTemplateBundle template,
    int? id,
  ) {
    if (id == null) return null;
    for (final module in template.modules) {
      if (module.id == id) return module;
    }
    return null;
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.study.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.study, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.textSecondary, height: 1.35),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SourceNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.study.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_rounded, color: colors.study, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '已从学习记录带入目标、章节和笔记，你只需要补齐问题与答案。',
              style: TextStyle(color: colors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.saving,
    required this.editing,
    required this.onTap,
  });

  final bool saving;
  final bool editing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.study,
          foregroundColor: colors.textOnAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mlg),
          ),
          elevation: 0,
        ),
        icon: saving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textOnAccent,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(saving ? '保存中' : (editing ? '更新知识卡' : '保存知识卡')),
      ),
    );
  }
}
