import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../../shared/providers/repository_providers.dart'
    show fitnessRepositoryProvider;

/// 记录身体数据页面（褐色渐变风格）
class AddBodyMetricPage extends ConsumerStatefulWidget {
  const AddBodyMetricPage({super.key});

  @override
  ConsumerState<AddBodyMetricPage> createState() => _AddBodyMetricPageState();
}

class _AddBodyMetricPageState extends ConsumerState<AddBodyMetricPage> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _armController = TextEditingController();
  final _thighController = TextEditingController();
  final _noteController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _armController.dispose();
    _thighController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }

  Future<void> _save() async {
    // 至少要填写一项数据
    if (_weightController.text.trim().isEmpty &&
        _bodyFatController.text.trim().isEmpty &&
        _chestController.text.trim().isEmpty &&
        _waistController.text.trim().isEmpty &&
        _hipController.text.trim().isEmpty &&
        _armController.text.trim().isEmpty &&
        _thighController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少填写一项数据')));
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final companion = BodyMetricsCompanion(
        recordDate: Value(dateStr),
        weight: Value(_parseDouble(_weightController.text)),
        bodyFat: Value(_parseDouble(_bodyFatController.text)),
        chest: Value(_parseDouble(_chestController.text)),
        waist: Value(_parseDouble(_waistController.text)),
        hip: Value(_parseDouble(_hipController.text)),
        arm: Value(_parseDouble(_armController.text)),
        thigh: Value(_parseDouble(_thighController.text)),
        note: Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        createdAt: Value(now.millisecondsSinceEpoch),
      );

      await ref.read(fitnessRepositoryProvider).insertBodyMetric(companion);

      // 刷新数据
      ref.invalidate(allBodyMetricsProvider);
      ref.invalidate(recentBodyMetricsProvider);
      ref.invalidate(latestBodyMetricProvider);
      ref.invalidate(bodyMetricsTrendProvider);
      ref.invalidate(fitnessChartDataProvider(7));
      ref.invalidate(fitnessChartDataProvider(30));
      ref.invalidate(fitnessChartDataProvider(365));

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('身体数据已保存'),
            backgroundColor: context.growthColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.growthColors.background,
      appBar: AppBar(
        title: Text(
          '记录身体数据',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.growthColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: context.growthColors.textPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 基本数据 ──
            _buildSectionTitle('基本数据'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricField(
                    controller: _weightController,
                    label: '体重',
                    unit: 'kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricField(
                    controller: _bodyFatController,
                    label: '体脂率',
                    unit: '%',
                    icon: Icons.water_drop_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 围度数据 ──
            _buildSectionTitle('围度数据（cm）'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricField(
                    controller: _chestController,
                    label: '胸围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricField(
                    controller: _waistController,
                    label: '腰围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricField(
                    controller: _hipController,
                    label: '臀围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricField(
                    controller: _armController,
                    label: '臂围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricField(
              controller: _thighController,
              label: '大腿围',
              unit: 'cm',
              icon: Icons.straighten,
            ),
            const SizedBox(height: 24),

            // ── 备注 ──
            _buildSectionTitle('备注（可选）'),
            const SizedBox(height: 12),
            _buildNoteField(),
            const SizedBox(height: 32),

            // ── 保存按钮 ──
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: context.growthColors.textSecondary,
      ),
    );
  }

  Widget _buildMetricField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.growthColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: context.growthColors.textHint,
          ),
          suffixText: unit,
          suffixStyle: TextStyle(
            fontSize: 12,
            color: context.growthColors.textHint,
          ),
          prefixIcon: Icon(icon, size: 18, color: context.growthColors.accent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.growthColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: _noteController,
        textInputAction: TextInputAction.newline,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: '记录今天的感受...',
          hintStyle: TextStyle(color: context.growthColors.textHint),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Icon(
              Icons.note_outlined,
              size: 18,
              color: context.growthColors.accent,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _saving
              ? null
              : LinearGradient(
                  colors: [
                    context.growthColors.accent,
                    context.growthColors.border,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _saving ? context.growthColors.border : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _saving
              ? null
              : [
                  BoxShadow(
                    color: context.growthColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: _saving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.growthColors.textOnAccent,
                  ),
                )
              : Text(
                  '保存身体数据',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.growthColors.textOnAccent,
                  ),
                ),
        ),
      ),
    );
  }
}
