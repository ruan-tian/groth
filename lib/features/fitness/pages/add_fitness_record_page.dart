import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:growth_os/app/design/design.dart';
import '../models/fitness_data.dart';
import 'package:growth_os/core/domain/pet/pet_event.dart';
import 'package:growth_os/core/services/pet_event_bus.dart';
import 'package:growth_os/features/fitness/models/activity_type.dart';
import 'package:growth_os/features/fitness/providers/fitness_dashboard_facade.dart';
import 'package:growth_os/features/fitness/providers/fitness_provider.dart';
import 'package:growth_os/shared/providers/repository_providers.dart';
import 'package:growth_os/shared/providers/service_providers.dart';
import 'package:growth_os/shared/widgets/common/common_widgets.dart';

const _fitnessAssetRoot = 'assets/images/fitness_record';
const _fitnessHeroAsset = '$_fitnessAssetRoot/fitness_record_hero.webp';
const _fitnessFooterAsset = '$_fitnessAssetRoot/fitness_record_footer.webp';
const _fitnessDumbbellsAsset = '$_fitnessAssetRoot/fitness_dumbbells.webp';

const _fit = Color(0xFF18A884);
const _fitDeep = Color(0xFF08735F);
const _fitDark = Color(0xFF10493F);
const _fitMist = Color(0xFFF2FBF7);
const _fitSoft = Color(0xFFE2F6EF);
const _fitLine = Color(0xFFCFE8DF);

class AddFitnessRecordPage extends ConsumerStatefulWidget {
  const AddFitnessRecordPage({
    super.key,
    this.initialMode = 'simple',
    this.initialDurationMinutes,
    this.initialBodyPart,
  });

  final String initialMode;
  final int? initialDurationMinutes;
  final String? initialBodyPart;

  @override
  ConsumerState<AddFitnessRecordPage> createState() =>
      _AddFitnessRecordPageState();
}

class _AddFitnessRecordPageState extends ConsumerState<AddFitnessRecordPage> {
  late int _modeIndex;
  ActivityType _selectedActivityType = ActivityType.strength;

  BallType? _selectedBallType;
  YogaStyle? _selectedYogaStyle;
  SwimStroke? _selectedSwimStroke;
  OutdoorActivity? _selectedOutdoorActivity;

  final _distanceController = TextEditingController();
  final _customTitleController = TextEditingController();
  final _bodyPartController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();
  final _feelingController = TextEditingController();

  final DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  final List<_ExerciseItem> _exercises = [];

  int _intensity = 3;
  int _fatigue = 3;
  bool _saving = false;
  bool _advancedExpanded = false;

  static const _presetBodyParts = ['胸', '背', '腿', '肩', '手臂', '核心', '全身'];
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
    final bodyPart = widget.initialBodyPart;
    if (bodyPart != null && bodyPart.isNotEmpty) {
      _bodyPartController.text = bodyPart;
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
    _distanceController.dispose();
    _customTitleController.dispose();
    _bodyPartController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    _feelingController.dispose();
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

  bool get _showRatings =>
      _modeIndex == 1 || _selectedActivityType != ActivityType.strength;

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
    return '${_selectedActivityType.label} · $duration · ${detail.isEmpty ? '待补充' : detail}';
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
      backgroundColor: _fitMist,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, _fitMist, _fitSoft.withValues(alpha: 0.64)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 720
                  ? 640.0
                  : double.infinity;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FitnessRecordHeader(
                          onBack: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildHeroCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildActivityTypeCard(),
                        const SizedBox(height: AppSpacing.lg),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          reverseDuration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutQuart,
                          switchOutCurve: Curves.easeInQuad,
                          transitionBuilder: (child, animation) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutQuart,
                            );
                            return FadeTransition(
                              opacity: curved,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.025),
                                  end: Offset.zero,
                                ).animate(curved),
                                child: child,
                              ),
                            );
                          },
                          child: _buildActivityDetailCard(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildCommonInfoCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFixedSaveBar(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: _fitLine.withValues(alpha: 0.58)),
        boxShadow: [
          BoxShadow(
            color: _fitDeep.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            bottom: -16,
            child: Opacity(
              opacity: 0.78,
              child: Image.asset(
                _fitnessDumbbellsAsset,
                width: 118,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _fitSoft.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: _fitLine),
                      ),
                      child: Text(
                        _selectedActivityType.label,
                        style: AppTextStyles.caption.copyWith(
                          color: _fitDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _durationSummary,
                      style: AppTextStyles.numberLarge.copyWith(
                        color: _fitDark,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _trainingSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textSecondary,
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
              ),
              const SizedBox(width: 96),
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
        color: _fitMist.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _fitLine.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _fitDeep, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: _fitDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTypeCard() {
    return _buildFormCard(
      title: '运动类型',
      subtitle: '先选择类型，下面只显示相关字段',
      icon: Icons.directions_run_rounded,
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ActivityType.values.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _buildActivityTypeTile(ActivityType.values[index]);
          },
        ),
      ),
    );
  }

  Widget _buildActivityTypeTile(ActivityType type) {
    final colors = context.growthColors;
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 104,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? _fit : colors.card.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: isSelected ? _fit : _fitLine.withValues(alpha: 0.72),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _fitDeep.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type.icon,
                color: isSelected ? colors.textOnAccent : _fitDeep,
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  color: isSelected ? colors.textOnAccent : colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                type.emoji,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? colors.textOnAccent
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDetailCard() {
    return _buildFormCard(
      key: ValueKey(_selectedActivityType),
      title: '${_selectedActivityType.label}专项',
      subtitle: '只填写这次训练真正相关的内容',
      icon: _selectedActivityType.icon,
      child: _buildActivitySpecificFields(),
    );
  }

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

  Widget _buildStrengthFields() {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('记录方式'),
        const SizedBox(height: AppSpacing.sm),
        SegmentedTabs(
          tabs: const ['简单模式', '专业模式'],
          selectedIndex: _modeIndex,
          height: 44,
          backgroundColor: _fitSoft,
          selectedColor: colors.textOnAccent,
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

  Widget _buildRunningFields() {
    return _buildDistanceField(title: '跑步距离', icon: Icons.directions_run);
  }

  Widget _buildCyclingFields() {
    return _buildDistanceField(title: '骑行距离', icon: Icons.directions_bike);
  }

  Widget _buildDistanceField({required String title, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _distanceController,
          hint: '例如：5.0',
          icon: icon,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffix: '公里',
        ),
      ],
    );
  }

  Widget _buildBallSportsFields() {
    return _buildEnumPills(
      title: '选择球类',
      children: BallType.values.map((ball) {
        return _buildChoicePill(
          label: ball.label,
          emoji: ball.emoji,
          selected: _selectedBallType == ball,
          onTap: () => setState(() => _selectedBallType = ball),
        );
      }).toList(),
    );
  }

  Widget _buildYogaFields() {
    return _buildEnumPills(
      title: '瑜伽流派',
      children: YogaStyle.values.map((style) {
        return _buildChoicePill(
          label: style.label,
          emoji: style.emoji,
          selected: _selectedYogaStyle == style,
          onTap: () => setState(() => _selectedYogaStyle = style),
        );
      }).toList(),
    );
  }

  Widget _buildSwimmingFields() {
    return _buildEnumPills(
      title: '泳姿',
      children: SwimStroke.values.map((stroke) {
        return _buildChoicePill(
          label: stroke.label,
          emoji: stroke.emoji,
          selected: _selectedSwimStroke == stroke,
          onTap: () => setState(() => _selectedSwimStroke = stroke),
        );
      }).toList(),
    );
  }

  Widget _buildOutdoorFields() {
    return _buildEnumPills(
      title: '户外类型',
      children: OutdoorActivity.values.map((activity) {
        return _buildChoicePill(
          label: activity.label,
          emoji: activity.emoji,
          selected: _selectedOutdoorActivity == activity,
          onTap: () => setState(() => _selectedOutdoorActivity = activity),
        );
      }).toList(),
    );
  }

  Widget _buildEnumPills({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children,
        ),
      ],
    );
  }

  Widget _buildOtherFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('运动名称'),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _customTitleController,
          hint: '例如：跳绳、搏击、滑板...',
          icon: Icons.star_rounded,
        ),
      ],
    );
  }

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
        return _buildChoicePill(
          label: '$minutes 分钟',
          selected: _durationMinutes == minutes,
          onTap: () {
            _durationController.text = '$minutes';
            _endTime = _startTime.add(Duration(minutes: minutes));
          },
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedFields() {
    final colors = context.growthColors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: _fitSoft.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: _fitLine.withValues(alpha: 0.72)),
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
          iconColor: _fitDeep,
          collapsedIconColor: colors.textSecondary,
          title: Text(
            '进阶补充',
            style: AppTextStyles.cardTitle.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            _showRatings ? '强度、疲劳、感受与备注' : '训练感受与备注',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          children: [
            if (_showRatings) ...[
              _buildRatingBlock(
                title: '训练强度',
                value: _intensity,
                color: _fit,
                onChanged: (value) => setState(() => _intensity = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildRatingBlock(
                title: '疲劳程度',
                value: _fatigue,
                color: const Color(0xFFF2B15A),
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
    final colors = context.growthColors;
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: _fitLine.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: _fitDeep.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  color: _fitSoft,
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: Icon(icon, color: _fitDeep, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
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
    final colors = context.growthColors;
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
            color: selected ? _fit : _fitSoft.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected ? _fit : _fitLine.withValues(alpha: 0.78),
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
                  color: selected ? colors.textOnAccent : colors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colors = context.growthColors;
    return Text(
      title,
      style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextInputAction? textInputAction,
    String? suffix,
  }) {
    final colors = context.growthColors;
    return TextField(
      controller: controller,
      textInputAction:
          textInputAction ??
          (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: colors.textHint),
        prefixIcon: Icon(icon, color: _fitDeep.withValues(alpha: 0.74)),
        suffixText: suffix,
        suffixStyle: AppTextStyles.caption.copyWith(
          color: colors.textSecondary,
        ),
        filled: true,
        fillColor: _fitMist.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: _fitLine.withValues(alpha: 0.78)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: _fitLine.withValues(alpha: 0.78)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: _fit, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildBodyPartSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _presetBodyParts.map((part) {
        return _buildChoicePill(
          label: part,
          selected: _bodyPartController.text == part,
          onTap: () => setState(() => _bodyPartController.text = part),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseList() {
    final colors = context.growthColors;
    if (_exercises.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: _fitSoft.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: _fitLine.withValues(alpha: 0.72)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_rounded,
              color: _fitDeep.withValues(alpha: 0.72),
              size: 30,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '还没有动作明细',
              style: AppTextStyles.cardTitle.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '添加动作后会自动计入专业记录',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _exercises.asMap().entries.map((entry) {
        return _buildExerciseTile(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildExerciseTile(int index, _ExerciseItem exercise) {
    final colors = context.growthColors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _fitMist.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: _fitLine.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _fitSoft,
              borderRadius: BorderRadius.circular(AppRadius.mlg),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(fontWeight: FontWeight.w600, color: _fitDeep),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${exercise.sets}组 × ${exercise.reps}次'
                  '${exercise.weight != null ? ' · ${exercise.weight}kg' : ''}'
                  '${exercise.restSeconds != null ? ' · 休息${exercise.restSeconds}秒' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: colors.textTertiary),
            tooltip: '删除动作',
            onPressed: () => setState(() => _exercises.removeAt(index)),
          ),
        ],
      ),
    );
  }

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
            color: _fitSoft.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: _fitLine.withValues(alpha: 0.90)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: _fitDeep),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '添加动作明细',
                style: AppTextStyles.cardTitle.copyWith(
                  color: _fitDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            SizedBox(
              width: double.infinity,
              child: _FitSheetButton(
                onTap: () {
                  if (nameController.text.trim().isEmpty) return;
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
                },
              ),
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
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textHint),
            prefixIcon: Icon(icon, color: _fitDeep, size: 18),
            isDense: true,
            filled: true,
            fillColor: _fitMist.withValues(alpha: 0.72),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: _fitLine.withValues(alpha: 0.78)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(color: _fitLine.withValues(alpha: 0.78)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: const BorderSide(color: _fit, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedSaveBar() {
    final colors = context.growthColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: _fitLine.withValues(alpha: 0.62)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    _fitnessFooterAsset,
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _trainingSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: _fitDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '预计 +$_estimatedExp EXP，坚持的每一次都会算数',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: _fitDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              label: '保存运动记录',
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOutCubic,
                  scale: _saving ? 0.98 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _saving
                          ? null
                          : const LinearGradient(
                              colors: [_fit, _fitDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _saving ? _fit.withValues(alpha: 0.54) : null,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: _saving
                          ? null
                          : [
                              BoxShadow(
                                color: _fitDeep.withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _saving
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
                                const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '保存运动记录',
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
            ),
          ],
        ),
      ),
    );
  }

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
    if (duration <= 0 || duration > 1440) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的训练时长（1-1440分钟）')));
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(fitnessRepositoryProvider);
      final now = DateTime.now();
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
      final oldTotal = await ref.read(expRepositoryProvider).getTotalExp();
      final exerciseCompanions = <FitnessExercisesCompanion>[
        if (_selectedActivityType == ActivityType.strength && _modeIndex == 1)
          for (final exercise in _exercises)
            FitnessExercisesCompanion(
              exerciseName: Value(exercise.name),
              sets: Value(exercise.sets),
              reps: Value(exercise.reps),
              weight: Value(exercise.weight),
              restSeconds: Value(exercise.restSeconds),
              createdAt: Value(now.millisecondsSinceEpoch),
            ),
      ];

      await repo.saveFitnessRecordWithExp(
        record: FitnessRecordsCompanion(
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
        exercises: exerciseCompanions,
        exp: exp,
        reason: '${_selectedActivityType.label}: $bodyPart ($duration min)',
        createdAt: now.millisecondsSinceEpoch,
      );

      final oldLevel = expService.calculateLevel(oldTotal);
      final newLevel = expService.calculateLevel(oldTotal + exp);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(
          PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
        );
      }

      ref.invalidate(recentFitnessRecordsProvider);
      ref.invalidate(todayFitnessMinutesProvider);
      ref.invalidate(weeklyFitnessCountProvider);
      ref.read(fitnessDashboardFacadeProvider).refreshDashboard();
      ref.invalidate(fitnessChartDataProvider(7));
      ref.invalidate(fitnessChartDataProvider(30));
      ref.invalidate(fitnessChartDataProvider(365));

      if (mounted) {
        PetEventBus.instance.emit(
          PetEvent.moduleCompleted(
            eventId: 'fitness_${DateTime.now().millisecondsSinceEpoch}',
            type: PetEventType.fitnessCompleted,
            module: 'fitness',
          ),
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已保存，获得 $exp EXP')));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _FitnessRecordHeader extends StatelessWidget {
  const _FitnessRecordHeader({required this.onBack});

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
              width: 128,
              height: 88,
              decoration: BoxDecoration(
                color: _fitSoft.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(AppRadius.xxxl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -4,
            child: Image.asset(
              _fitnessHeroAsset,
              width: 134,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            top: 6,
            child: _FitnessCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ),
          Positioned(
            left: 2,
            right: 136,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加运动记录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 28,
                    color: _fitDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '记录每一次训练，让身体变化被看见',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _fitDeep.withValues(alpha: 0.72),
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

class _FitnessCircleButton extends StatelessWidget {
  const _FitnessCircleButton({required this.icon, required this.onTap});

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
            border: Border.all(color: _fitLine.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: _fitDeep.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _fitDark, size: 20),
        ),
      ),
    );
  }
}

class _FitSheetButton extends StatelessWidget {
  const _FitSheetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_fit, _fitDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: _fitDeep.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '添加动作',
              style: AppTextStyles.cardTitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
