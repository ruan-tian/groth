import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/repository_providers.dart' show sleepRepositoryProvider;
import '../../../shared/providers/sleep_provider.dart';
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_bus.dart';

/// 添加睡眠记录页面
class AddSleepRecordPage extends ConsumerStatefulWidget {
  const AddSleepRecordPage({super.key});

  @override
  ConsumerState<AddSleepRecordPage> createState() =>
      _AddSleepRecordPageState();
}

class _AddSleepRecordPageState extends ConsumerState<AddSleepRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _dreamController = TextEditingController();
  final _noteController = TextEditingController();

  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _qualityLevel = 3;
  int _fallAsleepMinutes = 15;
  int _wakeCount = 0;
  int _energyLevel = 3;
  bool _isSaving = false;

  @override
  void dispose() {
    _dreamController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _calculateDuration() {
    final sleepMinutes = _sleepTime.hour * 60 + _sleepTime.minute;
    final wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;

    int duration;
    if (wakeMinutes >= sleepMinutes) {
      duration = wakeMinutes - sleepMinutes;
    } else {
      duration = (24 * 60 - sleepMinutes) + wakeMinutes;
    }
    return duration;
  }

  Future<void> _pickTime(bool isBed, bool isSleep) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isBed
          ? _bedTime
          : isSleep
              ? _sleepTime
              : _wakeTime,
    );

    if (picked != null) {
      setState(() {
        if (isBed) {
          _bedTime = picked;
        } else if (isSleep) {
          _sleepTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final duration = _calculateDuration();

      final companion = SleepRecordsCompanion(
        sleepDate: Value(dateStr),
        bedTime: Value(_formatTime(_bedTime)),
        sleepTime: Value(_formatTime(_sleepTime)),
        wakeTime: Value(_formatTime(_wakeTime)),
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
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

      final repo = ref.read(sleepRepositoryProvider);
      await repo.insertSleepRecord(companion);

      if (mounted) {
        ref.invalidate(lastNightSleepRecordProvider);
        ref.invalidate(weeklyAvgSleepDurationProvider);
        ref.invalidate(weeklyAvgSleepQualityProvider);
        ref.invalidate(recentSleepRecordsProvider);

        // 发送宠物事件
        final eventId = 'sleep_${DateTime.now().millisecondsSinceEpoch}';
        PetEventBus.instance.emit(PetEvent.moduleCompleted(
          eventId: eventId,
          type: PetEventType.sleepCompleted,
          module: 'sleep',
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('睡眠记录已保存')),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = _calculateDuration();
    final hours = duration ~/ 60;
    final minutes = duration % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录睡眠'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          children: [
            // 睡眠时长预览
            Card(
              color: GrowthColors.sleepLight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  children: [
                    Icon(Icons.bedtime,
                        color: GrowthColors.sleepPrimary, size: 48),
                    const SizedBox(height: AppTheme.spaceSm),
                    Text(
                      '${hours}h ${minutes}m',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: GrowthColors.sleepPrimary,
                      ),
                    ),
                    const Text('预计睡眠时长'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 时间选择
            Text('时间', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            _TimePickerRow(
              label: '上床',
              time: _formatTime(_bedTime),
              onTap: () => _pickTime(true, false),
            ),
            _TimePickerRow(
              label: '入睡',
              time: _formatTime(_sleepTime),
              onTap: () => _pickTime(false, true),
            ),
            _TimePickerRow(
              label: '起床',
              time: _formatTime(_wakeTime),
              onTap: () => _pickTime(false, false),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 睡眠质量
            Text('睡眠质量', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _qualityLevel ? Icons.star : Icons.star_border,
                    size: 36,
                    color: GrowthColors.expFill,
                  ),
                  onPressed: () =>
                      setState(() => _qualityLevel = index + 1),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 入睡耗时
            Text('入睡耗时（分钟）', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            Slider(
              value: _fallAsleepMinutes.toDouble(),
              min: 0,
              max: 60,
              divisions: 12,
              label: '$_fallAsleepMinutes 分钟',
              onChanged: (v) =>
                  setState(() => _fallAsleepMinutes = v.toInt()),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 夜醒次数
            Text('夜醒次数', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _wakeCount > 0
                      ? () => setState(() => _wakeCount--)
                      : null,
                ),
                Text(
                  '$_wakeCount 次',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _wakeCount < 10
                      ? () => setState(() => _wakeCount++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 醒后精力
            Text('醒后精力', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _energyLevel
                        ? Icons.battery_full
                        : Icons.battery_1_bar,
                    size: 32,
                    color: GrowthColors.expFill,
                  ),
                  onPressed: () =>
                      setState(() => _energyLevel = index + 1),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 梦境备注
            Text('梦境', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            TextFormField(
              controller: _dreamController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '记录梦境内容（选填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),

            // 备注
            Text('备注', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSm),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '其他信息（选填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),

            // 保存按钮
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.access_time),
        label: Text(
          time,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
