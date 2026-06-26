import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../study/providers/study_provider.dart';
import '../models/study_data.dart';

const _studyAssetRoot = 'assets/images/study_record';
const _catWritingAsset = '$_studyAssetRoot/study_cat_writing.webp';
const _catLayAsset = '$_studyAssetRoot/study_cat_lay.webp';
const _heartAsset = '$_studyAssetRoot/deco_heart.webp';
const _pawAsset = '$_studyAssetRoot/deco_paw.webp';
const _pawGrayAsset = '$_studyAssetRoot/deco_paw_gray.webp';

const _sea = Color(0xFF18A7B5);
const _seaDeep = Color(0xFF087383);
const _seaDark = Color(0xFF0B5262);
const _seaMist = Color(0xFFF1FBFA);
const _seaSoft = Color(0xFFE1F5F5);
const _seaLine = Color(0xFFCFE9E9);

/// 添加学习记录页面
///
/// 支持简单模式和专业模式切换，使用新设计系统。
class AddStudyRecordPage extends ConsumerStatefulWidget {
  const AddStudyRecordPage({super.key});

  @override
  ConsumerState<AddStudyRecordPage> createState() => _AddStudyRecordPageState();
}

class _AddStudyRecordPageState extends ConsumerState<AddStudyRecordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _entranceController;

  // ── 模式 (0 = 简单, 1 = 专业) ──
  int _modeIndex = 0;

  // ── 简单模式字段 ──
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _noteController = TextEditingController();

  // ── 专业模式额外字段 ──
  final _subjectController = TextEditingController();
  final _chapterController = TextEditingController();
  final _gainController = TextEditingController();
  final _problemController = TextEditingController();

  int _focusLevel = 4;
  int _difficultyLevel = 3;
  int _masteryLevel = 3;

  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endTime = DateTime.now();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
      final subject = _subjectController.text.trim();

      final companion = StudyRecordsCompanion.insert(
        mode: _isProfessional ? 'professional' : 'simple',
        title: _titleController.text.trim(),
        subject: Value(subject.isEmpty ? null : subject),
        chapter: Value(
          _isProfessional && _chapterController.text.trim().isNotEmpty
              ? _chapterController.text.trim()
              : null,
        ),
        startTime: _startTime.millisecondsSinceEpoch,
        endTime: _endTime.millisecondsSinceEpoch,
        durationMinutes: duration,
        focusLevel: Value(_focusLevel),
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
        focusLevel: _focusLevel,
        difficultyLevel: _isProfessional ? _difficultyLevel : 0,
      );

      // 原子操作：插入记录 + 更新EXP + 写入经验日志
      final oldTotal = await ref.read(expRepositoryProvider).getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      await ref
          .read(studyRepositoryProvider)
          .saveStudyRecordWithExp(
            record: companion,
            exp: exp,
            reason:
                '\u5b66\u4e60: ${_titleController.text.trim()} ($duration min)',
            createdAt: now,
          );

      final newTotal = oldTotal + exp;
      final newLevel = expService.calculateLevel(newTotal);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(
          PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
        );
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
        PetEventBus.instance.emit(
          PetEvent.moduleCompleted(
            eventId: eventId,
            type: PetEventType.studyCompleted,
            module: 'study',
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
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
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
      backgroundColor: _seaMist,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, _seaMist, _seaSoft.withValues(alpha: 0.62)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth > 700
                          ? 620.0
                          : double.infinity;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _EntranceItem(
                                  animation: _entranceController,
                                  begin: 0,
                                  child: _StudyHeader(
                                    onBack: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        Navigator.of(context).maybePop();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _EntranceItem(
                                  animation: _entranceController,
                                  begin: 0.08,
                                  child: _StudyModeSwitch(
                                    selectedIndex: _modeIndex,
                                    onChanged: (index) {
                                      setState(() => _modeIndex = index);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  reverseDuration: const Duration(
                                    milliseconds: 180,
                                  ),
                                  switchInCurve: Curves.easeOutQuart,
                                  switchOutCurve: Curves.easeInQuad,
                                  transitionBuilder: (child, animation) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutQuart,
                                    );
                                    final offset = Tween<Offset>(
                                      begin: const Offset(0, 0.025),
                                      end: Offset.zero,
                                    ).animate(curved);
                                    final scale = Tween<double>(
                                      begin: 0.992,
                                      end: 1,
                                    ).animate(curved);
                                    return FadeTransition(
                                      opacity: curved,
                                      child: ScaleTransition(
                                        scale: scale,
                                        child: SlideTransition(
                                          position: offset,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _isProfessional
                                      ? _ProfessionalStudyForm(
                                          key: const ValueKey('professional'),
                                          titleController: _titleController,
                                          durationController:
                                              _durationController,
                                          subjectController: _subjectController,
                                          chapterController: _chapterController,
                                          gainController: _gainController,
                                          problemController: _problemController,
                                          noteController: _noteController,
                                          focusLevel: _focusLevel,
                                          difficultyLevel: _difficultyLevel,
                                          masteryLevel: _masteryLevel,
                                          startTime: _startTime,
                                          endTime: _endTime,
                                          onStartTap: _pickStartTime,
                                          onEndTap: _pickEndTime,
                                          onFocusChanged: (value) => setState(
                                            () => _focusLevel = value,
                                          ),
                                          onDifficultyChanged: (value) =>
                                              setState(
                                                () => _difficultyLevel = value,
                                              ),
                                          onMasteryChanged: (value) => setState(
                                            () => _masteryLevel = value,
                                          ),
                                        )
                                      : _SimpleStudyForm(
                                          key: const ValueKey('simple'),
                                          titleController: _titleController,
                                          durationController:
                                              _durationController,
                                          subjectController: _subjectController,
                                          noteController: _noteController,
                                          focusLevel: _focusLevel,
                                          onFocusChanged: (value) => setState(
                                            () => _focusLevel = value,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 18),
                                _SaveFooter(
                                  isSaving: _saving,
                                  onSave: _saving ? null : _save,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 174,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 126,
              height: 86,
              decoration: BoxDecoration(
                color: _seaSoft.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(AppRadius.xxxl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 0,
            child: Image.asset(
              _catWritingAsset,
              width: 144,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            top: 6,
            child: _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ),
          Positioned(
            left: 2,
            right: 132,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加学习记录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 28,
                    color: _seaDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '记录每一次学习，让成长看得见',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _seaDeep.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyModeSwitch extends StatelessWidget {
  const _StudyModeSwitch({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    const labels = ['简单模式', '专业模式'];

    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _seaSoft.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: _seaLine.withValues(alpha: 0.72)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / labels.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutQuart,
                    left: selectedIndex * itemWidth,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(AppRadius.mlg),
                        border: Border.all(
                          color: _seaLine.withValues(alpha: 0.62),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _seaDeep.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(labels.length, (index) {
                      final selected = index == selectedIndex;
                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.mlg),
                          onTap: () => onChanged(index),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: selected
                                    ? _seaDeep
                                    : colors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                              child: Text(labels[index]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Text(
            selectedIndex == 0 ? '快速记录核心内容，30秒完成记录' : '完整记录学习详情，深度复盘分析',
            key: ValueKey(selectedIndex),
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _SimpleStudyForm extends StatelessWidget {
  const _SimpleStudyForm({
    super.key,
    required this.titleController,
    required this.durationController,
    required this.subjectController,
    required this.noteController,
    required this.focusLevel,
    required this.onFocusChanged,
  });

  final TextEditingController titleController;
  final TextEditingController durationController;
  final TextEditingController subjectController;
  final TextEditingController noteController;
  final int focusLevel;
  final ValueChanged<int> onFocusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnimatedFormCard(
          delay: 0,
          child: _StudyTextField(
            controller: titleController,
            title: '学习内容',
            hint: '例如：学习 Flutter 状态管理',
            icon: Icons.bookmark_rounded,
            maxLength: 50,
            validator: _validateTitle,
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 70,
          child: Row(
            children: [
              Expanded(
                child: _StudyTextField(
                  controller: durationController,
                  title: '学习时长',
                  hint: '60',
                  icon: Icons.timer_rounded,
                  suffixText: '分钟',
                  keyboardType: TextInputType.number,
                  validator: _validateDuration,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 120,
          child: _StudyTextField(
            controller: subjectController,
            title: '科目',
            hint: '计算机 / 开发',
            icon: Icons.school_rounded,
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 170,
          child: _RatingBlock(
            title: '专注度',
            icon: Icons.spa_rounded,
            value: focusLevel,
            onChanged: onFocusChanged,
            labels: const ['分心', '一般', '非常专注'],
            activeAsset: null,
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 220,
          child: _StudyTextField(
            controller: noteController,
            title: '学习收获（可选）',
            hint: '今天学到了什么呢？\n记录你的收获吧～',
            icon: Icons.lightbulb_rounded,
            maxLines: 4,
            maxLength: 200,
          ),
        ),
      ],
    );
  }
}

class _ProfessionalStudyForm extends StatelessWidget {
  const _ProfessionalStudyForm({
    super.key,
    required this.titleController,
    required this.durationController,
    required this.subjectController,
    required this.chapterController,
    required this.gainController,
    required this.problemController,
    required this.noteController,
    required this.focusLevel,
    required this.difficultyLevel,
    required this.masteryLevel,
    required this.startTime,
    required this.endTime,
    required this.onStartTap,
    required this.onEndTap,
    required this.onFocusChanged,
    required this.onDifficultyChanged,
    required this.onMasteryChanged,
  });

  final TextEditingController titleController;
  final TextEditingController durationController;
  final TextEditingController subjectController;
  final TextEditingController chapterController;
  final TextEditingController gainController;
  final TextEditingController problemController;
  final TextEditingController noteController;
  final int focusLevel;
  final int difficultyLevel;
  final int masteryLevel;
  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final ValueChanged<int> onFocusChanged;
  final ValueChanged<int> onDifficultyChanged;
  final ValueChanged<int> onMasteryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnimatedFormCard(
          delay: 0,
          child: _SectionBlock(
            title: '学习内容',
            icon: Icons.assignment_rounded,
            tint: _seaSoft,
            children: [
              _StudyTextField(
                controller: titleController,
                title: '学习内容',
                hint: '例如：学习 Flutter 状态管理',
                maxLength: 50,
                validator: _validateTitle,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StudyTextField(
                      controller: durationController,
                      title: '学习时长',
                      hint: '60',
                      suffixText: '分钟',
                      keyboardType: TextInputType.number,
                      validator: _validateDuration,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StudyTextField(
                      controller: subjectController,
                      title: '科目',
                      hint: '计算机 / 开发',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StudyTextField(
                controller: chapterController,
                title: '章节（可选）',
                hint: '例如：第三章 状态管理原理',
                maxLength: 50,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 80,
          child: _SectionBlock(
            title: '时间信息',
            icon: Icons.event_available_rounded,
            tint: const Color(0xFFE9F8F1),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateTimeField(
                      label: '开始时间',
                      dateTime: startTime,
                      onTap: onStartTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateTimeField(
                      label: '结束时间',
                      dateTime: endTime,
                      onTap: onEndTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 140,
          child: _SectionBlock(
            title: '学习状态',
            icon: Icons.insights_rounded,
            tint: const Color(0xFFFFF4DE),
            children: [
              _PawRatingRow(
                title: '专注度',
                value: focusLevel,
                onChanged: onFocusChanged,
                endLabel: '非常专注',
              ),
              const SizedBox(height: 14),
              _PawRatingRow(
                title: '难度',
                value: difficultyLevel,
                onChanged: onDifficultyChanged,
                endLabel: '非常难',
              ),
              const SizedBox(height: 14),
              _PawRatingRow(
                title: '掌握度',
                value: masteryLevel,
                onChanged: onMasteryChanged,
                endLabel: '非常熟练',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AnimatedFormCard(
          delay: 200,
          child: _SectionBlock(
            title: '复盘总结',
            icon: Icons.edit_note_rounded,
            tint: const Color(0xFFEAF1FF),
            children: [
              _StudyTextField(
                controller: gainController,
                title: '学习收获',
                hint: '今天学到了什么？',
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              _StudyTextField(
                controller: problemController,
                title: '遗留问题',
                hint: '还有什么不明白的地方？',
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              _StudyTextField(
                controller: noteController,
                title: '备注（可选）',
                hint: '其他想记录的内容...',
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.icon,
    required this.tint,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconBubble(icon: icon, color: tint),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 15,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _StudyTextField extends StatelessWidget {
  const _StudyTextField({
    required this.controller,
    required this.title,
    required this.hint,
    this.icon,
    this.suffixText,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  final TextEditingController controller;
  final String title;
  final String hint;
  final IconData? icon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              _IconBubble(icon: icon!, color: _seaSoft),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType:
              keyboardType ??
              (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: AppTextStyles.body.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            counterStyle: AppTextStyles.label.copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: _seaMist.withValues(alpha: 0.72),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: _seaLine.withValues(alpha: 0.78)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: const BorderSide(color: _sea, width: 1.25),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: colors.danger, width: 1.25),
            ),
          ),
        ),
      ],
    );
  }
}

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
    final colors = context.growthColors;
    final dt =
        '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _seaMist.withValues(alpha: 0.72),
            border: Border.all(color: _seaLine.withValues(alpha: 0.78)),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: _seaDeep.withValues(alpha: 0.72),
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBlock extends StatelessWidget {
  const _RatingBlock({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.labels,
    this.activeAsset,
  });

  final String title;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  final String? activeAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconBubble(icon: icon, color: _seaSoft),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 15,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final active = rating <= value;
            return _RatingButton(
              active: active,
              rating: rating,
              asset: activeAsset,
              onTap: () => onChanged(rating),
              icon: Icons.star_rounded,
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (label) => Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PawRatingRow extends StatelessWidget {
  const _PawRatingRow({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.endLabel,
  });

  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return _RatingButton(
                active: rating <= value,
                rating: rating,
                asset: _pawAsset,
                onTap: () => onChanged(rating),
                icon: Icons.pets_rounded,
                compact: true,
              );
            }),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            endLabel,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: colors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.active,
    required this.rating,
    required this.onTap,
    required this.icon,
    this.asset,
    this.compact = false,
  });

  final bool active;
  final int rating;
  final VoidCallback onTap;
  final IconData icon;
  final String? asset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final size = compact ? 30.0 : 46.0;

    return Semantics(
      button: true,
      label: '$rating 分',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          scale: active ? 1 : 0.88,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: active ? 1 : 0.58,
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: size,
              height: size,
              child: asset == null
                  ? Icon(
                      icon,
                      size: compact ? 25 : 38,
                      color: active ? const Color(0xFFFFC247) : colors.border,
                    )
                  : Image.asset(
                      active ? asset! : _pawGrayAsset,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFormCard extends StatefulWidget {
  const _AnimatedFormCard({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  State<_AnimatedFormCard> createState() => _AnimatedFormCardState();
}

class _AnimatedFormCardState extends State<_AnimatedFormCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.992, end: 1).animate(curved),
          child: _StudyCardSurface(colors: colors, child: widget.child),
        ),
      ),
    );
  }
}

class _StudyCardSurface extends StatelessWidget {
  const _StudyCardSurface({required this.colors, required this.child});

  final AppThemeColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: _seaLine.withValues(alpha: 0.54)),
        boxShadow: [
          BoxShadow(
            color: _seaDeep.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [
              colors.card.withValues(alpha: 0.20),
              _seaSoft.withValues(alpha: 0.14),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SaveFooter extends StatelessWidget {
  const _SaveFooter({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              scale: isSaving ? 0.98 : 1,
              child: _SeaSaveButton(
                text: '保存记录',
                icon: Icons.check_rounded,
                isLoading: isSaving,
                onTap: onSave,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Image.asset(_catLayAsset, width: 54, fit: BoxFit.contain),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '你专注的每一分钟，都是未来的自己在感谢你。',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: _seaDeep.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Opacity(
                  opacity: 0.74,
                  child: Image.asset(
                    _heartAsset,
                    width: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeaSaveButton extends StatelessWidget {
  const _SeaSaveButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || isLoading;

    return Opacity(
      opacity: disabled ? 0.58 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Ink(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_sea, _seaDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: _seaDeep.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntranceItem extends StatelessWidget {
  const _EntranceItem({
    required this.animation,
    required this.begin,
    required this.child,
  });

  final Animation<double> animation;
  final double begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, 1, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Material(
      color: colors.card.withValues(alpha: 0.76),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _seaLine.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: _seaDeep.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _seaDark, size: 20),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 17, color: _seaDeep),
    );
  }
}

String? _validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) return '请输入学习内容';
  return null;
}

String? _validateDuration(String? value) {
  if (value == null || value.trim().isEmpty) return '请输入学习时长';
  final duration = int.tryParse(value.trim());
  if (duration == null || duration <= 0) return '请输入有效时长';
  if (duration > 1440) return '单次学习时长不能超过24小时';
  return null;
}
