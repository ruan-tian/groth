import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/task_provider.dart';
import '../../../shared/widgets/common/growth_date_picker.dart';
import '../../../shared/widgets/common/growth_time_picker.dart';
import 'task_priority.dart';

// =============================================================================
// AddTaskDialog - 添加/编辑任务对话框
// =============================================================================

class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key, this.editTask, this.initialDate});

  final DailyTask? editTask;
  final DateTime? initialDate;

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TaskPriority _priority;
  bool _saving = false;

  bool get _isEditing => widget.editTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.editTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _selectedDate = task != null
        ? DateTime.tryParse(task.taskDate) ?? DateTime.now()
        : widget.initialDate ?? DateTime.now();
    _startTime = task != null
        ? TimeOfDay(hour: task.startHour, minute: task.startMinute)
        : TimeOfDay.now();
    _endTime = task != null
        ? TimeOfDay(hour: task.endHour, minute: task.endMinute)
        : TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    _priority = task != null
        ? TaskPriority.fromValue(task.priority)
        : TaskPriority.none;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拖拽条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTitleField(),
            const SizedBox(height: 14),
            _buildDescriptionField(),
            const SizedBox(height: 14),
            _buildPriorityPicker(),
            const SizedBox(height: 14),
            _buildDatePicker(context),
            const SizedBox(height: 14),
            _buildTimePickers(context),
            const SizedBox(height: 20),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.growthColors;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
            color: colors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _isEditing ? '编辑任务' : '添加任务',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: '关闭对话框',
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return _InputField(
      label: '任务名称',
      controller: _titleController,
      hintText: '例如：英语阅读',
      icon: Icons.task_alt_rounded,
      textInputAction: TextInputAction.next,
      autofocus: !_isEditing,
    );
  }

  Widget _buildDescriptionField() {
    return _InputField(
      label: '详细描述（可选）',
      controller: _descriptionController,
      hintText: '例如：完成第三章阅读',
      icon: Icons.description_rounded,
      textInputAction: TextInputAction.newline,
      maxLines: 2,
    );
  }

  Widget _buildPriorityPicker() {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '优先级',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((p) {
            final isSelected = _priority == p;
            return Expanded(
              child: Semantics(
                button: true,
                label: '选择${p.label}优先级',
                selected: isSelected,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _priority = p);
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: p != TaskPriority.high ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? p.color.withValues(alpha: 0.15)
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? p.color : colors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? p.color : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final colors = context.growthColors;

    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr =
        '${_selectedDate.month}月${_selectedDate.day}日 ${weekdays[_selectedDate.weekday - 1]}';
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日期',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '选择日期',
          child: GestureDetector(
            onTap: () async {
              final picked = await showGrowthDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isToday ? '今天 · $dateStr' : dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!isToday)
                    Semantics(
                      button: true,
                      label: '回到今天',
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedDate = DateTime.now()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '回到今天',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickers(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时间',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                context,
                label: '开始',
                time: _startTime,
                onTimeSelected: (t) {
                  setState(() => _startTime = t);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(width: 20, height: 1, color: colors.divider),
            ),
            Expanded(
              child: _buildTimePicker(
                context,
                label: '结束',
                time: _endTime,
                onTimeSelected: (t) {
                  setState(() => _endTime = t);
                },
              ),
            ),
          ],
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
    final colors = context.growthColors;

    return Semantics(
      button: true,
      label: '选择$label时间',
      child: GestureDetector(
        onTap: () async {
          final picked = await showGrowthTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) onTimeSelected(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: colors.textTertiary),
                  ),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.growthColors;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textOnAccent,
                    ),
                  )
                : Icon(
                    _isEditing ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                  ),
            label: Text(_saving ? '保存中...' : (_isEditing ? '保存修改' : '添加任务')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final colors = context.growthColors;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入任务名称')));
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间需晚于开始时间')));
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(dailyTaskRepositoryProvider);
      final now = DateTime.now();
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final companion = DailyTasksCompanion(
        title: Value(_titleController.text.trim()),
        description: Value(
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
        taskDate: Value(dateStr),
        startHour: Value(_startTime.hour),
        startMinute: Value(_startTime.minute),
        endHour: Value(_endTime.hour),
        endMinute: Value(_endTime.minute),
        priority: Value(_priority.value),
        createdAt: Value(
          _isEditing ? widget.editTask!.createdAt : now.millisecondsSinceEpoch,
        ),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

      if (_isEditing) {
        await repo.updateTask(
          DailyTasksCompanion(
            id: Value(widget.editTask!.id),
            title: companion.title,
            description: companion.description,
            taskDate: companion.taskDate,
            startHour: companion.startHour,
            startMinute: companion.startMinute,
            endHour: companion.endHour,
            endMinute: companion.endMinute,
            priority: companion.priority,
            templateId: Value(widget.editTask!.templateId),
            sortOrder: Value(widget.editTask!.sortOrder),
            createdAt: companion.createdAt,
            updatedAt: companion.updatedAt,
          ),
        );
      } else {
        await repo.insertTask(companion);
      }

      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayIncompleteTaskCountProvider);
      ref.invalidate(tasksByDateProvider(dateStr));

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '任务已更新'
                  : '任务已添加到 ${_selectedDate.month}/${_selectedDate.day}',
            ),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction:
              textInputAction ??
              (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: colors.textHint),
            prefixIcon: Icon(icon, size: 18, color: colors.primary),
            filled: true,
            fillColor: colors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLines: maxLines,
          autofocus: autofocus,
        ),
      ],
    );
  }
}
