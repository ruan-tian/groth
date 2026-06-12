import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/study_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';

/// 添加学习记录页面
///
/// 支持简单模式和专业模式切换，使用新设计系统。
class AddStudyRecordPage extends ConsumerStatefulWidget {
  const AddStudyRecordPage({super.key});

  @override
  ConsumerState<AddStudyRecordPage> createState() =>
      _AddStudyRecordPageState();
}

class _AddStudyRecordPageState extends ConsumerState<AddStudyRecordPage> {
  final _formKey = GlobalKey<FormState>();

  // ── 模式 (0 = 简单, 1 = 专业) ──
  int _modeIndex = 0;

  // ── 简单模式字段 ──
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _noteController = TextEditingController();

  // ── 专业模式额外字段 ──
  final _subjectController = TextEditingController();
  final _chapterController = TextEditingController();
  final _gainController = TextEditingController();
  final _problemController = TextEditingController();

  int _focusLevel = 3;
  int _difficultyLevel = 3;
  int _masteryLevel = 3;

  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endTime = DateTime.now();

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    _subjectController.dispose();
    _chapterController.dispose();
    _gainController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 时间选择
  // ---------------------------------------------------------------------------

  Future<void> _pickStartTime() async {
    final date = await showGrowthDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showGrowthTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _syncDuration();
    });
  }

  Future<void> _pickEndTime() async {
    final date = await showGrowthDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showGrowthTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (time == null) return;

    setState(() {
      _endTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _syncDuration();
    });
  }

  /// 根据开始/结束时间同步时长字段
  void _syncDuration() {
    final diff = _endTime.difference(_startTime).inMinutes;
    if (diff > 0) {
      _durationController.text = diff.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // 保存
  // ---------------------------------------------------------------------------

  bool get _isProfessional => _modeIndex == 1;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final duration = int.parse(_durationController.text);

      final companion = StudyRecordsCompanion.insert(
        mode: _isProfessional ? 'professional' : 'simple',
        title: _titleController.text.trim(),
        subject:
            Value(_isProfessional ? _subjectController.text.trim() : null),
        chapter:
            Value(_isProfessional ? _chapterController.text.trim() : null),
        startTime: _startTime.millisecondsSinceEpoch,
        endTime: _endTime.millisecondsSinceEpoch,
        durationMinutes: duration,
        focusLevel: Value(_isProfessional ? _focusLevel : null),
        difficultyLevel: Value(_isProfessional ? _difficultyLevel : null),
        masteryLevel: Value(_isProfessional ? _masteryLevel : null),
        note: Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        gain: Value(
          _isProfessional && _gainController.text.trim().isNotEmpty
              ? _gainController.text.trim()
              : null,
        ),
        problem: Value(
          _isProfessional && _problemController.text.trim().isNotEmpty
              ? _problemController.text.trim()
              : null,
        ),
        createdAt: now,
        updatedAt: now,
      );

      // 计算经验值（纯计算，事务外执行）
      final expService = ref.read(expServiceProvider);
      final exp = expService.calculateStudyExp(
        durationMinutes: duration,
        focusLevel: _isProfessional ? _focusLevel : 0,
        difficultyLevel: _isProfessional ? _difficultyLevel : 0,
      );

      // 原子操作：插入记录 + 更新EXP + 写入经验日志
      final db = ref.read(databaseProvider);
      final oldTotal = await ref.read(expRepositoryProvider).getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      late final int recordId;
      await db.transaction(() async {
        final studyRepo = ref.read(studyRepositoryProvider);
        recordId = await studyRepo.insertStudyRecord(companion);
        await studyRepo.updateStudyRecordExp(recordId, exp);
        await ref.read(expRepositoryProvider).insertExpLog(
          GrowthExpLogsCompanion.insert(
            sourceType: 'study',
            sourceId: recordId,
            expValue: exp,
            reason: '学习: ${_titleController.text.trim()} ($duration min)',
            createdAt: now,
          ),
        );
      });

      // 等级提升检测
      final newTotal = oldTotal + exp;
      final newLevel = expService.calculateLevel(newTotal);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(PetEvent.levelUp(
          oldLevel: oldLevel,
          newLevel: newLevel,
        ));
      }

      // 刷新相关 Provider
      ref.invalidate(dashboardProvider);
      ref.invalidate(todayStudyMinutesProvider);
      ref.invalidate(todayStudyRecordsProvider);
      ref.invalidate(weeklyStudyMinutesProvider);
      ref.invalidate(recentStudyRecordsProvider);

      if (mounted) {
        // 发送宠物事件
        final eventId = 'study_${DateTime.now().millisecondsSinceEpoch}';
        PetEventBus.instance.emit(PetEvent.moduleCompleted(
          eventId: eventId,
          type: PetEventType.studyCompleted,
          module: 'study',
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存，获得 $exp EXP')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('添加学习记录'),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 模式切换 ──
                      SegmentedTabs(
                        tabs: const ['简单模式', '专业模式'],
                        selectedIndex: _modeIndex,
                        onChanged: (i) => setState(() => _modeIndex = i),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── 学习内容（必填）──
                      _buildTextField(
                        controller: _titleController,
                        label: '学习内容',
                        hint: '例如：学习 Flutter',
                        icon: Icons.book_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '请输入学习内容'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 学习时长（必填）──
                      _buildTextField(
                        controller: _durationController,
                        label: '学习时长 (分钟)',
                        hint: '例如：60',
                        icon: Icons.timer_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '请输入学习时长';
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return '请输入有效时长';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── 专业模式额外字段 ──
                      if (_isProfessional) ...[
                        // 科目
                        _buildTextField(
                          controller: _subjectController,
                          label: '科目',
                          hint: '例如：数学',
                          icon: Icons.school_rounded,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 章节
                        _buildTextField(
                          controller: _chapterController,
                          label: '章节',
                          hint: '例如：第三章',
                          icon: Icons.menu_book_rounded,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 开始 / 结束时间
                        Row(
                          children: [
                            Expanded(
                              child: _DateTimeField(
                                label: '开始时间',
                                dateTime: _startTime,
                                onTap: _pickStartTime,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _DateTimeField(
                                label: '结束时间',
                                dateTime: _endTime,
                                onTap: _pickEndTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 专注度
                        Text('专注度', style: AppTextStyles.cardTitle),
                        const SizedBox(height: AppSpacing.sm),
                        RatingSelector(
                          value: _focusLevel,
                          onChanged: (v) => setState(() => _focusLevel = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 难度
                        Text('难度', style: AppTextStyles.cardTitle),
                        const SizedBox(height: AppSpacing.sm),
                        RatingSelector(
                          value: _difficultyLevel,
                          onChanged: (v) =>
                              setState(() => _difficultyLevel = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 掌握度
                        Text('掌握度', style: AppTextStyles.cardTitle),
                        const SizedBox(height: AppSpacing.sm),
                        RatingSelector(
                          value: _masteryLevel,
                          onChanged: (v) =>
                              setState(() => _masteryLevel = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 收获
                        _buildTextField(
                          controller: _gainController,
                          label: '学习收获',
                          hint: '今天学到了什么...',
                          icon: Icons.lightbulb_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 遗留问题
                        _buildTextField(
                          controller: _problemController,
                          label: '遗留问题',
                          hint: '还有什么不明白的...',
                          icon: Icons.help_outline_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // ── 备注 ──
                      _buildTextField(
                        controller: _noteController,
                        label: '备注',
                        hint: '其他想记录的...',
                        icon: Icons.note_rounded,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // ── 底部保存按钮 ──
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  text: '保存记录',
                  icon: Icons.check_rounded,
                  isLoading: _saving,
                  onTap: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 统一输入框样式
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _DateTimeField - 日期时间选择字段
// =============================================================================

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.dateTime,
    required this.onTap,
  });

  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dt =
        '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(dt, style: AppTextStyles.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
