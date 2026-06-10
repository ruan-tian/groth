import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/task_provider.dart';
import 'task_priority.dart';

// =============================================================================
// AddTaskDialog - 添加/编辑任务对话框
// =============================================================================

class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key, this.editTask});

  final DailyTask? editTask;

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
        : DateTime.now();
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F0), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C3D2E).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildPriorityPicker(),
                const SizedBox(height: 16),
                _buildDatePicker(context),
                const SizedBox(height: 16),
                _buildTimePickers(context),
                const SizedBox(height: 24),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
            color: const Color(0xFF5D68F2),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _isEditing ? '编辑任务' : '添加任务',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C3D2E),
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: '关闭对话框',
          child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF8B6F5E),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '优先级',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B6F5E),
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
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? p.color : const Color(0xFFE8E8E8),
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
                          color: isSelected ? p.color : AppColors.textSecondary,
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
        const Text(
          '日期',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B6F5E),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '选择日期',
          child: GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Color(0xFFD4A574),
                ),
                const SizedBox(width: 12),
                Text(
                  isToday ? '今天 · $dateStr' : dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5C3D2E),
                  ),
                ),
                const Spacer(),
                if (!isToday)
                  Semantics(
                    button: true,
                    label: '回到今天',
                    child: GestureDetector(
                    onTap: () => setState(() => _selectedDate = DateTime.now()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1DF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '回到今天',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF88681A),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '时间',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B6F5E),
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
              child: Container(
                width: 20,
                height: 1,
                color: const Color(0xFFE8C9A0),
              ),
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
    return Semantics(
      button: true,
      label: '选择$label时间',
      child: GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onTimeSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: Color(0xFFD4A574),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFB0A09A),
                  ),
                ),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3D2E),
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE8C9A0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('取消', style: TextStyle(color: Color(0xFF8B6F5E))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isEditing ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                  ),
            label: Text(_saving ? '保存中...' : (_isEditing ? '保存修改' : '添加任务')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFD4A574),
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入任务名称')));
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
            backgroundColor: const Color(0xFF35C976),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B6F5E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFC9CDD4)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFFD4A574)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD4A574),
                width: 1.5,
              ),
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
