import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart' show dashboardProvider;
import '../../../shared/providers/diet_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/repository_providers.dart' show dietRepositoryProvider;
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_bus.dart';

/// 添加饮食记录页面（牛油果绿风格）
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
  void dispose() {
    _foodController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_foodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入食物描述')),
      );
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

      final repo = ref.read(dietRepositoryProvider);
      await repo.insertDietRecord(companion);

      ref.invalidate(todayDietRecordsProvider);
      ref.invalidate(todayDietCountProvider);
      ref.invalidate(todayAvgHealthScoreProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        // 发送宠物事件
        final eventId = 'diet_${DateTime.now().millisecondsSinceEpoch}';
        PetEventBus.instance.emit(PetEvent.moduleCompleted(
          eventId: eventId,
          type: PetEventType.dietCompleted,
          module: 'diet',
        ));

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: AppBar(
        title: const Text(
          '记录饮食',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5016),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF2D5016),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 餐次选择 ──
            _buildSectionTitle('餐次'),
            const SizedBox(height: 8),
            _buildMealTypeSelector(),
            const SizedBox(height: 20),

            // ── 食物描述 ──
            _buildSectionTitle('吃了什么'),
            const SizedBox(height: 8),
            _buildFoodField(),
            const SizedBox(height: 20),

            // ── 份量 ──
            _buildSectionTitle('份量'),
            const SizedBox(height: 8),
            _buildPortionSelector(),
            const SizedBox(height: 20),

            // ── 热量等级 ──
            _buildSectionTitle('热量'),
            const SizedBox(height: 8),
            _buildCalorieSelector(),
            const SizedBox(height: 20),

            // ── 蛋白质等级 ──
            _buildSectionTitle('蛋白质'),
            const SizedBox(height: 8),
            _buildProteinSelector(),
            const SizedBox(height: 20),

            // ── 健康评分 ──
            _buildSectionTitle('健康评分'),
            const SizedBox(height: 8),
            _buildHealthScoreSelector(),
            const SizedBox(height: 20),

            // ── 备注 ──
            _buildSectionTitle('备注（可选）'),
            const SizedBox(height: 8),
            _buildNoteField(),
            const SizedBox(height: 32),

            // ── 保存按钮 ──
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF556B2F),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 餐次选择
  // ---------------------------------------------------------------------------

  Widget _buildMealTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: _buildMealTypeChip('breakfast', '早餐', Icons.free_breakfast_rounded)),
          Expanded(child: _buildMealTypeChip('lunch', '午餐', Icons.lunch_dining_rounded)),
          Expanded(child: _buildMealTypeChip('dinner', '晚餐', Icons.dinner_dining_rounded)),
          Expanded(child: _buildMealTypeChip('snack', '加餐', Icons.cookie_rounded)),
        ],
      ),
    );
  }

  Widget _buildMealTypeChip(String value, String label, IconData icon) {
    final isSelected = _mealType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _mealType = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B8E23) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B8B83),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF8B8B83),
              ),
            ),
          ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _foodController,
        decoration: InputDecoration(
          hintText: '例如：鸡胸肉 + 米饭 + 青菜',
          hintStyle: const TextStyle(color: Color(0xFFB0B0A8)),
          prefixIcon: const Icon(
            Icons.restaurant_rounded,
            size: 18,
            color: Color(0xFF6B8E23),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 份量选择
  // ---------------------------------------------------------------------------

  Widget _buildPortionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: _buildPortionChip('small', '少量')),
          Expanded(child: _buildPortionChip('normal', '正常')),
          Expanded(child: _buildPortionChip('large', '大量')),
        ],
      ),
    );
  }

  Widget _buildPortionChip(String value, String label) {
    final isSelected = _portionLevel == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _portionLevel = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B8E23) : const Color(0xFFF8FFF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B8E23)
                : const Color(0xFF6B8E23).withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFF556B2F),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 热量选择
  // ---------------------------------------------------------------------------

  Widget _buildCalorieSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: _buildCalorieChip('low', '低', const Color(0xFF6B8E23))),
          Expanded(child: _buildCalorieChip('normal', '中', const Color(0xFFFF8C00))),
          Expanded(child: _buildCalorieChip('high', '高', const Color(0xFFFF6B6B))),
        ],
      ),
    );
  }

  Widget _buildCalorieChip(String value, String label, Color color) {
    final isSelected = _calorieLevel == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _calorieLevel = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 蛋白质选择
  // ---------------------------------------------------------------------------

  Widget _buildProteinSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: _buildProteinChip('low', '低')),
          Expanded(child: _buildProteinChip('medium', '中')),
          Expanded(child: _buildProteinChip('high', '高')),
        ],
      ),
    );
  }

  Widget _buildProteinChip(String value, String label) {
    final isSelected = _proteinLevel == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _proteinLevel = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDAA520) : const Color(0xFFDAA520).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDAA520)
                : const Color(0xFFDAA520).withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : const Color(0xFFDAA520),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 健康评分
  // ---------------------------------------------------------------------------

  Widget _buildHealthScoreSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isSelected = index < _healthScore;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _healthScore = index + 1);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                size: 36,
                color: isSelected ? const Color(0xFFDAA520) : const Color(0xFFD0D0C8),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 备注
  // ---------------------------------------------------------------------------

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B8E23).withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: '记录其他信息...',
          hintStyle: const TextStyle(color: Color(0xFFB0B0A8)),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: Icon(
              Icons.note_outlined,
              size: 18,
              color: Color(0xFF6B8E23),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 保存按钮
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isSaving
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF6B8E23), Color(0xFF8FBC8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isSaving ? const Color(0xFF8FBC8F) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isSaving
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6B8E23).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '保存饮食记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
