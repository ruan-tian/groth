import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/health_data.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../dashboard/providers/dashboard_provider.dart'
    show dashboardProvider;
import '../../health/providers/diet_provider.dart';
import '../../../shared/providers/repository_providers.dart'
    show dietRepositoryProvider, expRepositoryProvider;
import '../../../shared/providers/service_providers.dart'
    show expServiceProvider;

const _dietAssetRoot = 'assets/images/diet_record';
const _dietHeroAsset = '$_dietAssetRoot/diet_hero.webp';
const _dietFooterAsset = '$_dietAssetRoot/diet_deco_2.webp';
const _drumstickOnAsset = '$_dietAssetRoot/drumstick_on.webp';
const _drumstickOffAsset = '$_dietAssetRoot/drumstick_off.webp';

const _diet = Color(0xFFE3A21A);
const _dietDeep = Color(0xFFB06E00);
const _dietDark = Color(0xFF66430D);
const _dietMist = Color(0xFFFFFBF0);
const _dietSoft = Color(0xFFFFF2CC);
const _dietLine = Color(0xFFF2DEAA);

class AddDietRecordPage extends ConsumerStatefulWidget {
  const AddDietRecordPage({super.key});

  @override
  ConsumerState<AddDietRecordPage> createState() => _AddDietRecordPageState();
}

class _AddDietRecordPageState extends ConsumerState<AddDietRecordPage> {
  final _foodController = TextEditingController();
  final _noteController = TextEditingController();

  String _mealType = 'lunch';
  String _portionLevel = 'normal';
  String _calorieLevel = 'normal';
  String _proteinLevel = 'medium';
  int _healthScore = 3;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _foodController.addListener(_refreshPreview);
    _noteController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _foodController.removeListener(_refreshPreview);
    _noteController.removeListener(_refreshPreview);
    _foodController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  int get _estimatedDietExp {
    final expService = ref.read(expServiceProvider);
    return expService.calculateDietExp(
      hasCompleteMeals:
          _mealType == 'breakfast' ||
          _mealType == 'lunch' ||
          _mealType == 'dinner',
      hasReasonableTarget: _proteinLevel == 'medium' || _proteinLevel == 'high',
    );
  }

  String get _mealLabel => switch (_mealType) {
    'breakfast' => '早餐',
    'lunch' => '午餐',
    'dinner' => '晚餐',
    'snack' => '加餐',
    _ => '饮食',
  };

  String get _foodPreview {
    final text = _foodController.text.trim();
    return text.isEmpty ? '还没填写吃了什么' : text;
  }

  String get _healthText => switch (_healthScore) {
    1 => '需要调整',
    2 => '略不均衡',
    3 => '基本正常',
    4 => '比较均衡',
    _ => '非常健康',
  };

  Future<void> _save() async {
    if (_foodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入食物描述')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final companion = DietRecordsCompanion(
        mealDate: Value(dateStr),
        mealType: Value(_mealType),
        foodText: Value(_foodController.text.trim()),
        portionLevel: Value(_portionLevel),
        calorieLevel: Value(_calorieLevel),
        proteinLevel: Value(_proteinLevel),
        healthScore: Value(_healthScore),
        note: Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

      final expService = ref.read(expServiceProvider);
      final repo = ref.read(dietRepositoryProvider);
      final expRepo = ref.read(expRepositoryProvider);
      final oldTotal = await expRepo.getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      final dietExp = expService.calculateDietExp(
        hasCompleteMeals:
            _mealType == 'breakfast' ||
            _mealType == 'lunch' ||
            _mealType == 'dinner',
        hasReasonableTarget:
            _proteinLevel == 'medium' || _proteinLevel == 'high',
      );

      await repo.saveDietRecordWithExp(
        record: companion,
        exp: dietExp,
        reason: 'diet: ${_foodController.text.trim()}',
        createdAt: now.millisecondsSinceEpoch,
      );

      if (dietExp > 0) {
        final newLevel = expService.calculateLevel(oldTotal + dietExp);
        if (newLevel > oldLevel) {
          PetEventBus.instance.emit(
            PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
          );
        }
      }

      ref.invalidate(todayDietRecordsProvider);
      ref.invalidate(todayDietCountProvider);
      ref.invalidate(todayAvgHealthScoreProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(dailyCalorieWaterProvider(7));
      ref.invalidate(dailyCalorieWaterProvider(30));
      ref.invalidate(dailyCalorieWaterProvider(365));

      if (mounted) {
        PetEventBus.instance.emit(
          PetEvent.moduleCompleted(
            eventId: 'diet_${DateTime.now().millisecondsSinceEpoch}',
            type: PetEventType.dietCompleted,
            module: 'diet',
          ),
        );

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('饮食记录已保存')));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _dietMist,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              _dietMist,
              _dietSoft.withValues(alpha: 0.64),
            ],
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
                        _DietHeader(
                          onBack: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDietHeroCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildMealTypeSelector(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFoodCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildNutritionCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildHealthScoreSelector(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildNoteField(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSaveButton(),
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

  Widget _buildDietHeroCard() {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: _dietLine.withValues(alpha: 0.60)),
        boxShadow: [
          BoxShadow(
            color: _dietDeep.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            bottom: -12,
            child: Image.asset(
              _dietFooterAsset,
              width: 112,
              fit: BoxFit.contain,
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
                        color: _dietSoft.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: _dietLine),
                      ),
                      child: Text(
                        _mealLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: _dietDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _foodPreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.numberLarge.copyWith(
                        color: _dietDark,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '健康 $_healthScore 分 · $_healthText · 预计 +$_estimatedDietExp EXP',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildFoodCard() {
    return _buildFormCard(
      title: '吃了什么',
      subtitle: '一句话记录即可，后面再补营养倾向',
      icon: Icons.restaurant_menu_rounded,
      child: _buildFoodField(),
    );
  }

  Widget _buildNutritionCard() {
    return _buildFormCard(
      title: '营养判断',
      subtitle: '用三段选择快速描述这餐的整体情况',
      icon: Icons.eco_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('份量'),
          const SizedBox(height: AppSpacing.sm),
          _buildPortionSelector(),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('热量'),
          const SizedBox(height: AppSpacing.sm),
          _buildCalorieSelector(),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('蛋白质'),
          const SizedBox(height: AppSpacing.sm),
          _buildProteinSelector(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colors = context.growthColors;
    return Text(
      title,
      style: AppTextStyles.cardTitle.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return _buildFormCard(
      title: '餐次',
      subtitle: '先确定这条记录属于哪一餐',
      icon: Icons.schedule_rounded,
      child: _buildSegmentSurface(
        children: [
          _buildMealTypeChip('breakfast', '早餐', Icons.free_breakfast_rounded),
          _buildMealTypeChip('lunch', '午餐', Icons.lunch_dining_rounded),
          _buildMealTypeChip('dinner', '晚餐', Icons.dinner_dining_rounded),
          _buildMealTypeChip('snack', '加餐', Icons.cookie_rounded),
        ],
      ),
    );
  }

  Widget _buildMealTypeChip(String value, String label, IconData icon) {
    final colors = context.growthColors;
    final isSelected = _mealType == value;
    return Semantics(
      button: true,
      label: '选择$label',
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _mealType = value);
        },
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? _diet : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colors.textOnAccent : colors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

  Widget _buildFoodField() {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: _dietMist.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: _dietLine.withValues(alpha: 0.78)),
      ),
      child: TextField(
        controller: _foodController,
        textInputAction: TextInputAction.next,
        maxLength: 500,
        minLines: 1,
        maxLines: 2,
        style: AppTextStyles.body.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: '例如：鸡胸肉 + 米饭 + 青菜',
          hintStyle: AppTextStyles.body.copyWith(color: colors.textHint),
          prefixIcon: Icon(
            Icons.restaurant_rounded,
            size: 18,
            color: _dietDeep.withValues(alpha: 0.72),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildPortionSelector() {
    return _buildSegmentSurface(
      children: [
        _buildDietSegmentChip('small', '少量', _portionLevel, (value) {
          setState(() => _portionLevel = value);
        }),
        _buildDietSegmentChip('normal', '正常', _portionLevel, (value) {
          setState(() => _portionLevel = value);
        }),
        _buildDietSegmentChip('large', '大量', _portionLevel, (value) {
          setState(() => _portionLevel = value);
        }),
      ],
    );
  }

  Widget _buildCalorieSelector() {
    final colors = context.growthColors;
    return _buildSegmentSurface(
      children: [
        _buildDietSegmentChip(
          'low',
          '偏低',
          _calorieLevel,
          (value) => setState(() => _calorieLevel = value),
          color: colors.success,
        ),
        _buildDietSegmentChip(
          'normal',
          '适中',
          _calorieLevel,
          (value) => setState(() => _calorieLevel = value),
          color: _diet,
        ),
        _buildDietSegmentChip(
          'high',
          '偏高',
          _calorieLevel,
          (value) => setState(() => _calorieLevel = value),
          color: colors.danger,
        ),
      ],
    );
  }

  Widget _buildProteinSelector() {
    final colors = context.growthColors;
    return _buildSegmentSurface(
      children: [
        _buildDietSegmentChip(
          'low',
          '偏少',
          _proteinLevel,
          (value) => setState(() => _proteinLevel = value),
          color: colors.warning,
        ),
        _buildDietSegmentChip(
          'medium',
          '适中',
          _proteinLevel,
          (value) => setState(() => _proteinLevel = value),
          color: _diet,
        ),
        _buildDietSegmentChip(
          'high',
          '充足',
          _proteinLevel,
          (value) => setState(() => _proteinLevel = value),
          color: colors.success,
        ),
      ],
    );
  }

  Widget _buildSegmentSurface({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _dietMist.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _dietLine.withValues(alpha: 0.78)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: children.map((child) => Expanded(child: child)).toList(),
      ),
    );
  }

  Widget _buildDietSegmentChip(
    String value,
    String label,
    String groupValue,
    ValueChanged<String> onChanged, {
    Color? color,
  }) {
    final colors = context.growthColors;
    final selectedColor = color ?? _diet;
    final isSelected = value == groupValue;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '选择$label',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? colors.textOnAccent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: _dietLine.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: _dietDeep.withValues(alpha: 0.06),
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
                  color: _dietSoft,
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: Icon(icon, color: _dietDeep, size: 21),
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

  Widget _buildHealthScoreSelector() {
    return _buildFormCard(
      title: '健康评分',
      subtitle: _healthText,
      icon: Icons.restaurant_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _dietMist.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: _dietLine.withValues(alpha: 0.78)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final score = index + 1;
                final active = index < _healthScore;
                return Semantics(
                  button: true,
                  label: '评分$score分',
                  selected: active,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _healthScore = score);
                    },
                    child: AnimatedScale(
                      scale: active ? 1 : 0.88,
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: active ? 1 : 0.58,
                        duration: const Duration(milliseconds: 180),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Image.asset(
                            active ? _drumstickOnAsset : _drumstickOffAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _healthText,
              style: AppTextStyles.cardTitle.copyWith(
                color: _dietDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    final colors = context.growthColors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          border: Border.all(color: _dietLine.withValues(alpha: 0.56)),
          boxShadow: [
            BoxShadow(
              color: _dietDeep.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          iconColor: _dietDeep,
          collapsedIconColor: colors.textSecondary,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _dietSoft,
              borderRadius: BorderRadius.circular(AppRadius.mlg),
            ),
            child: Icon(Icons.note_alt_rounded, color: _dietDeep, size: 21),
          ),
          title: Text(
            '补充说明',
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 17,
            ),
          ),
          subtitle: Text(
            _noteController.text.trim().isEmpty
                ? '可选，记录口味、情绪或特殊情况'
                : _noteController.text.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: _dietMist.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: _dietLine.withValues(alpha: 0.78)),
              ),
              child: TextField(
                controller: _noteController,
                textInputAction: TextInputAction.newline,
                maxLength: 1000,
                maxLines: 3,
                style: AppTextStyles.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '记录其他信息...',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: colors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.note_outlined,
                    size: 18,
                    color: _dietDeep.withValues(alpha: 0.72),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
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
                border: Border.all(color: _dietLine.withValues(alpha: 0.62)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    _dietHeroAsset,
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
                          '$_mealLabel · $_healthScore 分 · $_healthText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: _dietDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '预计 +$_estimatedDietExp EXP，认真吃饭也算成长',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: _dietDeep,
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
              label: '保存饮食记录',
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOutCubic,
                  scale: _isSaving ? 0.98 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _isSaving
                          ? null
                          : const LinearGradient(
                              colors: [_diet, _dietDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isSaving ? _diet.withValues(alpha: 0.54) : null,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: _isSaving
                          ? null
                          : [
                              BoxShadow(
                                color: _dietDeep.withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _isSaving
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
                                  '保存饮食记录',
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
}

class _DietHeader extends StatelessWidget {
  const _DietHeader({required this.onBack});

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
                color: _dietSoft.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(AppRadius.xxxl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -4,
            child: Image.asset(_dietHeroAsset, width: 134, fit: BoxFit.contain),
          ),
          Positioned(
            left: 0,
            top: 6,
            child: _DietCircleButton(
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
                  '记录饮食',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 28,
                    color: _dietDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '认真吃饭，也是在照顾未来的自己',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _dietDeep.withValues(alpha: 0.72),
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

class _DietCircleButton extends StatelessWidget {
  const _DietCircleButton({required this.icon, required this.onTap});

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
            border: Border.all(color: _dietLine.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: _dietDeep.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _dietDark, size: 20),
        ),
      ),
    );
  }
}
