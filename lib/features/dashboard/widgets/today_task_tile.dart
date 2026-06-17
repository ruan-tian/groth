import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
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
    final colors = context.growthColors;

    return Slidable(
      key: ValueKey('task_${task.id}'),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onComplete(),
            backgroundColor: task.isCompleted ? colors.warning : colors.success,
            foregroundColor: colors.textOnAccent,
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
            backgroundColor: colors.warning,
            foregroundColor: colors.textOnAccent,
            icon: Icons.calendar_today_rounded,
            label: '改期',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colors.danger,
            foregroundColor: colors.textOnAccent,
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
          child: _TaskTile(
            task: task,
            priority: priority,
            onToggle: onComplete,
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.heavyImpact();
    final colors = context.growthColors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: colors.card),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _ContextMenuItem(
              icon: Icons.edit_rounded,
              label: '编辑任务',
              color: colors.primary,
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            _ContextMenuItem(
              icon: Icons.calendar_today_rounded,
              label: '改期',
              color: colors.warning,
              onTap: () {
                Navigator.pop(ctx);
                onReschedule();
              },
            ),
            _ContextMenuItem(
              icon: Icons.flag_rounded,
              label: '设置优先级',
              color: colors.danger,
              onTap: () {
                Navigator.pop(ctx);
                _showPriorityPicker(context);
              },
            ),
            if (!task.isCompleted)
              _ContextMenuItem(
                icon: Icons.check_circle_outline_rounded,
                label: '标记完成',
                color: colors.success,
                onTap: () {
                  Navigator.pop(ctx);
                  onComplete();
                },
              ),
            _ContextMenuItem(
              icon: Icons.delete_outline_rounded,
              label: '删除任务',
              color: colors.danger,
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
    final colors = context.growthColors;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: colors.card),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '设置优先级',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
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
                    ? Icon(Icons.check_rounded, color: colors.success)
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
    final colors = context.growthColors;

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? color : colors.textPrimary,
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
    final colors = context.growthColors;
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
        color: isCompleted ? colors.surfaceVariant : colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? colors.border
              : priority.color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted ? colors.border : priority.color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: isCompleted ? '恢复任务' : '完成任务',
            button: true,
            child: GestureDetector(
              onTap: onToggle,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: isCompleted ? colors.success : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? colors.success : colors.border,
                        width: 1.5,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: colors.textOnAccent,
                          )
                        : null,
                  ),
                ),
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
                        ? colors.textTertiary
                        : colors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textTertiary,
                  ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
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
                      color: colors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '进行中',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.warning,
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
                      color: colors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '已过期',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.danger,
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
                GrowthDateUtils.formatTime(task.startHour, task.startMinute),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isCompleted
                      ? colors.textTertiary
                      : colors.textSecondary,
                ),
              ),
              Text(
                GrowthDateUtils.formatTime(task.endHour, task.endMinute),
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted
                      ? colors.textTertiary.withValues(alpha: 0.6)
                      : colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
