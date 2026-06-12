import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../../shared/providers/dashboard_provider.dart'
    show dashboardProvider, databaseProvider;
import '../../../shared/providers/diet_provider.dart';
import '../../../shared/providers/repository_providers.dart'
    show dietRepositoryProvider, expRepositoryProvider;
import '../../../shared/providers/service_providers.dart'
    show expServiceProvider;

/// 添加饮食记录页面
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

      // 原子操作：插入记录 + 经验日志
      final expService = ref.read(expServiceProvider);
      final db = ref.read(databaseProvider);
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
      await db.transaction(() async {
        await repo.insertDietRecord(companion);

        if (dietExp > 0) {
          await expRepo.insertExpLog(
            GrowthExpLogsCompanion.insert(
              sourceType: 'diet',
              sourceId: 0,
              expValue: dietExp,
              reason: '饮食: ${_foodController.text.trim()}',
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
        }
      });

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
        // 发送宠物事件
        final eventId = 'diet_${DateTime.now().millisecondsSinceEpoch}';
        PetEventBus.instance.emit(
          PetEvent.moduleCompleted(
            eventId: eventId,
            type: PetEventType.dietCompleted,
            module: 'diet',
          ),
        );

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('饮食记录已保存'),
            backgroundColor: Color(0xFF6B8E23),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFFBF6),
      appBar: AppBar(
        title: Text('记录饮食', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDietHeroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.diet, Color(0xFFFFC36B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        boxShadow: AppShadows.colored(
          AppColors.diet,
          blurRadius: 26,
          offsetY: 12,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -22,
            child: Icon(
              Icons.restaurant_rounded,
              size: 118,
              color: Colors.white.withValues(alpha: 0.14),
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
                  _mealLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
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
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '健康 $_healthScore 星 · $_healthText · 预计 +$_estimatedDietExp EXP',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    return Text(
      title,
      style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w800),
    );
  }

  // ---------------------------------------------------------------------------
  // 餐次选择
  // ---------------------------------------------------------------------------

  Widget _buildMealTypeSelector() {
    return _buildFormCard(
      title: '餐次',
      subtitle: '先确定这条记录属于哪一餐',
      icon: Icons.schedule_rounded,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.diet.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildMealTypeChip(
                'breakfast',
                '早餐',
                Icons.free_breakfast_rounded,
              ),
            ),
            Expanded(
              child: _buildMealTypeChip(
                'lunch',
                '午餐',
                Icons.lunch_dining_rounded,
              ),
            ),
            Expanded(
              child: _buildMealTypeChip(
                'dinner',
                '晚餐',
                Icons.dinner_dining_rounded,
              ),
            ),
            Expanded(
              child: _buildMealTypeChip('snack', '加餐', Icons.cookie_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeChip(String value, String label, IconData icon) {
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
            color: isSelected ? AppColors.diet : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 食物描述
  // ---------------------------------------------------------------------------

  Widget _buildFoodField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.diet.withValues(alpha: 0.14)),
      ),
      child: TextField(
        controller: _foodController,
        textInputAction: TextInputAction.next,
        minLines: 1,
        maxLines: 2,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: '例如：鸡胸肉 + 米饭 + 青菜',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
          prefixIcon: Icon(
            Icons.restaurant_rounded,
            size: 18,
            color: AppColors.diet.withValues(alpha: 0.72),
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

  // ---------------------------------------------------------------------------
  // 份量选择
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // 热量选择
  // ---------------------------------------------------------------------------

  Widget _buildCalorieSelector() {
    return _buildSegmentSurface(
      children: [
        _buildDietSegmentChip(
          'low',
          '偏低',
          _calorieLevel,
          (value) => setState(() => _calorieLevel = value),
          color: AppColors.success,
        ),
        _buildDietSegmentChip(
          'normal',
          '适中',
          _calorieLevel,
          (value) => setState(() => _calorieLevel = value),
          color: AppColors.diet,
        ),
        _buildDietSegmentChip(
          'high',
          '偏高',
          _calorieLevel,
          (value) => setState(() => _calorieLevel = value),
          color: AppColors.danger,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 蛋白质选择
  // ---------------------------------------------------------------------------

  Widget _buildProteinSelector() {
    return _buildSegmentSurface(
      children: [
        _buildDietSegmentChip(
          'low',
          '偏少',
          _proteinLevel,
          (value) => setState(() => _proteinLevel = value),
          color: AppColors.warning,
        ),
        _buildDietSegmentChip(
          'medium',
          '适中',
          _proteinLevel,
          (value) => setState(() => _proteinLevel = value),
          color: AppColors.diet,
        ),
        _buildDietSegmentChip(
          'high',
          '充足',
          _proteinLevel,
          (value) => setState(() => _proteinLevel = value),
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildSegmentSurface({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.diet.withValues(alpha: 0.12)),
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
    Color color = AppColors.diet,
  }) {
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
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.diet.withValues(alpha: 0.1)),
        boxShadow: AppShadows.colored(
          AppColors.diet,
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
                  color: AppColors.softGold,
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: Icon(icon, color: AppColors.diet, size: 21),
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

  // ---------------------------------------------------------------------------
  // 健康评分
  // ---------------------------------------------------------------------------

  Widget _buildHealthScoreSelector() {
    return _buildFormCard(
      title: '健康评分',
      subtitle: _healthText,
      icon: Icons.star_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.diet.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              children: List.generate(5, (index) {
                final score = index + 1;
                final isSelected = index < _healthScore;
                return Semantics(
                  button: true,
                  label: '评分$score分',
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _healthScore = score);
                    },
                    child: AnimatedScale(
                      scale: isSelected ? 1 : 0.92,
                      duration: AppMotion.fast,
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 38,
                        color: isSelected
                            ? AppColors.warning
                            : AppColors.ratingInactive,
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
                color: AppColors.diet,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 备注
  // ---------------------------------------------------------------------------

  Widget _buildNoteField() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          border: Border.all(color: AppColors.diet.withValues(alpha: 0.1)),
          boxShadow: AppShadows.colored(
            AppColors.diet,
            blurRadius: 18,
            offsetY: 8,
          ),
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
          iconColor: AppColors.diet,
          collapsedIconColor: AppColors.textSecondary,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.softGold,
              borderRadius: BorderRadius.circular(AppRadius.mlg),
            ),
            child: const Icon(
              Icons.note_alt_rounded,
              color: AppColors.diet,
              size: 21,
            ),
          ),
          title: Text(
            '补充说明',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
          ),
          subtitle: Text(
            _noteController.text.trim().isEmpty
                ? '可选，记录口味、情绪或特殊情况'
                : _noteController.text.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF6),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.diet.withValues(alpha: 0.14),
                ),
              ),
              child: TextField(
                controller: _noteController,
                textInputAction: TextInputAction.newline,
                maxLines: 3,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '记录其他信息...',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.note_outlined,
                    size: 18,
                    color: AppColors.diet.withValues(alpha: 0.72),
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

  // ---------------------------------------------------------------------------
  // 保存按钮
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
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
                  '$_mealLabel · $_healthScore 星 · $_healthText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '预计 +$_estimatedDietExp EXP',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.diet,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: '保存饮食记录',
            child: GestureDetector(
              onTap: _isSaving ? null : _save,
              child: AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                width: 132,
                height: 52,
                decoration: BoxDecoration(
                  color: _isSaving
                      ? AppColors.diet.withValues(alpha: 0.55)
                      : AppColors.diet,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: _isSaving
                      ? null
                      : AppShadows.colored(AppColors.diet),
                ),
                child: Center(
                  child: _isSaving
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
}
