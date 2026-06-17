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
  bool _saveAsTemplate = true;

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
    final colors = context.growthColors;
    return _SheetFrame(
      title: '训练编排',
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: '模板名称'),
          ),
          TextField(
            controller: _bodyPartController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: '训练部位'),
          ),
          const SizedBox(height: 12),
          ..._exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _EditableExerciseTile(
              exercise: exercise,
              onChanged: (next) => setState(() => _exercises[index] = next),
              onDelete: () => setState(() => _exercises.removeAt(index)),
              onMoveUp: index == 0
                  ? null
                  : () => setState(() {
                      final item = _exercises.removeAt(index);
                      _exercises.insert(index - 1, item);
                    }),
              onMoveDown: index == _exercises.length - 1
                  ? null
                  : () => setState(() {
                      final item = _exercises.removeAt(index);
                      _exercises.insert(index + 1, item);
                    }),
            );
          }),
          OutlinedButton.icon(
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
            }),
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加动作'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _saveAsTemplate,
            activeThumbColor: colors.fitness,
            onChanged: (value) => setState(() => _saveAsTemplate = value),
            title: Text(
              '保存为自定义模板',
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: _exercises.isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    _PlanEditResult(
                      templateName: _nameController.text.trim().isEmpty
                          ? '自定义训练'
                          : _nameController.text.trim(),
                      bodyPart: _bodyPartController.text.trim().isEmpty
                          ? '全身'
                          : _bodyPartController.text.trim(),
                      exercises: _exercises,
                      saveAsTemplate: _saveAsTemplate,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.fitness,
              foregroundColor: colors.textOnAccent,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('应用编排'),
          ),
        ],
      ),
    );
  }
}

class _EditableExerciseTile extends StatelessWidget {
  const _EditableExerciseTile({
    required this.exercise,
    required this.onChanged,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final WorkoutExercisePlan exercise;
  final ValueChanged<WorkoutExercisePlan> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: exercise.name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: '动作名称'),
                    onChanged: (value) =>
                        onChanged(exercise.copyWith(name: value)),
                  ),
                ),
                IconButton(
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<WorkoutExerciseType>(
                    initialValue: exercise.type,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: WorkoutExerciseType.reps,
                        child: Text('次数'),
                      ),
                      DropdownMenuItem(
                        value: WorkoutExerciseType.timed,
                        child: Text('计时'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      onChanged(exercise.withType(value));
                    },
                  ),
                ),
                _SmallNumberField(
                  label: '组',
                  value: exercise.targetSets,
                  onChanged: (value) =>
                      onChanged(exercise.copyWith(targetSets: value)),
                ),
                if (exercise.type == WorkoutExerciseType.reps)
                  _SmallNumberField(
                    label: '次',
                    value: exercise.targetReps ?? 0,
                    onChanged: (value) =>
                        onChanged(exercise.copyWith(targetReps: value)),
                  )
                else
                  _SmallNumberField(
                    label: '秒',
                    value: exercise.targetSeconds ?? 0,
                    onChanged: (value) =>
                        onChanged(exercise.copyWith(targetSeconds: value)),
                  ),
                _SmallNumberField(
                  label: '休息(s)',
                  value: exercise.restSeconds,
                  onChanged: (value) =>
                      onChanged(exercise.copyWith(restSeconds: value)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallNumberField extends StatelessWidget {
  const _SmallNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: TextFormField(
        initialValue: '$value',
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, isDense: true),
        keyboardType: TextInputType.number,
        onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
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
