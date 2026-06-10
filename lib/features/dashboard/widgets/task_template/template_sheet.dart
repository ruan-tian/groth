import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/design/design.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/providers/task_provider.dart';

/// 任务模板底部弹窗
///
/// 紧凑美观的模板选择界面
class TaskTemplateSheet extends ConsumerStatefulWidget {
  const TaskTemplateSheet({super.key});

  @override
  ConsumerState<TaskTemplateSheet> createState() => _TaskTemplateSheetState();
}

class _TaskTemplateSheetState extends ConsumerState<TaskTemplateSheet> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(taskTemplatesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // ── 拖拽指示器 ──
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── 标题栏 ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '任务模板',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    // 创建模板按钮
                    IconButton(
                      icon: Icon(
                        _isCreating ? Icons.list : Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() => _isCreating = !_isCreating);
                      },
                      iconSize: 22,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── 内容区域 ──
              Expanded(
                child: _isCreating
                    ? _CreateTemplateForm(
                        onCreated: () {
                          setState(() => _isCreating = false);
                        },
                      )
                    : _TemplateList(
                        scrollController: scrollController,
                        templatesAsync: templatesAsync,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// _TemplateList - 模板列表
// =============================================================================

class _TemplateList extends ConsumerWidget {
  const _TemplateList({
    required this.scrollController,
    required this.templatesAsync,
  });

  final ScrollController scrollController;
  final AsyncValue<List<TaskTemplate>> templatesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 48,
                  color: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '暂无模板',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '点击右上角 + 创建常用任务模板',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _TemplateTile(
              template: template,
              onTap: () => _useTemplate(context, ref, template),
              onDelete: () => _deleteTemplate(context, ref, template),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  /// 使用模板
  void _useTemplate(
    BuildContext context,
    WidgetRef ref,
    TaskTemplate template,
  ) async {
    final repo = ref.read(taskTemplateRepositoryProvider);
    await repo.incrementUsageCount(template.id);
    ref.invalidate(taskTemplatesProvider);
    ref.invalidate(popularTemplatesProvider);

    if (context.mounted) {
      Navigator.pop(context, template);
    }
  }

  /// 删除模板
  Future<void> _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    TaskTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除「${template.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(taskTemplateRepositoryProvider);
      await repo.deleteTemplate(template.id);
      ref.invalidate(taskTemplatesProvider);
      ref.invalidate(popularTemplatesProvider);
    }
  }
}

// =============================================================================
// _TemplateTile - 单个模板（紧凑设计）
// =============================================================================

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  final TaskTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(
                  Icons.task_alt,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (template.description != null &&
                        template.description!.isNotEmpty)
                      Text(
                        template.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // 时间
              Text(
                '${_formatTime(template.defaultStartHour, template.defaultStartMinute)}'
                '-'
                '${_formatTime(template.defaultEndHour, template.defaultEndMinute)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // 删除按钮
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// _CreateTemplateForm - 创建模板表单（紧凑设计）
// =============================================================================

class _CreateTemplateForm extends ConsumerStatefulWidget {
  const _CreateTemplateForm({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateTemplateForm> createState() =>
      _CreateTemplateFormState();
}

class _CreateTemplateFormState extends ConsumerState<_CreateTemplateForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 模板名称
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '模板名称 *',
              hintText: '例如：晨间学习',
              isDense: true,
            ),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // 模板描述
          TextField(
            controller: _descriptionController,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              hintText: '例如：每天早上学习新技能',
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),

          // 时间选择
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  context,
                  label: '开始',
                  time: _startTime,
                  onTimeSelected: (time) {
                    setState(() => _startTime = time);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
              ),
              Expanded(
                child: _buildTimePicker(
                  context,
                  label: '结束',
                  time: _endTime,
                  onTimeSelected: (time) {
                    setState(() => _endTime = time);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 保存按钮
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? '保存中...' : '保存模板'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onTimeSelected,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time, size: 18),
          isDense: true,
        ),
        child: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模板名称')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(taskTemplateRepositoryProvider);
      final now = DateTime.now();

      await repo.insertTemplate(
        TaskTemplatesCompanion(
          name: Value(_nameController.text.trim()),
          description: Value(_descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim()),
          defaultStartHour: Value(_startTime.hour),
          defaultStartMinute: Value(_startTime.minute),
          defaultEndHour: Value(_endTime.hour),
          defaultEndMinute: Value(_endTime.minute),
          createdAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

      ref.invalidate(taskTemplatesProvider);
      ref.invalidate(popularTemplatesProvider);

      if (mounted) {
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
