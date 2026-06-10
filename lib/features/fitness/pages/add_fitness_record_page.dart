import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/design/design.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/providers/dashboard_provider.dart';
import '../../../../shared/providers/fitness_provider.dart';
import '../../../../shared/widgets/common/common_widgets.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';

/// 添加健身记录页面
class AddFitnessRecordPage extends ConsumerStatefulWidget {
  const AddFitnessRecordPage({
    super.key,
    this.initialMode = 'simple',
    this.initialDurationMinutes,
  });

  final String initialMode;
  final int? initialDurationMinutes;

  @override
  ConsumerState<AddFitnessRecordPage> createState() =>
      _AddFitnessRecordPageState();
}

class _AddFitnessRecordPageState extends ConsumerState<AddFitnessRecordPage> {
  late int _modeIndex;

  // 简单模式字段
  final _bodyPartController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // 专业模式字段
  final _titleController = TextEditingController();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  int _intensity = 3;
  int _fatigue = 3;
  final _feelingController = TextEditingController();
  final List<_ExerciseItem> _exercises = [];

  bool _saving = false;

  // 预设部位
  final _presetBodyParts = ['胸', '背', '腿', '肩', '手臂', '核心', '全身'];

  @override
  void initState() {
    super.initState();
    _modeIndex = widget.initialMode == 'professional' ? 1 : 0;
    final duration = widget.initialDurationMinutes;
    if (duration != null && duration > 0) {
      _durationController.text = '$duration';
      _endTime = _startTime.add(Duration(minutes: duration));
    }
  }

  @override
  void dispose() {
    _bodyPartController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    _feelingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('添加训练记录', style: AppTextStyles.pageTitle),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 模式切换 ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SegmentedTabs(
                tabs: const ['简单模式', '专业模式'],
                selectedIndex: _modeIndex,
                onChanged: (index) => setState(() => _modeIndex = index),
              ),
            ),

            // ── 表单内容 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _modeIndex == 0
                    ? _buildSimpleForm()
                    : _buildProfessionalForm(),
              ),
            ),

            // ── 保存按钮 ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryButton(
                text: _saving ? '保存中...' : '保存记录',
                icon: _saving ? null : Icons.check,
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 简单模式表单 ──
  Widget _buildSimpleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 训练部位
        _buildSectionTitle('训练部位'),
        const SizedBox(height: AppSpacing.sm),
        _buildBodyPartSelector(),
        const SizedBox(height: AppSpacing.lg),

        // 训练时长
        _buildSectionTitle('训练时长 (分钟)'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _durationController,
          hint: '例如：60',
          icon: Icons.timer,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 备注
        _buildSectionTitle('备注'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _notesController,
          hint: '记录训练感受...',
          icon: Icons.note,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ── 专业模式表单 ──
  Widget _buildProfessionalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 训练标题
        _buildSectionTitle('训练标题'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _titleController,
          hint: '例如：胸 + 三头强化训练',
          icon: Icons.title,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 训练部位（带身体模型占位）
        _buildSectionTitle('训练部位'),
        const SizedBox(height: AppSpacing.sm),
        _buildBodyPartWithModel(),
        const SizedBox(height: AppSpacing.lg),

        // 时间选择
        _buildSectionTitle('训练时间'),
        const SizedBox(height: AppSpacing.sm),
        _buildTimeSelector(),
        const SizedBox(height: AppSpacing.lg),

        // 强度和疲劳
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('训练强度'),
                  const SizedBox(height: AppSpacing.sm),
                  RatingSelector(
                    value: _intensity,
                    onChanged: (v) => setState(() => _intensity = v),
                    activeColor: AppColors.fitness,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('疲劳程度'),
                  const SizedBox(height: AppSpacing.sm),
                  RatingSelector(
                    value: _fatigue,
                    onChanged: (v) => setState(() => _fatigue = v),
                    activeColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 训练动作
        _buildSectionTitle('训练动作'),
        const SizedBox(height: AppSpacing.sm),
        _buildExerciseList(),
        const SizedBox(height: AppSpacing.md),
        _buildAddExerciseButton(),
        const SizedBox(height: AppSpacing.lg),

        // 训练感受
        _buildSectionTitle('训练感受'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _feelingController,
          hint: '今天训练感觉如何...',
          icon: Icons.sentiment_satisfied,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ── 构建区域标题 ──
  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.cardTitle);
  }

  // ── 构建输入框 ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // ── 部位选择器 ──
  Widget _buildBodyPartSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _presetBodyParts.map((part) {
        final isSelected = _bodyPartController.text == part;
        return GestureDetector(
          onTap: () => setState(() => _bodyPartController.text = part),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.fitness : AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.fitness : AppColors.border,
              ),
            ),
            child: Text(
              part,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 部位选择 + 身体模型占位 ──
  Widget _buildBodyPartWithModel() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：部位选择
        Expanded(flex: 3, child: _buildBodyPartSelector()),
        const SizedBox(width: AppSpacing.md),
        // 右侧：身体模型占位
        Expanded(
          flex: 2,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.accessibility_new,
                    size: 48,
                    color: AppColors.fitness,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _bodyPartController.text.isEmpty
                        ? '选择部位'
                        : _bodyPartController.text,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.fitness,
                      fontWeight: FontWeight.w600,
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

  // ── 时间选择器 ──
  Widget _buildTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeField(
            label: '开始时间',
            time: _startTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startTime),
              );
              if (picked != null) {
                setState(() {
                  _startTime = DateTime(
                    _startTime.year,
                    _startTime.month,
                    _startTime.day,
                    picked.hour,
                    picked.minute,
                  );
                });
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(Icons.arrow_forward, color: AppColors.textTertiary),
        ),
        Expanded(
          child: _buildTimeField(
            label: '结束时间',
            time: _endTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_endTime),
              );
              if (picked != null) {
                setState(() {
                  _endTime = DateTime(
                    _endTime.year,
                    _endTime.month,
                    _endTime.day,
                    picked.hour,
                    picked.minute,
                  );
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.cardTitle,
            ),
          ],
        ),
      ),
    );
  }

  // ── 动作列表 ──
  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: Text('暂无动作', style: AppTextStyles.caption)),
      );
    }

    return Column(
      children: _exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;
        return _buildExerciseTile(index, exercise);
      }).toList(),
    );
  }

  Widget _buildExerciseTile(int index, _ExerciseItem exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.fitness,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: AppTextStyles.cardTitle),
                Text(
                  '${exercise.sets}组 × ${exercise.reps}次'
                  '${exercise.weight != null ? ' · ${exercise.weight}kg' : ''}'
                  '${exercise.restSeconds != null ? ' · 休息${exercise.restSeconds}秒' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
            onPressed: () => setState(() => _exercises.removeAt(index)),
          ),
        ],
      ),
    );
  }

  // ── 添加动作按钮 ──
  Widget _buildAddExerciseButton() {
    return OutlinedButton.icon(
      onPressed: _showAddExerciseSheet,
      icon: const Icon(Icons.add),
      label: const Text('添加动作'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.fitness,
        side: BorderSide(color: AppColors.fitness),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  // ── 添加动作弹窗 ──
  void _showAddExerciseSheet() {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');
    final weightController = TextEditingController();
    final restController = TextEditingController(text: '90');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetContainer(
        title: '添加动作',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetField(
              '动作名称',
              nameController,
              '例如：卧推',
              Icons.fitness_center,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSheetField(
                    '组数',
                    setsController,
                    '3',
                    Icons.repeat,
                    TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSheetField(
                    '次数',
                    repsController,
                    '12',
                    Icons.tag,
                    TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSheetField(
                    '重量 (kg)',
                    weightController,
                    '60',
                    Icons.monitor_weight,
                    TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSheetField(
                    '休息 (秒)',
                    restController,
                    '90',
                    Icons.timer,
                    TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: '添加动作',
              icon: Icons.add,
              onTap: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _exercises.add(
                      _ExerciseItem(
                        name: nameController.text.trim(),
                        sets: int.tryParse(setsController.text) ?? 3,
                        reps: int.tryParse(repsController.text) ?? 12,
                        weight: double.tryParse(weightController.text),
                        restSeconds: int.tryParse(restController.text),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, [
    TextInputType? keyboardType,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 18),
            isDense: true,
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  // ── 保存记录 ──
  Future<void> _save() async {
    if (_modeIndex == 0) {
      // 简单模式验证
      if (_bodyPartController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择训练部位')));
        return;
      }
      if (_durationController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入训练时长')));
        return;
      }
    }

    final duration = int.tryParse(_durationController.text) ?? 0;
    if (duration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的训练时长')));
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(fitnessRepositoryProvider);
      final now = DateTime.now();

      // 插入健身记录
      final recordId = await repo.insertFitnessRecord(
        FitnessRecordsCompanion(
          mode: Value(_modeIndex == 0 ? 'simple' : 'professional'),
          title: Value(
            _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
          ),
          bodyPart: Value(_bodyPartController.text.trim()),
          startTime: Value(_startTime.millisecondsSinceEpoch),
          endTime: Value(_endTime.millisecondsSinceEpoch),
          durationMinutes: Value(duration),
          fatigueLevel: Value(_modeIndex == 1 ? _fatigue : null),
          intensityLevel: Value(_modeIndex == 1 ? _intensity : null),
          feeling: Value(
            _modeIndex == 1 ? _feelingController.text.trim() : null,
          ),
          note: Value(
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
          createdAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

      // 插入动作列表（专业模式）
      if (_modeIndex == 1) {
        for (final exercise in _exercises) {
          await repo.insertFitnessExercise(
            FitnessExercisesCompanion(
              fitnessRecordId: Value(recordId),
              exerciseName: Value(exercise.name),
              sets: Value(exercise.sets),
              reps: Value(exercise.reps),
              weight: Value(exercise.weight),
              restSeconds: Value(exercise.restSeconds),
              createdAt: Value(now.millisecondsSinceEpoch),
            ),
          );
        }
      }

      // 计算经验值
      final expService = ref.read(expServiceProvider);
      final exp = expService.calculateFitnessExp(
        durationMinutes: duration,
        intensityLevel: _modeIndex == 1 ? _intensity : 0,
        exerciseCount: _exercises.length,
        hasFeeling:
            _modeIndex == 1 && _feelingController.text.trim().isNotEmpty,
      );

      // 更新经验值
      await repo.updateFitnessRecordExp(recordId, exp);

      // 插入经验日志
      final expRepo = ref.read(expRepositoryProvider);
      final oldTotal = await expRepo.getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      await expRepo.insertExpLog(
        GrowthExpLogsCompanion.insert(
          sourceType: 'fitness',
          sourceId: recordId,
          expValue: exp,
          reason: '健身: ${_bodyPartController.text.trim()} ($duration分钟)',
          createdAt: now.millisecondsSinceEpoch,
        ),
      );

      final newTotal = oldTotal + exp;
      final newLevel = expService.calculateLevel(newTotal);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(
          PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
        );
      }

      // 刷新数据
      ref.invalidate(recentFitnessRecordsProvider);
      ref.invalidate(todayFitnessMinutesProvider);
      ref.invalidate(weeklyFitnessCountProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(fitnessChartDataProvider(7));
      ref.invalidate(fitnessChartDataProvider(30));
      ref.invalidate(fitnessChartDataProvider(365));

      if (mounted) {
        // 发送宠物事件
        final eventId = 'fitness_${DateTime.now().millisecondsSinceEpoch}';
        PetEventBus.instance.emit(
          PetEvent.moduleCompleted(
            eventId: eventId,
            type: PetEventType.fitnessCompleted,
            module: 'fitness',
          ),
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已保存，获得 $exp EXP')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── 动作数据模型 ──
class _ExerciseItem {
  _ExerciseItem({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.restSeconds,
  });

  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final int? restSeconds;
}
