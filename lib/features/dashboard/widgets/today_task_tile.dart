import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import 'task_priority.dart';

// =============================================================================
// TaskSlidable - 带滑动操作的任务项
// =============================================================================

class TaskSlidable extends StatelessWidget {
  const TaskSlidable({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
    required this.onReschedule,
    required this.onEdit,
    required this.onSetPriority,
  });

  final DailyTask task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onReschedule;
  final VoidCallback onEdit;
  final ValueChanged<TaskPriority> onSetPriority;

  @override
  Widget build(BuildContext context) {
    final priority = TaskPriority.fromValue(task.priority);

    return Slidable(
      key: ValueKey('task_${task.id}'),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onComplete(),
            backgroundColor: task.isCompleted
                ? const Color(0xFFFF8A3D)
                : const Color(0xFF35C976),
            foregroundColor: Colors.white,
            icon: task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
            label: task.isCompleted ? '恢复' : '完成',
            borderRadius: BorderRadius.circular(0),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.4,
        dismissible: DismissiblePane(onDismissed: onDelete),
        children: [
          SlidableAction(
            onPressed: (_) => onReschedule(),
            backgroundColor: const Color(0xFFFF8A3D),
            foregroundColor: Colors.white,
            icon: Icons.calendar_today_rounded,
            label: '改期',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: const Color(0xFFFF4D4F),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: '删除',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Semantics(
        label: '${task.title}，长按显示操作菜单',
        button: true,
        child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: _TaskTile(task: task, priority: priority, onToggle: onComplete),
      ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _ContextMenuItem(
              icon: Icons.edit_rounded,
              label: '编辑任务',
              color: const Color(0xFF5D68F2),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            _ContextMenuItem(
              icon: Icons.calendar_today_rounded,
              label: '改期',
              color: const Color(0xFFFF8A3D),
              onTap: () {
                Navigator.pop(ctx);
                onReschedule();
              },
            ),
            _ContextMenuItem(
              icon: Icons.flag_rounded,
              label: '设置优先级',
              color: const Color(0xFFFF4D4F),
              onTap: () {
                Navigator.pop(ctx);
                _showPriorityPicker(context);
              },
            ),
            if (!task.isCompleted)
              _ContextMenuItem(
                icon: Icons.check_circle_outline_rounded,
                label: '标记完成',
                color: const Color(0xFF35C976),
                onTap: () {
                  Navigator.pop(ctx);
                  onComplete();
                },
              ),
            _ContextMenuItem(
              icon: Icons.delete_outline_rounded,
              label: '删除任务',
              color: const Color(0xFFFF4D4F),
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '设置优先级',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...TaskPriority.values.map(
              (p) => ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: p.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(p.label),
                trailing: task.priority == p.value
                    ? const Icon(Icons.check_rounded, color: Color(0xFF35C976))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSetPriority(p);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? color : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.priority,
    required this.onToggle,
  });

  final DailyTask task;
  final TaskPriority priority;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = task.startHour * 60 + task.startMinute;
    final endMinutes = task.endHour * 60 + task.endMinute;

    final isCompleted = task.isCompleted;
    final isInProgress =
        !isCompleted &&
        startMinutes <= currentMinutes &&
        endMinutes >= currentMinutes;
    final isOverdue = !isCompleted && endMinutes < currentMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF8F8FB) : const Color(0xFFFFFCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFE9E9F0)
              : priority.color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFD0D5DD) : priority.color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: isCompleted ? '恢复任务' : '完成任务',
            button: true,
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: isCompleted
                      ? const Color(0xFF35C976)
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF35C976)
                        : const Color(0xFFD0D5DD),
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textTertiary,
                  ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isInProgress) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '进行中',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8A3D),
                      ),
                    ),
                  ),
                ] else if (isOverdue) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '已过期',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF4D4F),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(task.startHour, task.startMinute),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isCompleted
                      ? AppColors.textTertiary
                      : const Color(0xFF6E6384),
                ),
              ),
              Text(
                _formatTime(task.endHour, task.endMinute),
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted
                      ? AppColors.textTertiary.withValues(alpha: 0.6)
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
