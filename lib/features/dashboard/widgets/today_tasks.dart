import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/task_provider.dart';

// =============================================================================
// TaskPriority - 优先级枚举
// =============================================================================

enum TaskPriority {
  none(0, '无', Color(0xFFD0D5DD)),
  low(1, '低', Color(0xFF5D68F2)),
  medium(2, '中', Color(0xFFFF8A3D)),
  high(3, '高', Color(0xFFFF4D4F));

  const TaskPriority(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static TaskPriority fromValue(int v) =>
      TaskPriority.values.firstWhere((p) => p.value == v, orElse: () => none);
}

// =============================================================================
// TodayTasks Widget - 分组式待办事项列表
// =============================================================================

class TodayTasks extends ConsumerStatefulWidget {
  const TodayTasks({super.key});

  @override
  ConsumerState<TodayTasks> createState() => _TodayTasksState();
}

class _TodayTasksState extends ConsumerState<TodayTasks>
    with SingleTickerProviderStateMixin {
  bool _showCompleted = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B6F5E).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 标题行 + 进度条 ──
              _buildHeader(context, tasksAsync),
              // ── 任务分组列表 ──
              tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) return _buildEmptyState();
                  return _buildTaskSections(tasks);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('加载失败: $e')),
                ),
              ),
              // ── 添加任务按钮 ──
              _buildAddTaskButton(context),
            ],
          ),
        ),
        // ── 庆祝动画 ──
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF5D68F2),
              Color(0xFF35C976),
              Color(0xFFFF8A3D),
              Color(0xFFFF7EAA),
              Color(0xFFFFD700),
            ],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 标题行 + 进度条
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
      BuildContext context, AsyncValue<List<DailyTask>> tasksAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checklist_rounded,
                    size: 16, color: Color(0xFF5D68F2)),
              ),
              const SizedBox(width: 10),
              const Text('今日任务',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              tasksAsync.when(
                data: (tasks) {
                  final completed = tasks.where((t) => t.isCompleted).length;
                  final total = tasks.length;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 完成计数
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: completed == total && total > 0
                              ? const Color(0xFF35C976).withValues(alpha: 0.1)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$completed/$total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: completed == total && total > 0
                                ? const Color(0xFF35C976)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 8),
                        // 百分比
                        Text(
                          '${(completed / total * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5D68F2),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 进度条
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) return const SizedBox.shrink();
              final completed = tasks.where((t) => t.isCompleted).length;
              final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? const Color(0xFF35C976)
                        : const Color(0xFF5D68F2),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.task_alt,
                size: 40,
                color: AppColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('暂无任务',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('点击下方按钮添加今天的计划',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 任务分组列表
  // ---------------------------------------------------------------------------

  Widget _buildTaskSections(List<DailyTask> tasks) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final inProgress = <DailyTask>[];
    final upcoming = <DailyTask>[];
    final completed = <DailyTask>[];

    for (final task in tasks) {
      if (task.isCompleted) {
        completed.add(task);
      } else {
        final startM = task.startHour * 60 + task.startMinute;
        final endM = task.endHour * 60 + task.endMinute;
        if (startM <= currentMinutes && endM >= currentMinutes) {
          inProgress.add(task);
        } else {
          upcoming.add(task);
        }
      }
    }

    // Sort: in-progress by start time, upcoming by start time
    inProgress.sort((a, b) =>
        (a.startHour * 60 + a.startMinute)
            .compareTo(b.startHour * 60 + b.startMinute));
    upcoming.sort((a, b) =>
        (a.startHour * 60 + a.startMinute)
            .compareTo(b.startHour * 60 + b.startMinute));
    // Completed: most recently completed first (by start time desc)
    completed.sort((a, b) =>
        (b.startHour * 60 + b.startMinute)
            .compareTo(a.startHour * 60 + a.startMinute));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 进行中 ──
        if (inProgress.isNotEmpty)
          _buildSection(
            label: '进行中',
            icon: Icons.play_circle_outline_rounded,
            color: const Color(0xFFFF8A3D),
            tasks: inProgress,
            showDivider: true,
          ),

        // ── 待开始 ──
        if (upcoming.isNotEmpty)
          _buildSection(
            label: '待开始',
            icon: Icons.schedule_rounded,
            color: const Color(0xFF5D68F2),
            tasks: upcoming,
            showDivider: completed.isNotEmpty,
          ),

        // ── 已完成 ──
        if (completed.isNotEmpty)
          _buildCompletedSection(completed),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 单个分组
  // ---------------------------------------------------------------------------

  Widget _buildSection({
    required String label,
    required IconData icon,
    required Color color,
    required List<DailyTask> tasks,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${tasks.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _TaskSlidable(
              task: task,
              onComplete: () => _toggleTask(ref, task),
              onDelete: () => _deleteTask(ref, task),
              onReschedule: () => _rescheduleTask(context, ref, task),
              onEdit: () => _editTask(context, ref, task),
              onSetPriority: (p) => _setPriority(ref, task, p),
            )),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 已完成分组（可折叠）
  // ---------------------------------------------------------------------------

  Widget _buildCompletedSection(List<DailyTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _showCompleted = !_showCompleted);
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: Color(0xFF35C976)),
                const SizedBox(width: 6),
                const Text('已完成',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF35C976))),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF35C976).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${tasks.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF35C976))),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showCompleted ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _showCompleted
              ? Column(
                  children: tasks
                      .take(5)
                      .map((task) => _TaskSlidable(
                            task: task,
                            onComplete: () => _toggleTask(ref, task),
                            onDelete: () => _deleteTask(ref, task),
                            onReschedule: () =>
                                _rescheduleTask(context, ref, task),
                            onEdit: () => _editTask(context, ref, task),
                            onSetPriority: (p) =>
                                _setPriority(ref, task, p),
                          ))
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 添加任务按钮
  // ---------------------------------------------------------------------------

  Widget _buildAddTaskButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddTaskDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: Color(0xFF5D68F2)),
            SizedBox(width: 6),
            Text('添加任务',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D68F2))),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 任务操作
  // ---------------------------------------------------------------------------

  Future<void> _toggleTask(WidgetRef ref, DailyTask task) async {
    final repo = ref.read(dailyTaskRepositoryProvider);
    final newCompleted = !task.isCompleted;
    await repo.toggleTaskCompletion(task.id, newCompleted);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayIncompleteTaskCountProvider);
    HapticFeedback.mediumImpact();

    // 检查是否全部完成
    if (newCompleted) {
      final tasks = await repo.getTodayTasks();
      if (tasks.isNotEmpty && tasks.every((t) => t.isCompleted)) {
        _confettiController.play();
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _deleteTask(WidgetRef ref, DailyTask task) async {
    final repo = ref.read(dailyTaskRepositoryProvider);
    await repo.deleteTask(task.id);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayIncompleteTaskCountProvider);
    HapticFeedback.lightImpact();
  }

  Future<void> _rescheduleTask(
      BuildContext context, WidgetRef ref, DailyTask task) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;

    final dateStr =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    final repo = ref.read(dailyTaskRepositoryProvider);
    await repo.updateTask(DailyTasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      taskDate: Value(dateStr),
      startHour: Value(task.startHour),
      startMinute: Value(task.startMinute),
      endHour: Value(task.endHour),
      endMinute: Value(task.endMinute),
      isCompleted: Value(task.isCompleted),
      priority: Value(task.priority),
      templateId: Value(task.templateId),
      sortOrder: Value(task.sortOrder),
      createdAt: Value(task.createdAt),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayIncompleteTaskCountProvider);
    HapticFeedback.lightImpact();
  }

  Future<void> _setPriority(
      WidgetRef ref, DailyTask task, TaskPriority priority) async {
    final repo = ref.read(dailyTaskRepositoryProvider);
    await repo.updateTaskPriority(task.id, priority.value);
    ref.invalidate(todayTasksProvider);
    HapticFeedback.lightImpact();
  }

  void _editTask(BuildContext context, WidgetRef ref, DailyTask task) {
    showDialog(
      context: context,
      builder: (ctx) => _AddTaskDialog(editTask: task),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddTaskDialog(),
    );
  }
}

// =============================================================================
// _TaskSlidable - 带滑动操作的任务项
// =============================================================================

class _TaskSlidable extends StatelessWidget {
  const _TaskSlidable({
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
      // 右滑 → 完成/取消完成
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
            icon: task.isCompleted
                ? Icons.undo_rounded
                : Icons.check_rounded,
            label: task.isCompleted ? '恢复' : '完成',
            borderRadius: BorderRadius.circular(0),
          ),
        ],
      ),
      // 左滑 → 改期 + 删除
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
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: _TaskTile(
          task: task,
          priority: priority,
          onToggle: onComplete,
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
            Text(task.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
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
            const Text('设置优先级',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...TaskPriority.values.map((p) => ListTile(
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
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ContextMenuItem
// =============================================================================

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

// =============================================================================
// _TaskTile - 单个任务项
// =============================================================================

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
        !isCompleted && startMinutes <= currentMinutes && endMinutes >= currentMinutes;
    final isOverdue =
        !isCompleted && endMinutes < currentMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFFAFAFA) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 0.4),
        ),
      ),
      child: Row(
        children: [
          // ── 优先级色条 ──
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFD0D5DD)
                  : priority.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // ── 复选框 ──
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
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
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // ── 任务内容 ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textTertiary,
                  ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(task.description!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (isInProgress) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('进行中',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF8A3D))),
                  ),
                ] else if (isOverdue) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('已过期',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF4D4F))),
                  ),
                ],
              ],
            ),
          ),

          // ── 时间 ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(task.startHour, task.startMinute),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? AppColors.textTertiary
                      : const Color(0xFF8B6F5E),
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

// =============================================================================
// _AddTaskDialog - 添加/编辑任务对话框
// =============================================================================

class _AddTaskDialog extends ConsumerStatefulWidget {
  const _AddTaskDialog({this.editTask});

  final DailyTask? editTask;

  @override
  ConsumerState<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<_AddTaskDialog> {
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
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _selectedDate = task != null
        ? DateTime.tryParse(task.taskDate) ?? DateTime.now()
        : DateTime.now();
    _startTime = task != null
        ? TimeOfDay(hour: task.startHour, minute: task.startMinute)
        : TimeOfDay.now();
    _endTime = task != null
        ? TimeOfDay(hour: task.endHour, minute: task.endMinute)
        : TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    _priority =
        task != null ? TaskPriority.fromValue(task.priority) : TaskPriority.none;
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
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF8B6F5E)),
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
      autofocus: !_isEditing,
    );
  }

  Widget _buildDescriptionField() {
    return _InputField(
      label: '详细描述（可选）',
      controller: _descriptionController,
      hintText: '例如：完成第三章阅读',
      icon: Icons.description_rounded,
      maxLines: 2,
    );
  }

  // ---------------------------------------------------------------------------
  // 优先级选择器
  // ---------------------------------------------------------------------------

  Widget _buildPriorityPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('优先级',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B6F5E))),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((p) {
            final isSelected = _priority == p;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _priority = p);
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                      right: p != TaskPriority.high ? 8 : 0),
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
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? p.color : AppColors.textSecondary,
                        ),
                      ),
                    ],
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
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('日期',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B6F5E))),
        const SizedBox(height: 8),
        GestureDetector(
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE8C9A0).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: Color(0xFFD4A574)),
                const SizedBox(width: 12),
                Text(isToday ? '今天 · $dateStr' : dateStr,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5C3D2E))),
                const Spacer(),
                if (!isToday)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedDate = DateTime.now()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1DF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('回到今天',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF88681A))),
                    ),
                  ),
              ],
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
        const Text('时间',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B6F5E))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(context,
                  label: '开始', time: _startTime, onTimeSelected: (t) {
                setState(() => _startTime = t);
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                  width: 20, height: 1, color: const Color(0xFFE8C9A0)),
            ),
            Expanded(
              child: _buildTimePicker(context,
                  label: '结束', time: _endTime, onTimeSelected: (t) {
                setState(() => _endTime = t);
              }),
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
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
            context: context, initialTime: time);
        if (picked != null) onTimeSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFE8C9A0).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: Color(0xFFD4A574)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFB0A09A))),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C3D2E)),
                ),
              ],
            ),
          ],
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
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('取消',
                style: TextStyle(color: Color(0xFF8B6F5E))),
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
                        strokeWidth: 2, color: Colors.white))
                : Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded,
                    size: 18),
            label: Text(_saving
                ? '保存中...'
                : (_isEditing ? '保存修改' : '添加任务')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFD4A574),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入任务名称')));
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
        description: Value(_descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim()),
        taskDate: Value(dateStr),
        startHour: Value(_startTime.hour),
        startMinute: Value(_startTime.minute),
        endHour: Value(_endTime.hour),
        endMinute: Value(_endTime.minute),
        priority: Value(_priority.value),
        createdAt: Value(_isEditing ? widget.editTask!.createdAt : now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

      if (_isEditing) {
        await repo.updateTask(DailyTasksCompanion(
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
        ));
      } else {
        await repo.insertTask(companion);
      }

      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayIncompleteTaskCountProvider);

      if (mounted) {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing
              ? '任务已更新'
              : '任务已添加到 ${_selectedDate.month}/${_selectedDate.day}'),
          backgroundColor: const Color(0xFF35C976),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// =============================================================================
// _InputField - 通用输入框组件
// =============================================================================

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B6F5E))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFC9CDD4)),
            prefixIcon:
                Icon(icon, size: 18, color: const Color(0xFFD4A574)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: const Color(0xFFE8C9A0).withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: const Color(0xFFE8C9A0).withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFD4A574), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          maxLines: maxLines,
          autofocus: autofocus,
        ),
      ],
    );
  }
}
