import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../models/dashboard_data.dart';
import '../../plan/providers/task_provider.dart';
import '../../../shared/widgets/date_grouped_list.dart';

/// 任务历史页面
///
/// 显示过往全部任务，按日期分组，支持筛选和搜索
class TaskHistoryPage extends ConsumerStatefulWidget {
  const TaskHistoryPage({super.key});

  @override
  ConsumerState<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends ConsumerState<TaskHistoryPage> {
  String? _filterStatus; // null: 全部, 'completed': 已完成, 'pending': 未完成
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务历史'),
        centerTitle: true,
        actions: [
          // 筛选按钮
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: _filterStatus != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            onSelected: (value) {
              setState(() => _filterStatus = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(value: 'completed', child: Text('已完成')),
              const PopupMenuItem(value: 'pending', child: Text('未完成')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 搜索栏 ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索任务...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // ── 任务列表 ──
          Expanded(
            child: allTasksAsync.when(
              data: (tasks) {
                // 应用筛选
                var filtered = tasks;
                if (_filterStatus == 'completed') {
                  filtered = tasks.where((t) => t.isCompleted).toList();
                } else if (_filterStatus == 'pending') {
                  filtered = tasks.where((t) => !t.isCompleted).toList();
                }

                // 应用搜索
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((t) {
                    final titleMatch = t.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                    final descMatch =
                        t.description?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false;
                    return titleMatch || descMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '暂无任务',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 按日期分组
                return DateGroupedList<DailyTask>(
                  items: filtered,
                  dateExtractor: (task) => DateTime.parse(task.taskDate),
                  itemBuilder: (context, task) => _TaskHistoryTile(
                    task: task,
                    onToggle: () => _toggleTask(ref, task),
                    onDelete: () => _deleteTask(context, ref, task),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  /// 切换任务完成状态
  Future<void> _toggleTask(WidgetRef ref, DailyTask task) async {
    final repo = ref.read(dailyTaskRepositoryProvider);
    await repo.toggleTaskCompletion(task.id, !task.isCompleted);
    ref.invalidate(allTasksProvider);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayIncompleteTaskCountProvider);
  }

  /// 删除任务
  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    DailyTask task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除「${task.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.growthColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(dailyTaskRepositoryProvider);
      await repo.deleteTask(task.id);
      ref.invalidate(allTasksProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayIncompleteTaskCountProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
        );
      }
    }
  }
}

// =============================================================================
// _TaskHistoryTile - 任务历史项
// =============================================================================

class _TaskHistoryTile extends StatelessWidget {
  const _TaskHistoryTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final DailyTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey('task_history_${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: context.growthColors.danger,
        child: Icon(Icons.delete, color: context.growthColors.textOnAccent),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 2,
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? context.growthColors.success
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? context.growthColors.success
                      : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: context.growthColors.textOnAccent,
                    )
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? colorScheme.outline : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Text(
                  task.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '${_formatTime(task.startHour, task.startMinute)}'
                '-'
                '${_formatTime(task.endHour, task.endMinute)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          trailing: task.isCompleted
              ? Icon(
                  Icons.check_circle,
                  color: context.growthColors.success,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
