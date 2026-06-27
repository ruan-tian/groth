import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../../shared/providers/repository_providers.dart'
    show fitnessRepositoryProvider;

/// 身体数据记录表单
///
/// 记录体重、体脂率、围度等身体数据。
/// 使用 TextFormField + 数字键盘输入，保存后插入数据库。
class BodyMetricForm extends ConsumerStatefulWidget {
  /// 保存成功回调
  final VoidCallback? onSaved;

  const BodyMetricForm({super.key, this.onSaved});

  @override
  ConsumerState<BodyMetricForm> createState() => _BodyMetricFormState();
}

class _BodyMetricFormState extends ConsumerState<BodyMetricForm> {
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _armController = TextEditingController();
  final _thighController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSaving = false;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('身体数据已保存')));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 体重 & 体脂率
            Text(
              '基本数据',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricField(
                    controller: _weightController,
                    label: '体重',
                    unit: 'kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricField(
                    controller: _bodyFatController,
                    label: '体脂率',
                    unit: '%',
                    icon: Icons.water_drop_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 围度数据
            Text(
              '围度数据',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricField(
                    controller: _chestController,
                    label: '胸围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricField(
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
                  child: _MetricField(
                    controller: _hipController,
                    label: '臀围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricField(
                    controller: _armController,
                    label: '臂围',
                    unit: 'cm',
                    icon: Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricField(
              controller: _thighController,
              label: '大腿围',
              unit: 'cm',
              icon: Icons.straighten,
            ),

            const SizedBox(height: 20),

            // 备注
            Text(
              '备注',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              textInputAction: TextInputAction.newline,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '记录今天的感受...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 保存按钮
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.growthColors.textOnAccent,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '保存'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个围度/数据输入框
class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;

  const _MetricField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}
