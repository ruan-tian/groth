import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:growth_os/app/design/design.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/domain/pet/pet_event.dart';
import 'package:growth_os/core/services/pet_event_bus.dart';
import 'package:growth_os/features/fitness/models/activity_type.dart';
import 'package:growth_os/shared/providers/dashboard_provider.dart';
import 'package:growth_os/shared/providers/fitness_provider.dart';
import 'package:growth_os/shared/widgets/common/common_widgets.dart';

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

  // 运动类型
  ActivityType _selectedActivityType = ActivityType.strength;

  // 运动类型专属字段
  BallType? _selectedBallType;
  YogaStyle? _selectedYogaStyle;
  SwimStroke? _selectedSwimStroke;
  OutdoorActivity? _selectedOutdoorActivity;
  final _distanceController = TextEditingController();
  final _customTitleController = TextEditingController();

  // 简单模式字段
  final _bodyPartController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // 专业模式字段
  final _titleController = TextEditingController();
  final DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  int _intensity = 3;
  int _fatigue = 3;
  final _feelingController = TextEditingController();
  final List<_ExerciseItem> _exercises = [];

  bool _saving = false;
  bool _advancedExpanded = false;

  // 预设部位
  final _presetBodyParts = ['胸', '背', '腿', '肩', '手臂', '核心', '全身'];
  static const _durationPresets = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _modeIndex = widget.initialMode == 'professional' ? 1 : 0;
    final duration = widget.initialDurationMinutes;
    if (duration != null && duration > 0) {
      _durationController.text = '$duration';
      _endTime = _startTime.add(Duration(minutes: duration));
    }
    _durationController.addListener(_handleFieldChanged);
    _bodyPartController.addListener(_handleFieldChanged);
    _customTitleController.addListener(_handleFieldChanged);
    _feelingController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _durationController.removeListener(_handleFieldChanged);
    _bodyPartController.removeListener(_handleFieldChanged);
    _customTitleController.removeListener(_handleFieldChanged);
    _feelingController.removeListener(_handleFieldChanged);
    _bodyPartController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    _feelingController.dispose();
    _distanceController.dispose();
    _customTitleController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    final duration = _durationMinutes;
    if (duration > 0) {
      _endTime = _startTime.add(Duration(minutes: duration));
    }
    if (mounted) setState(() {});
  }

  int get _durationMinutes => int.tryParse(_durationController.text) ?? 0;

  int get _estimatedExp {
    final expService = ref.read(expServiceProvider);
    return expService.calculateFitnessExp(
      durationMinutes: _durationMinutes,
      intensityLevel: _selectedActivityType == ActivityType.strength
          ? (_modeIndex == 1 ? _intensity : 0)
          : _intensity,
      exerciseCount: _selectedActivityType == ActivityType.strength
          ? _exercises.length
          : 0,
      hasFeeling: _feelingController.text.trim().isNotEmpty,
    );
  }

  String get _trainingSummary {
    final duration = _durationMinutes > 0 ? '$_durationMinutes 分钟' : '未填时长';
    final detail = _resolveBodyPart();
    final safeDetail = detail.isEmpty ? '待补充' : detail;
    return '${_selectedActivityType.label} · $duration · $safeDetail';
  }

  String get _durationSummary {
    if (_durationMinutes <= 0) return '选择或输入时长';
    if (_durationMinutes < 60) return '$_durationMinutes 分钟';
    final hours = _durationMinutes ~/ 60;
    final minutes = _durationMinutes % 60;
    return minutes == 0 ? '$hours 小时' : '$hours 小时 $minutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFFBF6),
      appBar: AppBar(
        title: Text('添加运动记录', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  112,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActivityTypeCard(),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedSwitcher(
                      duration: AppMotion.slow,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      child: _buildActivityDetailCard(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCommonInfoCard(),
                  ],
                ),
              ),
            ),
            _buildFixedSaveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fitness.withValues(alpha: 0.92),
            const Color(0xFFFFB36B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        boxShadow: AppShadows.colored(
          AppColors.fitness,
          blurRadius: 26,
          offsetY: 12,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Icon(
              _selectedActivityType.icon,
              size: 112,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _selectedActivityType.label,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _durationSummary,
                style: AppTextStyles.numberLarge.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _trainingSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildHeroMetric(
                    icon: Icons.bolt_rounded,
                    label: '预计 +$_estimatedExp EXP',
                  ),
                  _buildHeroMetric(
                    icon: Icons.local_fire_department_rounded,
                    label: _selectedActivityType == ActivityType.strength
                        ? (_modeIndex == 0 ? '简单记录' : '专业明细')
                        : '快捷记录',
                  ),
                  if (_exercises.isNotEmpty)
                    _buildHeroMetric(
                      icon: Icons.format_list_numbered_rounded,
                      label: '${_exercises.length} 个动作',
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── 运动类型选择卡片 ──
  Widget _buildActivityTypeCard() {
    return _buildFormCard(
      title: '运动类型',
      subtitle: '先选类型，下面只显示相关字段',
      icon: Icons.directions_run_rounded,
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ActivityType.values.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final type = ActivityType.values[index];
            return _buildActivityTypeTile(type);
          },
        ),
      ),
    );
  }

  Widget _buildActivityTypeTile(ActivityType type) {
    final isSelected = _selectedActivityType == type;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '选择${type.label}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedActivityType = type;
            _selectedBallType = null;
            _selectedYogaStyle = null;
            _selectedSwimStroke = null;
            _selectedOutdoorActivity = null;
            _distanceController.clear();
            _customTitleController.clear();
          });
        },
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          width: 104,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.fitness : AppColors.softOrange,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: isSelected
                  ? AppColors.fitness
                  : AppColors.fitness.withValues(alpha: 0.12),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? AppShadows.colored(
                    AppColors.fitness,
                    blurRadius: 16,
                    offsetY: 7,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type.icon,
                color: isSelected ? Colors.white : AppColors.fitness,
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                type.emoji,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 运动类型专属详情卡片 ──
  Widget _buildActivityDetailCard() {
    return _buildFormCard(
      key: ValueKey(_selectedActivityType),
      title: '${_selectedActivityType.label}专项',
      subtitle: '只填写这次训练真正相关的内容',
      icon: _selectedActivityType.icon,
      child: _buildActivitySpecificFields(),
    );
  }

  // ── 根据运动类型显示不同字段 ──
  Widget _buildActivitySpecificFields() {
    switch (_selectedActivityType) {
      case ActivityType.strength:
        return _buildStrengthFields();
      case ActivityType.running:
        return _buildRunningFields();
      case ActivityType.ballSports:
        return _buildBallSportsFields();
      case ActivityType.yoga:
        return _buildYogaFields();
      case ActivityType.swimming:
        return _buildSwimmingFields();
      case ActivityType.cycling:
        return _buildCyclingFields();
      case ActivityType.outdoor:
        return _buildOutdoorFields();
      case ActivityType.other:
        return _buildOtherFields();
    }
  }

  // ── 力量训练字段 ──
  Widget _buildStrengthFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('记录方式'),
        const SizedBox(height: AppSpacing.sm),
        SegmentedTabs(
          tabs: const ['简单模式', '专业模式'],
          selectedIndex: _modeIndex,
          height: 44,
          backgroundColor: AppColors.softOrange,
          selectedColor: Colors.white,
          borderRadius: AppRadius.full,
          onChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() => _modeIndex = index);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('训练部位'),
        const SizedBox(height: AppSpacing.sm),
        _buildBodyPartSelector(),
        if (_modeIndex == 1) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('训练标题 (可选)'),
          const SizedBox(height: AppSpacing.sm),
          _buildTextField(
            controller: _titleController,
            hint: '例如：胸肩训练、核心强化',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('训练动作'),
          const SizedBox(height: AppSpacing.sm),
          _buildExerciseList(),
          const SizedBox(height: AppSpacing.md),
          _buildAddExerciseButton(),
        ],
      ],
    );
  }

  // ── 跑步字段 ──
  Widget _buildRunningFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('跑步距离'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _distanceController,
          hint: '例如：5.0',
          icon: Icons.directions_run_rounded,
          keyboardType: TextInputType.number,
          suffix: '公里',
        ),
      ],
    );
  }

  // ── 球类字段 ──
  Widget _buildBallSportsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('选择球类'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: BallType.values.map((ball) {
            final isSelected = _selectedBallType == ball;
            return _buildChoicePill(
              label: ball.label,
              emoji: ball.emoji,
              selected: isSelected,
              onTap: () => setState(() => _selectedBallType = ball),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 瑜伽字段 ──
  Widget _buildYogaFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('瑜伽流派'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: YogaStyle.values.map((style) {
            final isSelected = _selectedYogaStyle == style;
            return _buildChoicePill(
              label: style.label,
              emoji: style.emoji,
              selected: isSelected,
              onTap: () => setState(() => _selectedYogaStyle = style),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 游泳字段 ──
  Widget _buildSwimmingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('泳姿'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: SwimStroke.values.map((stroke) {
            final isSelected = _selectedSwimStroke == stroke;
            return _buildChoicePill(
              label: stroke.label,
              emoji: stroke.emoji,
              selected: isSelected,
              onTap: () => setState(() => _selectedSwimStroke = stroke),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('游泳距离 (可选)'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _distanceController,
          hint: '例如：1.5',
          icon: Icons.pool_rounded,
          keyboardType: TextInputType.number,
          suffix: '公里',
        ),
      ],
    );
  }

  // ── 骑行字段 ──
  Widget _buildCyclingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('骑行距离'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _distanceController,
          hint: '例如：20.0',
          icon: Icons.directions_bike_rounded,
          keyboardType: TextInputType.number,
          suffix: '公里',
        ),
      ],
    );
  }

  // ── 户外字段 ──
  Widget _buildOutdoorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('活动类型'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: OutdoorActivity.values.map((activity) {
            final isSelected = _selectedOutdoorActivity == activity;
            return _buildChoicePill(
              label: activity.label,
              emoji: activity.emoji,
              selected: isSelected,
              onTap: () => setState(() => _selectedOutdoorActivity = activity),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 其他运动字段 ──
  Widget _buildOtherFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('运动名称'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _customTitleController,
          hint: '例如：跳绳、拳击、滑板...',
          icon: Icons.star_rounded,
        ),
      ],
    );
  }

  // ── 通用信息卡片 ──
  Widget _buildCommonInfoCard() {
    return _buildFormCard(
      title: '训练信息',
      subtitle: '先填时长，其他内容按需要展开',
      icon: Icons.timer_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('训练时长'),
          const SizedBox(height: AppSpacing.sm),
          _buildDurationQuickChips(),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _durationController,
            hint: '手动输入分钟数',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
            suffix: '分钟',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildAdvancedFields(),
        ],
      ),
    );
  }

  Widget _buildDurationQuickChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _durationPresets.map((minutes) {
        final selected = _durationMinutes == minutes;
        return _buildChoicePill(
          label: '$minutes 分钟',
          selected: selected,
          onTap: () {
            _durationController.text = '$minutes';
            _endTime = _startTime.add(Duration(minutes: minutes));
          },
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedFields() {
    final showRatings =
        _modeIndex == 1 || _selectedActivityType != ActivityType.strength;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.softOrange.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.fitness.withValues(alpha: 0.12)),
        ),
        child: ExpansionTile(
          initiallyExpanded: _advancedExpanded,
          onExpansionChanged: (expanded) {
            HapticFeedback.selectionClick();
            setState(() => _advancedExpanded = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          iconColor: AppColors.fitness,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            '进阶补充',
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            showRatings ? '强度、疲劳、感受与备注' : '训练感受与备注',
            style: AppTextStyles.caption,
          ),
          children: [
            if (showRatings) ...[
              _buildRatingBlock(
                title: '训练强度',
                value: _intensity,
                color: AppColors.fitness,
                onChanged: (value) => setState(() => _intensity = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildRatingBlock(
                title: '疲劳程度',
                value: _fatigue,
                color: AppColors.warning,
                onChanged: (value) => setState(() => _fatigue = value),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _buildSectionTitle('训练感受 (可选)'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: _feelingController,
              hint: '记录今天的状态、突破或感受...',
              icon: Icons.sentiment_satisfied,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('备注 (可选)'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: _notesController,
              hint: '补充说明...',
              icon: Icons.note,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBlock({
    required String title,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: AppSpacing.sm),
        RatingSelector(
          value: value,
          onChanged: (next) {
            HapticFeedback.selectionClick();
            onChanged(next);
          },
          activeColor: color,
          iconSize: 26,
        ),
      ],
    );
  }

  Widget _buildFormCard({
    Key? key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.fitness.withValues(alpha: 0.1)),
        boxShadow: AppShadows.colored(
          AppColors.fitness,
          blurRadius: 18,
          offsetY: 8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softOrange,
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: Icon(icon, color: AppColors.fitness, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }

  Widget _buildChoicePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? emoji,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.fitness : AppColors.softOrange,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected
                  ? AppColors.fitness
                  : AppColors.fitness.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      textInputAction:
          textInputAction ??
          (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        prefixIcon: Icon(
          icon,
          color: AppColors.fitness.withValues(alpha: 0.72),
        ),
        suffixText: suffix,
        suffixStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFBF6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: AppColors.fitness.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: AppColors.fitness.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.fitness, width: 1.3),
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
        return _buildChoicePill(
          label: part,
          selected: isSelected,
          onTap: () => setState(() => _bodyPartController.text = part),
        );
      }).toList(),
    );
  }

  // ── 动作列表 ──
  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.softOrange.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.fitness.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_rounded,
              color: AppColors.fitness.withValues(alpha: 0.72),
              size: 30,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '还没有动作明细',
              style: AppTextStyles.cardTitle.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '添加动作后会自动计入专业记录',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.fitness.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.softOrange,
              borderRadius: BorderRadius.circular(AppRadius.mlg),
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
            tooltip: '删除动作',
            onPressed: () => setState(() => _exercises.removeAt(index)),
          ),
        ],
      ),
    );
  }

  // ── 添加动作按钮 ──
  Widget _buildAddExerciseButton() {
    return Semantics(
      button: true,
      label: '添加训练动作',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showAddExerciseSheet();
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.fitness.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.fitness.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: AppColors.fitness),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '添加动作明细',
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.fitness,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildFixedSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trainingSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '预计 +$_estimatedExp EXP',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.fitness,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: '保存运动记录',
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                width: 132,
                height: 52,
                decoration: BoxDecoration(
                  color: _saving
                      ? AppColors.fitness.withValues(alpha: 0.55)
                      : AppColors.fitness,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: _saving
                      ? null
                      : AppShadows.colored(AppColors.fitness),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '保存',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 保存记录 ──
  // ── 获取运动类型对应的 bodyPart 值 ──
  String _resolveBodyPart() {
    switch (_selectedActivityType) {
      case ActivityType.strength:
        return _bodyPartController.text.trim();
      case ActivityType.running:
        return '跑步';
      case ActivityType.ballSports:
        return _selectedBallType?.label ?? '球类';
      case ActivityType.yoga:
        return _selectedYogaStyle?.label ?? '瑜伽';
      case ActivityType.swimming:
        return _selectedSwimStroke?.label ?? '游泳';
      case ActivityType.cycling:
        return '骑行';
      case ActivityType.outdoor:
        return _selectedOutdoorActivity?.label ?? '户外';
      case ActivityType.other:
        return _customTitleController.text.trim().isNotEmpty
            ? _customTitleController.text.trim()
            : '其他';
    }
  }

  // ── 获取标题 ──
  String? _resolveTitle() {
    if (_selectedActivityType == ActivityType.strength) {
      return _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim();
    }
    if (_selectedActivityType == ActivityType.other &&
        _customTitleController.text.trim().isNotEmpty) {
      return _customTitleController.text.trim();
    }
    return _selectedActivityType.label;
  }

  Future<void> _save() async {
    // 验证
    final bodyPart = _resolveBodyPart();
    if (_selectedActivityType == ActivityType.strength &&
        _modeIndex == 0 &&
        bodyPart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择训练部位')));
      return;
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

      final recordId = await repo.insertFitnessRecord(
        FitnessRecordsCompanion(
          mode: Value(
            _selectedActivityType == ActivityType.strength
                ? (_modeIndex == 0 ? 'simple' : 'professional')
                : 'simple',
          ),
          title: Value(_resolveTitle()),
          bodyPart: Value(bodyPart),
          activityType: Value(_selectedActivityType.name),
          startTime: Value(_startTime.millisecondsSinceEpoch),
          endTime: Value(_endTime.millisecondsSinceEpoch),
          durationMinutes: Value(duration),
          fatigueLevel: Value(
            _selectedActivityType == ActivityType.strength
                ? (_modeIndex == 1 ? _fatigue : null)
                : _fatigue,
          ),
          intensityLevel: Value(
            _selectedActivityType == ActivityType.strength
                ? (_modeIndex == 1 ? _intensity : null)
                : _intensity,
          ),
          feeling: Value(
            _feelingController.text.trim().isEmpty
                ? null
                : _feelingController.text.trim(),
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

      // 插入动作列表（力量训练专业模式）
      if (_selectedActivityType == ActivityType.strength && _modeIndex == 1) {
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
        intensityLevel: _selectedActivityType == ActivityType.strength
            ? (_modeIndex == 1 ? _intensity : 0)
            : _intensity,
        exerciseCount: _selectedActivityType == ActivityType.strength
            ? _exercises.length
            : 0,
        hasFeeling: _feelingController.text.trim().isNotEmpty,
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
          reason: '${_selectedActivityType.label}: $bodyPart ($duration分钟)',
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
