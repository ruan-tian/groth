part of '../pages/fitness_training_timer_page.dart';

class _TemplatePickerSheet extends StatelessWidget {
  const _TemplatePickerSheet({
    required this.templates,
    required this.selectedTemplateId,
    required this.onSelect,
  });

  final List<FitnessWorkoutTemplate> templates;
  final int? selectedTemplateId;
  final ValueChanged<FitnessWorkoutTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SheetFrame(
      title: '选择训练模板',
      child: Column(
        children: templates.map((template) {
          final selected = template.id == selectedTemplateId;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              template.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              template.description ?? template.bodyPart,
              style: TextStyle(color: colors.textSecondary),
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: colors.fitness)
                : null,
            onTap: () => onSelect(template),
          );
        }).toList(),
      ),
    );
  }
}

class _PlanEditorSheet extends StatefulWidget {
  const _PlanEditorSheet({required this.session});

  final WorkoutSessionState session;

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bodyPartController;
  late List<WorkoutExercisePlan> _exercises;
  int? _expandedIndex;

  // ── 颜色常量 ──
  static const _orange = Color(0xFFF97316);
  static const _bg = Color(0xFFFAFBFF);
  static const _card = Color(0xFFFFFFFF);
  static const _border = Color(0xFFEEF1F8);
  static const _deleteRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.templateName);
    _bodyPartController = TextEditingController(text: widget.session.bodyPart);
    _exercises = List.of(widget.session.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyPartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.85),
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 拖拽条 ──
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── 固定顶部标题 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '训练编排',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '编辑你的训练模板',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── 可滚动内容区 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基础信息卡片
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  // 动作列表标题
                  Row(
                    children: [
                      const Text(
                        '训练动作',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_exercises.length} 个动作',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 动作列表
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _exercises.removeAt(oldIndex);
                        _exercises.insert(newIndex, item);
                        if (_expandedIndex == oldIndex) {
                          _expandedIndex = newIndex;
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      return _ExerciseCard(
                        key: ValueKey('ex_$index'),
                        index: index,
                        exercise: _exercises[index],
                        isExpanded: _expandedIndex == index,
                        onTap: () => setState(() {
                          _expandedIndex = _expandedIndex == index ? null : index;
                        }),
                        onChanged: (next) =>
                            setState(() => _exercises[index] = next),
                        onCopy: () => setState(() {
                          _exercises.insert(index + 1, _exercises[index]);
                        }),
                        onDelete: () => setState(() {
                          _exercises.removeAt(index);
                          if (_expandedIndex == index) _expandedIndex = null;
                        }),
                        onMoveUp: index == 0
                            ? null
                            : () => setState(() {
                                final item = _exercises.removeAt(index);
                                _exercises.insert(index - 1, item);
                                if (_expandedIndex == index) {
                                  _expandedIndex = index - 1;
                                }
                              }),
                        onMoveDown: index == _exercises.length - 1
                            ? null
                            : () => setState(() {
                                final item = _exercises.removeAt(index);
                                _exercises.insert(index + 1, item);
                                if (_expandedIndex == index) {
                                  _expandedIndex = index + 1;
                                }
                              }),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // 添加动作按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _exercises.add(
                          const WorkoutExercisePlan(
                            name: '新动作',
                            type: WorkoutExerciseType.reps,
                            targetSets: 3,
                            targetReps: 12,
                            restSeconds: 60,
                          ),
                        );
                        _expandedIndex = _exercises.length - 1;
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _orange,
                        side: const BorderSide(color: _orange, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        '添加动作',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 教练提示
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          FitnessTimerAssets.catFitnessDumbbellMain,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            '🐱',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '甜甜教练提示：建议每个动作之间设置 30-90 秒休息。',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // ── 固定底部按钮 ──
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + mq.viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: _card,
              border: Border(top: BorderSide(color: _border, width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _exercises.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            _PlanEditResult(
                              templateName:
                                  _nameController.text.trim().isEmpty
                                      ? '自定义训练'
                                      : _nameController.text.trim(),
                              bodyPart: _bodyPartController.text.trim().isEmpty
                                  ? '全身'
                                  : _bodyPartController.text.trim(),
                              exercises: _exercises,
                              saveAsTemplate: true,
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '保存模板',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基础信息',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoField(
                  label: '模板名称',
                  controller: _nameController,
                  hint: '全身基础',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoField(
                  label: '训练部位',
                  controller: _bodyPartController,
                  hint: '全身',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 基础信息输入框 ──

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEF1F8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEF1F8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFF97316),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 动作卡片（紧凑 + 可展开编辑） ──

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.isExpanded,
    required this.onTap,
    required this.onChanged,
    required this.onCopy,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final WorkoutExercisePlan exercise;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<WorkoutExercisePlan> onChanged;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _PlanEditorSheetState._card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? _PlanEditorSheetState._orange.withValues(alpha: 0.4)
                : _PlanEditorSheetState._border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: _PlanEditorSheetState._orange.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // ── 紧凑头部 ──
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // 拖拽柄
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 序号
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 名称 + 摘要
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _summaryText(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 更多菜单
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'copy':
                            onCopy();
                            break;
                          case 'up':
                            onMoveUp?.call();
                            break;
                          case 'down':
                            onMoveDown?.call();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('复制'),
                            ],
                          ),
                        ),
                        if (onMoveUp != null)
                          const PopupMenuItem(
                            value: 'up',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('上移'),
                              ],
                            ),
                          ),
                        if (onMoveDown != null)
                          const PopupMenuItem(
                            value: 'down',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('下移'),
                              ],
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: _PlanEditorSheetState._deleteRed,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '删除',
                                style: TextStyle(
                                  color:
                                      _PlanEditorSheetState._deleteRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── 展开编辑区 ──
            if (isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEF1F8), width: 0.8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    // 动作名称
                    _EditField(
                      label: '动作名称',
                      value: exercise.name,
                      onChanged: (v) => onChanged(exercise.copyWith(name: v)),
                    ),
                    const SizedBox(height: 14),
                    // 类型分段按钮
                    const Text(
                      '类型',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TypeChip(
                          label: '次数',
                          isSelected:
                              exercise.type == WorkoutExerciseType.reps,
                          onTap: () => onChanged(
                            exercise.copyWith(
                              type: WorkoutExerciseType.reps,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: '计时',
                          isSelected:
                              exercise.type == WorkoutExerciseType.timed,
                          onTap: () => onChanged(
                            exercise.copyWith(
                              type: WorkoutExerciseType.timed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 数值步进器
                    Row(
                      children: [
                        _Stepper(
                          label: '组数',
                          value: exercise.targetSets,
                          onChanged: (v) =>
                              onChanged(exercise.copyWith(targetSets: v)),
                        ),
                        const SizedBox(width: 12),
                        if (exercise.type == WorkoutExerciseType.reps)
                          _Stepper(
                            label: '次数',
                            value: exercise.targetReps ?? 0,
                            onChanged: (v) => onChanged(
                              exercise.copyWith(targetReps: v),
                            ),
                          )
                        else
                          _Stepper(
                            label: '秒数',
                            value: exercise.targetSeconds ?? 0,
                            onChanged: (v) => onChanged(
                              exercise.copyWith(targetSeconds: v),
                            ),
                          ),
                        const SizedBox(width: 12),
                        _Stepper(
                          label: '休息(s)',
                          value: exercise.restSeconds,
                          onChanged: (v) =>
                              onChanged(exercise.copyWith(restSeconds: v)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _summaryText() {
    final typeLabel =
        exercise.type == WorkoutExerciseType.timed ? '计时' : '次数';
    final value = exercise.type == WorkoutExerciseType.timed
        ? '${exercise.targetSeconds ?? 0}秒'
        : '${exercise.targetReps ?? 0}次';
    return '$typeLabel · ${exercise.targetSets}组 × $value · 休息${exercise.restSeconds}s';
  }
}

// ── 编辑输入框 ──

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEEF1F8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEEF1F8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFF97316),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 类型分段按钮 ──

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _PlanEditorSheetState._orange
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _PlanEditorSheetState._orange
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── 步进器 ──

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF1F8)),
            ),
            child: Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: value > 0 ? () => onChanged(value - 1) : null,
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => onChanged(value + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? _PlanEditorSheetState._orange
              : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}

class _SaveSummarySheet extends StatefulWidget {
  const _SaveSummarySheet({required this.session, required this.onSave});

  final WorkoutSessionState session;
  final Future<void> Function(int intensity, int fatigue, String feeling)
  onSave;

  @override
  State<_SaveSummarySheet> createState() => _SaveSummarySheetState();
}

class _SaveSummarySheetState extends State<_SaveSummarySheet> {
  final _feelingController = TextEditingController();
  int _intensity = 3;
  int _fatigue = 3;
  bool _saving = false;

  @override
  void dispose() {
    _feelingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SheetFrame(
      title: '保存训练记录',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.session.completedSets} 组 · ${_formatDuration(Duration(seconds: widget.session.totalElapsedSeconds))} · ${widget.session.estimatedCalories} kcal',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _RatingRow(
            label: '训练强度',
            value: _intensity,
            onChanged: (value) => setState(() => _intensity = value),
          ),
          _RatingRow(
            label: '疲劳程度',
            value: _fatigue,
            onChanged: (value) => setState(() => _fatigue = value),
          ),
          TextField(
            controller: _feelingController,
            textInputAction: TextInputAction.newline,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '训练感受'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onSave(
                      _intensity,
                      _fatigue,
                      _feelingController.text,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.fitness,
              foregroundColor: colors.textOnAccent,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(_saving ? '保存中...' : '确认保存'),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(label, style: TextStyle(color: colors.textPrimary)),
          ),
          ...List.generate(5, (index) {
            final selected = index < value;
            return IconButton(
              onPressed: () => onChanged(index + 1),
              icon: Icon(
                selected ? Icons.star_rounded : Icons.star_border_rounded,
                color: selected ? colors.fitness : colors.textHint,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.pageTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PlanEditResult {
  const _PlanEditResult({
    required this.templateName,
    required this.bodyPart,
    required this.exercises,
    required this.saveAsTemplate,
  });

  final String templateName;
  final String bodyPart;
  final List<WorkoutExercisePlan> exercises;
  final bool saveAsTemplate;
}

BoxDecoration _cardDecoration(BuildContext context) {
  final colors = context.growthColors;
  return BoxDecoration(
    color: colors.paper.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: colors.fitness.withValues(alpha: 0.14)),
    boxShadow: [
      BoxShadow(
        color: colors.shadow.withValues(alpha: 0.24),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 999999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
