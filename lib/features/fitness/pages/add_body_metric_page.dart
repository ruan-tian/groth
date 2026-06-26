import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/repository_providers.dart'
    show fitnessRepositoryProvider;
import '../../fitness/providers/fitness_provider.dart';
import '../models/fitness_data.dart';

const _metricAssetRoot = 'assets/images/fitness_record';
const _metricHeroAsset = '$_metricAssetRoot/fitness_record_top.webp';
const _metricFooterAsset = '$_metricAssetRoot/fitness_bottle.webp';
const _metricYogaAsset = '$_metricAssetRoot/fitness_yoga_mat.webp';

const _metric = Color(0xFF18A884);
const _metricDeep = Color(0xFF08735F);
const _metricDark = Color(0xFF10493F);
const _metricMist = Color(0xFFF2FBF7);
const _metricSoft = Color(0xFFE2F6EF);
const _metricLine = Color(0xFFCFE8DF);

/// 记录身体数据页面
class AddBodyMetricPage extends ConsumerStatefulWidget {
  const AddBodyMetricPage({super.key});

  @override
  ConsumerState<AddBodyMetricPage> createState() => _AddBodyMetricPageState();
}

class _AddBodyMetricPageState extends ConsumerState<AddBodyMetricPage>
    with SingleTickerProviderStateMixin {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _armController = TextEditingController();
  final _thighController = TextEditingController();
  final _noteController = TextEditingController();

  late final AnimationController _entranceController;
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
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _metricMist,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              _metricMist,
              _metricSoft.withValues(alpha: 0.64),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 720
                  ? 620.0
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
                        _MetricEntrance(
                          animation: _entranceController,
                          begin: 0,
                          child: _MetricHeader(
                            onBack: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                Navigator.of(context).maybePop();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _MetricEntrance(
                          animation: _entranceController,
                          begin: 0.08,
                          child: _MetricCard(
                            title: '基础数据',
                            subtitle: '体重和体脂率，填你今天有记录的项',
                            icon: Icons.monitor_weight_outlined,
                            children: [
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
                                  const SizedBox(width: AppSpacing.sm),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _MetricEntrance(
                          animation: _entranceController,
                          begin: 0.16,
                          child: _MetricCard(
                            title: '围度数据',
                            subtitle: '单位统一为 cm，可以按训练周期补充',
                            icon: Icons.straighten_rounded,
                            children: [
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
                                  const SizedBox(width: AppSpacing.sm),
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
                              const SizedBox(height: AppSpacing.sm),
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
                                  const SizedBox(width: AppSpacing.sm),
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
                              const SizedBox(height: AppSpacing.sm),
                              _MetricField(
                                controller: _thighController,
                                label: '大腿围',
                                unit: 'cm',
                                icon: Icons.straighten,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _MetricEntrance(
                          animation: _entranceController,
                          begin: 0.24,
                          child: _MetricCard(
                            title: '备注',
                            subtitle: '记录状态、饮食、训练后的身体反馈',
                            icon: Icons.note_alt_outlined,
                            children: [
                              _MetricNoteField(controller: _noteController),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _MetricSaveFooter(
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
      ),
    );
  }
}

class _MetricHeader extends StatelessWidget {
  const _MetricHeader({required this.onBack});

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
                color: _metricSoft.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(AppRadius.xxxl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Image.asset(
              _metricHeroAsset,
              width: 136,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            top: 6,
            child: _MetricCircleButton(
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
                  '记录身体数据',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 28,
                    color: _metricDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '体重、体脂、围度，都在温柔地说明变化',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _metricDeep.withValues(alpha: 0.72),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: _metricLine.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: _metricDeep.withValues(alpha: 0.06),
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
                  color: _metricSoft,
                  borderRadius: BorderRadius.circular(AppRadius.mlg),
                ),
                child: Icon(icon, color: _metricDeep, size: 21),
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
          ...children,
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
      ],
      style: AppTextStyles.body.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption.copyWith(color: colors.textHint),
        suffixText: unit,
        suffixStyle: AppTextStyles.caption.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon: Icon(icon, size: 18, color: _metricDeep),
        filled: true,
        fillColor: _metricMist.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: _metricLine.withValues(alpha: 0.78)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: _metricLine.withValues(alpha: 0.78)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: _metric, width: 1.3),
        ),
      ),
    );
  }
}

class _MetricNoteField extends StatelessWidget {
  const _MetricNoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.newline,
      maxLines: 4,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: '记录今天的感受、训练后的状态或身体反馈...',
        hintStyle: AppTextStyles.body.copyWith(color: colors.textHint),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: Icon(Icons.note_outlined, size: 18, color: _metricDeep),
        ),
        filled: true,
        fillColor: _metricMist.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: _metricLine.withValues(alpha: 0.78)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: _metricLine.withValues(alpha: 0.78)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: _metric, width: 1.3),
        ),
      ),
    );
  }
}

class _MetricSaveFooter extends StatelessWidget {
  const _MetricSaveFooter({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _metricSoft.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(_metricFooterAsset, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '变化不需要每天很大，只要持续被记录。',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: _metricDeep.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Opacity(
                  opacity: 0.68,
                  child: Image.asset(
                    _metricYogaAsset,
                    width: 42,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: isSaving ? null : onSave,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                scale: isSaving ? 0.98 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isSaving
                        ? null
                        : const LinearGradient(
                            colors: [_metric, _metricDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isSaving ? _metric.withValues(alpha: 0.54) : null,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: isSaving
                        ? null
                        : [
                            BoxShadow(
                              color: _metricDeep.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Center(
                    child: isSaving
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
                                '保存身体数据',
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
      ),
    );
  }
}

class _MetricEntrance extends StatelessWidget {
  const _MetricEntrance({
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
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _MetricCircleButton extends StatelessWidget {
  const _MetricCircleButton({required this.icon, required this.onTap});

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
            border: Border.all(color: _metricLine.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: _metricDeep.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _metricDark, size: 20),
        ),
      ),
    );
  }
}
