import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/task_provider.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../../core/constants/pet_assets.dart';
import 'add_task_dialog.dart';
import 'task_priority.dart';
import 'today_task_tile.dart';

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
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
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
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF0E7DB), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B75F6).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
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
    BuildContext context,
    AsyncValue<List<DailyTask>> tasksAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  size: 20,
                  color: Color(0xFF8B75F6),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '今日任务',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF37314E),
                ),
              ),
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: completed == total && total > 0
                              ? const Color(0xFF35C976).withValues(alpha: 0.12)
                              : const Color(0xFFF7F4FA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$completed/$total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: completed == total && total > 0
                                ? const Color(0xFF35C976)
                                : const Color(0xFF8D869A),
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
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B75F6),
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
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFEFEAF8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? const Color(0xFF35C976)
                        : const Color(0xFF8B75F6),
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
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      child: Center(
        child: Column(
          children: [
            Image.asset(
              PetAssets.commonEmpty,
              width: 86,
              height: 86,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.task_alt_rounded,
                size: 46,
                color: AppColors.textTertiary.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '暂无任务',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF37314E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '点击下方按钮添加今天的计划',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
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
    inProgress.sort(
      (a, b) => (a.startHour * 60 + a.startMinute).compareTo(
        b.startHour * 60 + b.startMinute,
      ),
    );
    upcoming.sort(
      (a, b) => (a.startHour * 60 + a.startMinute).compareTo(
        b.startHour * 60 + b.startMinute,
      ),
    );
    // Completed: most recently completed first (by start time desc)
    completed.sort(
      (a, b) => (b.startHour * 60 + b.startMinute).compareTo(
        a.startHour * 60 + a.startMinute,
      ),
    );

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
        if (completed.isNotEmpty) _buildCompletedSection(completed),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...tasks.map(
          (task) => TaskSlidable(
            task: task,
            onComplete: () => _toggleTask(ref, task),
            onDelete: () => _deleteTask(ref, task),
            onReschedule: () => _rescheduleTask(context, ref, task),
            onEdit: () => _editTask(context, ref, task),
            onSetPriority: (p) => _setPriority(ref, task, p),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
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
        Semantics(
          label: _showCompleted ? '收起已完成任务' : '展开已完成任务',
          button: true,
          child: GestureDetector(
          onTap: () {
            setState(() => _showCompleted = !_showCompleted);
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: Color(0xFF35C976),
                ),
                const SizedBox(width: 6),
                const Text(
                  '已完成',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF35C976),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF35C976).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF35C976),
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showCompleted ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
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
                      .map(
                        (task) => TaskSlidable(
                          task: task,
                          onComplete: () => _toggleTask(ref, task),
                          onDelete: () => _deleteTask(ref, task),
                          onReschedule: () =>
                              _rescheduleTask(context, ref, task),
                          onEdit: () => _editTask(context, ref, task),
                          onSetPriority: (p) => _setPriority(ref, task, p),
                        ),
                      )
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
    return Semantics(
      button: true,
      label: '添加任务',
      child: GestureDetector(
      onTap: () => _showAddTaskDialog(context, ref),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F2FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE8DFFF)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 19, color: Color(0xFF8B75F6)),
            SizedBox(width: 6),
            Text(
              '添加任务',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF8B75F6),
              ),
            ),
          ],
        ),
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
      PetEventBus.instance.emit(
        PetEvent.taskCompleted(
          eventId: 'task_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          module: 'task',
        ),
      );
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
    BuildContext context,
    WidgetRef ref,
    DailyTask task,
  ) async {
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
    await repo.updateTask(
      DailyTasksCompanion(
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
      ),
    );
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayIncompleteTaskCountProvider);
    HapticFeedback.lightImpact();
  }

  Future<void> _setPriority(
    WidgetRef ref,
    DailyTask task,
    TaskPriority priority,
  ) async {
    final repo = ref.read(dailyTaskRepositoryProvider);
    await repo.updateTaskPriority(task.id, priority.value);
    ref.invalidate(todayTasksProvider);
    HapticFeedback.lightImpact();
  }

  void _editTask(BuildContext context, WidgetRef ref, DailyTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AddTaskDialog(editTask: task),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => const AddTaskDialog());
  }
}
