import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/design/design.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/providers/task_provider.dart';

/// 任务模板对话框
///
/// 显示用户的任务模板列表，支持：
/// - 选择模板快速创建任务
/// - 创建新模板
/// - 编辑/删除模板
class TaskTemplateDialog extends ConsumerStatefulWidget {
  const TaskTemplateDialog({super.key});

  @override
  ConsumerState<TaskTemplateDialog> createState() => _TaskTemplateDialogState();
}

class _TaskTemplateDialogState extends ConsumerState<TaskTemplateDialog> {
  bool _showCreateForm = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(taskTemplatesProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.library_books, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          const Text('任务模板'),
          const Spacer(),
          IconButton(
            icon: Icon(_showCreateForm ? Icons.list : Icons.add),
            onPressed: () {
              setState(() => _showCreateForm = !_showCreateForm);
            },
            tooltip: _showCreateForm ? '查看模板' : '创建模板',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _showCreateForm
            ? const _CreateTemplateForm()
            : _TemplateList(
                templatesAsync: templatesAsync,
                onTemplateSelected: (template) => _useTemplate(template),
                onTemplateDeleted: (template) => _deleteTemplate(template),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// 使用模板创建任务
  void _useTemplate(TaskTemplate template) async {
    final repo = ref.read(taskTemplateRepositoryProvider);
    await repo.incrementUsageCount(template.id);
    ref.invalidate(taskTemplatesProvider);
    ref.invalidate(popularTemplatesProvider);

    if (mounted) {
      Navigator.pop(context, template);
    }
  }

  /// 删除模板
  void _deleteTemplate(TaskTemplate template) async {
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

    if (confirmed == true && mounted) {
      final repo = ref.read(taskTemplateRepositoryProvider);
      await repo.deleteTemplate(template.id);
      ref.invalidate(taskTemplatesProvider);
      ref.invalidate(popularTemplatesProvider);
    }
  }
}

// =============================================================================
// _TemplateList - 模板列表
// =============================================================================

class _TemplateList extends StatelessWidget {
  const _TemplateList({
    required this.templatesAsync,
    required this.onTemplateSelected,
    required this.onTemplateDeleted,
  });

  final AsyncValue<List<TaskTemplate>> templatesAsync;
  final ValueChanged<TaskTemplate> onTemplateSelected;
  final ValueChanged<TaskTemplate> onTemplateDeleted;

  @override
  Widget build(BuildContext context) {
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
                  '点击右上角 + 创建模板',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _TemplateTile(
              template: template,
              onTap: () => onTemplateSelected(template),
              onDelete: () => onTemplateDeleted(template),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

// =============================================================================
// _TemplateTile - 单个模板
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.task_alt,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(template.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.description != null && template.description!.isNotEmpty)
              Text(
                template.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${_formatTime(template.defaultStartHour, template.defaultStartMinute)}'
              ' - '
              '${_formatTime(template.defaultEndHour, template.defaultEndMinute)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '使用 ${template.usageCount} 次',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: theme.colorScheme.error,
              ),
              onPressed: onDelete,
              tooltip: '删除模板',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// _CreateTemplateForm - 创建模板表单
// =============================================================================

class _CreateTemplateForm extends ConsumerStatefulWidget {
  const _CreateTemplateForm();

  @override
  ConsumerState<_CreateTemplateForm> createState() => _CreateTemplateFormState();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '创建新模板',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // 模板名称
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '模板名称 *',
            hintText: '例如：晨间学习',
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 模板描述
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '模板描述',
            hintText: '例如：每天早上学习新技能',
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
                label: '开始时间',
                time: _startTime,
                onTimeSelected: (time) {
                  setState(() => _startTime = time);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildTimePicker(
                context,
                label: '结束时间',
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
              : const Icon(Icons.save),
          label: Text(_saving ? '保存中...' : '保存模板'),
        ),
      ],
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
          suffixIcon: const Icon(Icons.access_time),
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
        // 清空表单
        _nameController.clear();
        _descriptionController.clear();
        setState(() {
          _startTime = const TimeOfDay(hour: 9, minute: 0);
          _endTime = const TimeOfDay(hour: 10, minute: 0);
        });

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
