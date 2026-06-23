import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../models/health_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../health/providers/sleep_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';

/// 添加睡眠记录弹窗
class AddSleepRecordSheet extends ConsumerStatefulWidget {
  const AddSleepRecordSheet({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  ConsumerState<AddSleepRecordSheet> createState() =>
      _AddSleepRecordSheetState();
}

class _AddSleepRecordSheetState extends ConsumerState<AddSleepRecordSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _qualityLevel = 3;
  int _fallAsleepMinutes = 15;
  int _wakeCount = 0;
  int _energyLevel = 3;
  bool _isSaving = false;
  final _dreamController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isValid => true;

  Duration get _calculatedDuration {
    final sleepMinutes = _bedTime.hour * 60 + _bedTime.minute;
    final wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    int duration;
    if (wakeMinutes >= sleepMinutes) {
      duration = wakeMinutes - sleepMinutes; // 同一天（午睡）
    } else {
      duration = (24 * 60 - sleepMinutes) + wakeMinutes; // 跨天（夜间）
    }
    return Duration(minutes: duration);
  }

  @override
  void dispose() {
    _dreamController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 顶部拖拽条 ──
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: colors.textHint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),

          // ── 标题 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '添加睡眠记录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: '关闭弹窗',
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 内容区域（可滚动）──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 日期选择 ──
                  _buildDateField(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 时间选择 ──
                  _buildTimeField(
                    '上床时间',
                    _bedTime,
                    (t) => setState(() => _bedTime = t),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTimeField(
                    '入睡时间',
                    _sleepTime,
                    (t) => setState(() => _sleepTime = t),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTimeField(
                    '起床时间',
                    _wakeTime,
                    (t) => setState(() => _wakeTime = t),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 自动计算时长 ──
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.softPurple,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calculate, color: colors.sleep),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '自动计算睡眠时长: ${_formatDuration(_calculatedDuration.inMinutes)}',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.sleep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 睡眠质量 ──
                  Text('睡眠质量', style: AppTextStyles.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _QualityChip(
                        label: '很差',
                        selected: _qualityLevel == 1,
                        onTap: () => setState(() => _qualityLevel = 1),
                      ),
                      _QualityChip(
                        label: '较差',
                        selected: _qualityLevel == 2,
                        onTap: () => setState(() => _qualityLevel = 2),
                      ),
                      _QualityChip(
                        label: '一般',
                        selected: _qualityLevel == 3,
                        onTap: () => setState(() => _qualityLevel = 3),
                      ),
                      _QualityChip(
                        label: '良好',
                        selected: _qualityLevel == 4,
                        onTap: () => setState(() => _qualityLevel = 4),
                      ),
                      _QualityChip(
                        label: '优秀',
                        selected: _qualityLevel == 5,
                        onTap: () => setState(() => _qualityLevel = 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 入睡耗时 ──
                  Text(
                    '入睡耗时: $_fallAsleepMinutes 分钟',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Slider(
                    value: _fallAsleepMinutes.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: 24,
                    label: '$_fallAsleepMinutes 分钟',
                    activeColor: colors.sleep,
                    onChanged: (v) =>
                        setState(() => _fallAsleepMinutes = v.toInt()),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 夜醒次数 ──
                  Text('夜醒次数', style: AppTextStyles.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _wakeCount > 0
                            ? () => setState(() => _wakeCount--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: colors.sleep,
                      ),
                      Text('$_wakeCount 次', style: AppTextStyles.numberMedium),
                      IconButton(
                        onPressed: () => setState(() => _wakeCount++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: colors.sleep,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 醒后精力 ──
                  Text('醒后精力', style: AppTextStyles.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _QualityChip(
                        label: '很累',
                        selected: _energyLevel == 1,
                        onTap: () => setState(() => _energyLevel = 1),
                      ),
                      _QualityChip(
                        label: '一般',
                        selected: _energyLevel == 2,
                        onTap: () => setState(() => _energyLevel = 2),
                      ),
                      _QualityChip(
                        label: '良好',
                        selected: _energyLevel == 3,
                        onTap: () => setState(() => _energyLevel = 3),
                      ),
                      _QualityChip(
                        label: '优秀',
                        selected: _energyLevel == 4,
                        onTap: () => setState(() => _energyLevel = 4),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 备注 ──
                  Text('备注', style: AppTextStyles.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    textInputAction: TextInputAction.newline,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '记录一下睡眠情况或梦境...',
                      filled: true,
                      fillColor: colors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── 保存按钮 ──
                  PrimaryButton(
                    text: '保存记录',
                    icon: Icons.check,
                    onTap: _isValid && !_isSaving ? _save : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: '选择日期',
      child: GestureDetector(
        onTap: () async {
          final picked = await showGrowthDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: colors.sleep),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                style: AppTextStyles.cardTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: '选择$label',
      child: GestureDetector(
        onTap: () async {
          final picked = await showGrowthTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: colors.sleep),
              const SizedBox(width: AppSpacing.md),
              Text(label, style: AppTextStyles.caption),
              const Spacer(),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.cardTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours小时$mins分';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(sleepRepositoryProvider);
      final now = DateTime.now();
      final duration = _calculatedDuration.inMinutes;

      await repo.insertSleepRecord(
        SleepRecordsCompanion(
          sleepDate: Value(
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          ),
          bedTime: Value(
            '${_bedTime.hour.toString().padLeft(2, '0')}:${_bedTime.minute.toString().padLeft(2, '0')}',
          ),
          sleepTime: Value(
            '${_sleepTime.hour.toString().padLeft(2, '0')}:${_sleepTime.minute.toString().padLeft(2, '0')}',
          ),
          wakeTime: Value(
            '${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}',
          ),
          durationMinutes: Value(duration),
          qualityLevel: Value(_qualityLevel),
          fallAsleepMinutes: Value(_fallAsleepMinutes),
          wakeCount: Value(_wakeCount),
          energyLevel: Value(_energyLevel),
          dreamNote: Value(
            _dreamController.text.trim().isEmpty
                ? null
                : _dreamController.text.trim(),
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

      ref.invalidate(sleepRecordByDateProvider(_selectedDate));
      ref.invalidate(lastNightSleepRecordProvider);
      ref.invalidate(dashboardProvider);

      widget.onSave();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('睡眠记录已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.sleep.withValues(alpha: 0.1) : colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: selected ? colors.sleep : colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? colors.sleep : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
