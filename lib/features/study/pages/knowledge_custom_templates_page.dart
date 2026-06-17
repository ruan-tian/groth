import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/knowledge_card_repository.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_assets.dart';

class KnowledgeCustomTemplatesPage extends ConsumerStatefulWidget {
  const KnowledgeCustomTemplatesPage({super.key});

  @override
  ConsumerState<KnowledgeCustomTemplatesPage> createState() =>
      _KnowledgeCustomTemplatesPageState();
}

class _KnowledgeCustomTemplatesPageState
    extends ConsumerState<KnowledgeCustomTemplatesPage> {
  /// 用于在弹窗操作后强制刷新页面
  int _refreshKey = 0;

  void _forceRefresh() {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final templates = ref.watch(knowledgeCustomTemplatesProvider);

    // ignore: unused_local_variable
    _refreshKey; // 触发 rebuild 依赖

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '自定义模板',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(knowledgeCustomTemplatesProvider),
          child: templates.when(
            data: (items) => items.isEmpty
                ? _EmptyTemplatesPanel(
                    onCreate: () => _showTemplateDialog(context, ref, onRefresh: _forceRefresh),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _TemplatesHero(
                        onCreate: () => _showTemplateDialog(context, ref, onRefresh: _forceRefresh),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (final bundle in items) ...[
                        _TemplateCard(bundle: bundle, onRefresh: _forceRefresh),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CardSkeleton(height: 360),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: ErrorRetryWidget(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateDialog(context, ref, onRefresh: _forceRefresh),
        backgroundColor: colors.study,
        foregroundColor: colors.textOnAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建模板'),
      ),
    );
  }
}

class _TemplatesHero extends StatelessWidget {
  const _TemplatesHero({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxxl),
      child: AspectRatio(
        aspectRatio: 2.33,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              KnowledgeCardAssets.customTemplateBuilderWide,
              fit: BoxFit.cover,
              cacheWidth: 900,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
            ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colors.card.withValues(alpha: 0.96),
                    colors.card.withValues(alpha: 0.72),
                    colors.card.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(AppRadius.xxxl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '搭建自己的复习模板',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '适合软考、竞赛、期末、岗位专项等不在系统模板里的目标。',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: onCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.study,
                          foregroundColor: colors.textOnAccent,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('新建模板'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.bundle, this.onRefresh});

  final KnowledgeCustomTemplateBundle bundle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final template = bundle.template;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxxl),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                template.coverAsset ?? KnowledgeCardAssets.customTemplateCover,
                fit: BoxFit.cover,
                cacheWidth: 720,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
              ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    PopupMenuButton<_TemplateAction>(
                      tooltip: '模板操作',
                      color: colors.card,
                      surfaceTintColor: colors.card,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: colors.textTertiary,
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _TemplateAction.edit:
                            _showTemplateDialog(context, ref, bundle: bundle, onRefresh: onRefresh);
                            break;
                          case _TemplateAction.archive:
                            _archiveTemplate(context, ref, template, onRefresh: onRefresh);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _TemplateAction.edit,
                          child: _MenuActionRow(
                            icon: Icons.edit_rounded,
                            label: '编辑模板',
                          ),
                        ),
                        PopupMenuItem(
                          value: _TemplateAction.archive,
                          child: _MenuActionRow(
                            icon: Icons.archive_outlined,
                            label: '归档模板',
                            color: colors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (template.description != null &&
                    template.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    template.description!,
                    style: TextStyle(color: colors.textSecondary, height: 1.4),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _TemplateMetaChip(
                      icon: Icons.view_module_rounded,
                      text: '${bundle.modules.length} 个模块',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _TemplateMetaChip(icon: Icons.style_rounded, text: '可复用建卡'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (bundle.modules.isEmpty)
                  _EmptyModuleHint(
                    onCreate: () =>
                        _showModuleDialog(context, ref, template: template, onRefresh: onRefresh),
                  )
                else
                  Column(
                    children: [
                      for (final module in bundle.modules)
                        _ModuleTile(template: template, module: module, onRefresh: onRefresh),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showModuleDialog(context, ref, template: template, onRefresh: onRefresh),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('添加模块'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TemplateAction { edit, archive }

class _ModuleTile extends ConsumerWidget {
  const _ModuleTile({required this.template, required this.module, this.onRefresh});

  final KnowledgeCustomTemplate template;
  final KnowledgeCustomTemplateModule module;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final visual = KnowledgeCardAssets.visualForKey(module.deckKey);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              visual.asset,
              width: 58,
              height: 36,
              fit: BoxFit.cover,
              cacheWidth: 180,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
            ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '封面风格：${visual.name}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '用此模块建卡',
            onPressed: () =>
                context.push(_addCardPath(template: template, module: module)),
            icon: Icon(Icons.add_card_rounded, color: colors.study),
          ),
          PopupMenuButton<_ModuleAction>(
            tooltip: '模块操作',
            color: colors.card,
            surfaceTintColor: colors.card,
            icon: Icon(Icons.more_vert_rounded, color: colors.textTertiary),
            onSelected: (action) {
              switch (action) {
                case _ModuleAction.edit:
                  _showModuleDialog(
                    context,
                    ref,
                    template: template,
                    module: module,
                  );
                  break;
                case _ModuleAction.archive:
                  _archiveModule(context, ref, module, onRefresh: onRefresh);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ModuleAction.edit,
                child: _MenuActionRow(icon: Icons.edit_rounded, label: '编辑模块'),
              ),
              PopupMenuItem(
                value: _ModuleAction.archive,
                child: _MenuActionRow(
                  icon: Icons.archive_outlined,
                  label: '归档模块',
                  color: colors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ModuleAction { edit, archive }

class _TemplateMetaChip extends StatelessWidget {
  const _TemplateMetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.study),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colors.study,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyModuleHint extends StatelessWidget {
  const _EmptyModuleHint({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.study.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.mlg),
        border: Border.all(color: colors.study.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_module_outlined, color: colors.study),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('还没有模块，先添加一个模块再用模板建卡。')),
          TextButton(onPressed: onCreate, child: const Text('添加')),
        ],
      ),
    );
  }
}

class _EmptyTemplatesPanel extends StatelessWidget {
  const _EmptyTemplatesPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              KnowledgeCardAssets.emptyCustomTemplates,
              fit: BoxFit.cover,
              cacheWidth: 900,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
            ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        EmptyStateWidget(
          icon: Icons.dashboard_customize_rounded,
          title: '还没有自定义模板',
          subtitle: '为软考、竞赛、期末或自己的专业课创建一个可复用模板。',
          accentColor: colors.study,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: colors.study,
            foregroundColor: colors.textOnAccent,
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('新建模板'),
        ),
      ],
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  const _MenuActionRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final effectiveColor = color ?? colors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: effectiveColor)),
      ],
    );
  }
}

Future<void> _showTemplateDialog(
  BuildContext context,
  WidgetRef ref, {
  KnowledgeCustomTemplateBundle? bundle,
  VoidCallback? onRefresh,
}) async {
  final colors = context.growthColors;
  final nameController = TextEditingController(text: bundle?.template.name);
  final descController = TextEditingController(
    text: bundle?.template.description ?? '',
  );
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: colors.card,
      title: Text(bundle == null ? '新建自定义模板' : '编辑自定义模板'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '模板名称',
                hintText: '例如：软考高级、蓝桥杯、期末复习',
              ),
              validator: _requiredValidator,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '说明（可选）',
                hintText: '记录考试范围、用途或阶段',
              ),
              minLines: 2,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final repo = ref.read(knowledgeCardRepositoryProvider);
            final name = nameController.text.trim();
            final description = _nullableText(descController.text);
            if (bundle == null) {
              await repo.createCustomTemplate(
                name: name,
                description: description,
                coverAsset: KnowledgeCardAssets.customTemplateCover,
              );
            } else {
              await repo.updateCustomTemplate(
                id: bundle.template.id,
                name: name,
                description: description,
                coverAsset:
                    bundle.template.coverAsset ??
                    KnowledgeCardAssets.customTemplateCover,
              );
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );

  nameController.dispose();
  descController.dispose();

  if (saved == true) {
    ref.invalidate(knowledgeCustomTemplatesProvider);
    onRefresh?.call();
  }
}

Future<void> _showModuleDialog(
  BuildContext context,
  WidgetRef ref, {
  required KnowledgeCustomTemplate template,
  KnowledgeCustomTemplateModule? module,
  VoidCallback? onRefresh,
}) async {
  final colors = context.growthColors;
  final nameController = TextEditingController(text: module?.name);
  final formKey = GlobalKey<FormState>();
  final deckVisual = KnowledgeCardAssets.visualForKey(module?.deckKey);
  var deckKey = deckVisual.key;
  
  // Debug: ensure deckKey is in the items list
  final deckKeys = KnowledgeCardAssets.decks.map((d) => d.key).toList();
  if (!deckKeys.contains(deckKey)) {
    deckKey = deckKeys.last;
  }

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        title: Text(module == null ? '添加模块' : '编辑模块'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '模块名称',
                  hintText: '例如：案例分析、论文、专业课一',
                ),
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: deckKey,
                decoration: const InputDecoration(labelText: '默认封面风格'),
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
                    setDialogState(() => deckKey = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final repo = ref.read(knowledgeCardRepositoryProvider);
              final name = nameController.text.trim();
              if (module == null) {
                await repo.createCustomTemplateModule(
                  templateId: template.id,
                  name: name,
                  deckKey: deckKey,
                );
              } else {
                await repo.updateCustomTemplateModule(
                  id: module.id,
                  name: name,
                  deckKey: deckKey,
                );
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );

  nameController.dispose();

  if (saved == true) {
    ref.invalidate(knowledgeCustomTemplatesProvider);
    onRefresh?.call();
  }
}

Future<void> _archiveTemplate(
  BuildContext context,
  WidgetRef ref,
  KnowledgeCustomTemplate template, {
  VoidCallback? onRefresh,
}) async {
  final confirmed = await _confirmArchive(
    context,
    title: '归档模板',
    message: '确定归档「${template.name}」吗？模板内模块也会一起隐藏，已有知识卡不会删除。',
  );
  if (confirmed != true) return;

  await ref
      .read(knowledgeCardRepositoryProvider)
      .archiveCustomTemplate(template.id);
  ref.invalidate(knowledgeCustomTemplatesProvider);
  onRefresh?.call();
}

Future<void> _archiveModule(
  BuildContext context,
  WidgetRef ref,
  KnowledgeCustomTemplateModule module, {
  VoidCallback? onRefresh,
}) async {
  final confirmed = await _confirmArchive(
    context,
    title: '归档模块',
    message: '确定归档「${module.name}」吗？已有知识卡不会删除。',
  );
  if (confirmed != true) return;

  await ref
      .read(knowledgeCardRepositoryProvider)
      .archiveCustomTemplateModule(module.id);
  ref.invalidate(knowledgeCustomTemplatesProvider);
  onRefresh?.call();
}

Future<bool?> _confirmArchive(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final colors = context.growthColors;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: colors.card,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: colors.danger),
          child: const Text('归档'),
        ),
      ],
    ),
  );
}

String _addCardPath({
  required KnowledgeCustomTemplate template,
  required KnowledgeCustomTemplateModule module,
}) {
  final query = Uri(
    queryParameters: {
      'goalKey': 'custom',
      'goalName': template.name,
      'moduleName': module.name,
      'deckKey': module.deckKey,
      'customTemplateId': template.id.toString(),
      'customModuleId': module.id.toString(),
    },
  ).query;
  return '/plan/study/knowledge/add?$query';
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) return '这里还没有填写';
  return null;
}

String? _nullableText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
