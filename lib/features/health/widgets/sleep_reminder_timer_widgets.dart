part of '../pages/sleep_reminder_timer_page.dart';

enum _SleepTimeField { sleep, wake }

class _SleepColors {
  static const background = Color(0xFFF8F1FB);
  static const primary = Color(0xFF8D73D8);
  static const primaryDark = Color(0xFF4B3D73);
  static const card = Color(0xFFFFFCFF);
  static const text = Color(0xFF4D4661);
  static const muted = Color(0xFF8F879D);
  static const line = Color(0xFFE9DFF2);
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onSettings,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _SleepColors.primaryDark,
            ),
          ),
        ),
        _RoundIconButton(icon: Icons.settings_outlined, onTap: onSettings),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.84),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: _SleepColors.primaryDark, size: 29),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.plan,
    required this.onEditSleep,
    required this.onEditWake,
  });

  final SleepPlanState plan;
  final VoidCallback onEditSleep;
  final VoidCallback onEditWake;

  @override
  Widget build(BuildContext context) {
    return _SleepCard(
      height: 252,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 350;
          final imageWidth = compact ? 138.0 : 182.0;
          final textRight = compact ? 118.0 : 164.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFCFF), Color(0xFFF5E9FB)],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 14,
                child: Image.asset(HealthTimerAssets.moon, width: 44),
              ),
              Positioned(
                right: compact ? 88 : 132,
                top: 38,
                child: Image.asset(HealthTimerAssets.starSleep, width: 28),
              ),
              Positioned(
                right: -4,
                bottom: 12,
                width: imageWidth,
                height: 196,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 3,
                      child: Image.asset(
                        HealthTimerAssets.sleepSoftShadow,
                        width: compact ? 118 : 150,
                      ),
                    ),
                    Image.asset(
                      HealthTimerAssets.sleepCatMain,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    Positioned(
                      right: compact ? 4 : 12,
                      bottom: 4,
                      child: Image.asset(
                        HealthTimerAssets.nightLamp,
                        width: compact ? 44 : 58,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                top: 22,
                right: textRight,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今晚目标',
                      style: TextStyle(
                        color: _SleepColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _TimeBlock(
                      time: plan.sleepTime,
                      suffix: '入睡',
                      caption: '预计睡眠 ${plan.targetDurationLabel}',
                      icon: Icons.nightlight_round,
                      onTap: onEditSleep,
                    ),
                    const Spacer(),
                    _TimeBlock(
                      time: plan.wakeTime,
                      suffix: '起床',
                      caption: '明早目标',
                      icon: Icons.wb_sunny_rounded,
                      onTap: onEditWake,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.time,
    required this.suffix,
    required this.caption,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String time;
  final String suffix;
  final String caption;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _SleepColors.primary, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SleepColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: time,
                      style: TextStyle(
                        color: _SleepColors.primaryDark,
                        fontSize: compact ? 30 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' $suffix',
                      style: TextStyle(
                        color: _SleepColors.primary,
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.plan,
    required this.onTap,
    required this.onToggle,
  });

  final SleepPlanState plan;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return _SleepCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
          child: Row(
            children: [
              _IconTile(icon: Icons.notifications_none_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '睡前提醒',
                      style: TextStyle(
                        color: _SleepColors.primaryDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '提前 ${plan.leadMinutes} 分钟提醒你准备睡觉',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SleepColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.reminderTime,
                    style: const TextStyle(
                      color: _SleepColors.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.reminderEnabled ? '已开启' : '已关闭',
                    style: TextStyle(
                      color: plan.reminderEnabled
                          ? _SleepColors.primary
                          : _SleepColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Switch(
                value: plan.reminderEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: _SleepColors.primary,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCheckInCard extends StatelessWidget {
  const _TodayCheckInCard({
    required this.plan,
    required this.onReady,
    required this.onWake,
  });

  final SleepPlanState plan;
  final VoidCallback onReady;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    return _SleepCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日打卡',
              style: TextStyle(
                color: _SleepColors.primaryDark,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '记录入睡和起床，自动生成睡眠记录',
              style: TextStyle(
                color: _SleepColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 300;
                final ready = _CheckInAction(
                  icon: Icons.bedtime_rounded,
                  title: '我准备睡了',
                  subtitle: plan.readyAt == null
                      ? '记录今晚开始'
                      : _timeStampLabel(plan.readyAt!),
                  checked: plan.readyAt != null,
                  onTap: onReady,
                );
                final wake = _CheckInAction(
                  icon: Icons.wb_sunny_rounded,
                  title: '我起床了',
                  subtitle: plan.wokeAt == null
                      ? '保存昨晚记录'
                      : _timeStampLabel(plan.wokeAt!),
                  checked: plan.wokeAt != null,
                  onTap: onWake,
                );
                if (stacked) {
                  return Column(
                    children: [ready, const SizedBox(height: 10), wake],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: ready),
                    const SizedBox(width: 10),
                    Expanded(child: wake),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInAction extends StatelessWidget {
  const _CheckInAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? const Color(0xFFF3ECFF) : const Color(0xFFFFF8FC),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 124,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: checked ? _SleepColors.primary : _SleepColors.line,
              width: checked ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(icon: icon, small: true),
                  const Spacer(),
                  if (checked)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _SleepColors.primary,
                      size: 24,
                    ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _SleepColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SleepColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepRecordCard extends StatelessWidget {
  const _SleepRecordCard({required this.record});

  final SleepRecord? record;

  @override
  Widget build(BuildContext context) {
    return _SleepCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  '睡眠记录',
                  style: TextStyle(
                    color: _SleepColors.primaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Spacer(),
                Icon(Icons.chevron_right_rounded, color: _SleepColors.muted),
              ],
            ),
            const SizedBox(height: 16),
            if (record == null)
              const _EmptyRecord()
            else
              _RecordContent(record: record!),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecord extends StatelessWidget {
  const _EmptyRecord();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _SleepColors.line),
      ),
      child: const Text(
        '还没有睡眠记录，今晚完成一次入睡和起床打卡后会自动生成。',
        style: TextStyle(
          color: _SleepColors.muted,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _RecordContent extends StatelessWidget {
  const _RecordContent({required this.record});

  final SleepRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _SleepColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatRecordDate(record.sleepDate),
                      style: const TextStyle(
                        color: _SleepColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatDuration(record.durationMinutes),
                        style: const TextStyle(
                          color: _SleepColors.primaryDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Stars(value: record.qualityLevel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.nightlight_round,
                  label: '入睡',
                  value: record.sleepTime,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.wb_sunny_rounded,
                  label: '起床',
                  value: record.wakeTime,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.bolt_rounded,
                  label: '精力',
                  value: '${record.energyLevel}/5',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitStatsCard extends StatelessWidget {
  const _HabitStatsCard({required this.plan});

  final SleepPlanState plan;

  @override
  Widget build(BuildContext context) {
    return _SleepCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '睡眠习惯',
              style: TextStyle(
                color: _SleepColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: '连续早睡',
                    value: '${plan.consecutiveEarlySleepDays}',
                    unit: '天',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: '平均睡眠',
                    value: plan.averageSleepMinutes == null
                        ? '--'
                        : _formatShortDuration(plan.averageSleepMinutes!),
                    unit: '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: '早起达标',
                    value: '${plan.earlyWakeDays}',
                    unit: '天',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _SleepColors.line),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _SleepColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: _SleepColors.primaryDark,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: unit,
                      style: const TextStyle(
                        color: _SleepColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionBubble extends StatelessWidget {
  const _CompanionBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Image.asset(
                  HealthTimerAssets.sleepSoftShadow,
                  width: 48,
                ),
              ),
              Image.asset(
                HealthTimerAssets.sleepAvatar,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _SleepColors.line),
              boxShadow: [
                BoxShadow(
                  color: _SleepColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _SleepColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.small = false});

  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EAFB),
        borderRadius: BorderRadius.circular(small ? 14 : 16),
      ),
      child: Icon(icon, color: _SleepColors.primary, size: small ? 22 : 25),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: _SleepColors.primary),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: _SleepColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: _SleepColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < value ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 19,
          color: index < value ? const Color(0xFFF7B957) : _SleepColors.line,
        );
      }),
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: _SleepColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _SleepColors.line),
        boxShadow: [
          BoxShadow(
            color: _SleepColors.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LeadMinutesSheet extends StatefulWidget {
  const _LeadMinutesSheet({required this.currentValue});

  final int currentValue;

  @override
  State<_LeadMinutesSheet> createState() => _LeadMinutesSheetState();
}

class _LeadMinutesSheetState extends State<_LeadMinutesSheet> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: '提前提醒',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '建议提前 20-40 分钟，让自己有时间洗漱、关灯、放下手机。',
            style: TextStyle(
              color: _SleepColors.muted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              '$_value 分钟',
              style: const TextStyle(
                color: _SleepColors.primaryDark,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Slider(
            value: _value.toDouble(),
            min: 0,
            max: 180,
            divisions: 18,
            activeColor: _SleepColors.primary,
            onChanged: (value) => setState(() => _value = value.round()),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _value),
              style: ElevatedButton.styleFrom(
                backgroundColor: _SleepColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                '保存',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _SleepColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: _SleepColors.primaryDark,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _SleepColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _SleepColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _SleepColors.muted),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SheetSwitchAction extends StatelessWidget {
  const _SheetSwitchAction({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: _SleepColors.primary,
      onChanged: onChanged,
    );
  }
}

TimeOfDay _parseTimeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 22,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 30,
  );
}

String _formatTimeOfDay(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _timeStampLabel(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')} 已打卡';
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours <= 0) return '$rest 分钟';
  if (rest == 0) return '$hours 小时';
  return '$hours 小时 $rest 分钟';
}

String _formatShortDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours <= 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h${rest}m';
}

String _formatRecordDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.month}月${date.day}日 夜间';
}
