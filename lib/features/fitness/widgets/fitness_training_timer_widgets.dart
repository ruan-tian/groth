part of '../pages/fitness_training_timer_page.dart';

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.elapsed,
    required this.onBack,
    required this.onTemplates,
    required this.onEdit,
  });

  final String elapsed;
  final VoidCallback onBack;
  final VoidCallback onTemplates;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '训练会话',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            elapsed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.fitness,
            ),
          ),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.list_alt_rounded, onTap: onTemplates),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.tune_rounded,
            onTap: onEdit ?? () {},
            enabled: onEdit != null,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: colors.paper.withValues(alpha: enabled ? 0.92 : 0.48),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: enabled ? colors.fitness : colors.textHint),
        ),
      ),
    );
  }
}

class _TemplateStrip extends StatelessWidget {
  const _TemplateStrip({
    required this.templates,
    required this.selectedTemplateId,
    required this.onSelect,
  });

  final List<FitnessWorkoutTemplate> templates;
  final int? selectedTemplateId;
  final ValueChanged<FitnessWorkoutTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final template = templates[index];
          final selected = template.id == selectedTemplateId;
          return Semantics(
            button: true,
            label: '选择${template.name}模板',
            selected: selected,
            child: GestureDetector(
              onTap: () => onSelect(template),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? colors.fitness : colors.paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? colors.fitness
                        : colors.fitness.withValues(alpha: 0.18),
                  ),
                ),
                child: Center(
                  child: Text(
                    template.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? colors.textOnAccent
                          : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CurrentExerciseCard extends StatelessWidget {
  const _CurrentExerciseCard({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final exercise = session.currentExercise;
    final isRest = session.phase == WorkoutSessionPhase.rest;
    final image = isRest
        ? FitnessTimerAssets.catFitnessRest
        : exercise?.name.contains('平板') == true
        ? FitnessTimerAssets.catFitnessPlank
        : FitnessTimerAssets.catFitnessDumbbellMain;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRest ? '组间休息' : '当前动作',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isRest ? '调整呼吸，准备下一组' : exercise?.name ?? '选择训练模板',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(
                    height: 1.2,
                    color: colors.textPrimary,
                  ),
                ),
                if (exercise != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '第 ${session.currentSet}/${exercise.targetSets} 组 · ${exercise.targetText}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.fitness,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: colors.fitness.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(image, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final exercise = session.currentExercise;
    final isRest = session.phase == WorkoutSessionPhase.rest;
    final isTimed = exercise?.type == WorkoutExerciseType.timed;
    final target = exercise?.targetSeconds ?? 0;
    final shown = isRest
        ? Duration(seconds: session.restRemainingSeconds)
        : isTimed
        ? Duration(
            seconds: (target - session.currentSetElapsedSeconds).clamp(0, 9999),
          )
        : Duration(seconds: session.currentSetElapsedSeconds);
    final progress = isRest
        ? _safeProgress(
            session.restRemainingSeconds,
            exercise?.restSeconds ?? 1,
            reverse: true,
          )
        : isTimed
        ? _safeProgress(session.currentSetElapsedSeconds, target)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Center(
        child: SizedBox(
          width: 236,
          height: 236,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress == 0 ? null : progress,
                  strokeWidth: 16,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.fitness.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(
                    isRest ? colors.textSecondary : colors.fitness,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(shown),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.isPaused
                        ? '已暂停'
                        : isRest
                        ? '休息中'
                        : isTimed
                        ? '本组剩余'
                        : '本组用时',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.fitness,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _safeProgress(int value, int total, {bool reverse = false}) {
    if (total <= 0) return 0;
    final progress = (value / total).clamp(0.0, 1.0);
    return reverse ? progress : progress;
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.local_fire_department_rounded,
              value: '${session.estimatedCalories}',
              unit: 'kcal',
            ),
          ),
          Container(width: 1, height: 32, color: colors.border),
          Expanded(
            child: _StatCell(
              icon: Icons.repeat_rounded,
              value: '${session.completedSets}/${session.totalTargetSets}',
              unit: '组',
            ),
          ),
          Container(width: 1, height: 32, color: colors.border),
          Expanded(
            child: _StatCell(
              icon: Icons.fitness_center_rounded,
              value: '${session.totalVolume}',
              unit: 'kg',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.fitness, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.cardTitle.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _NextExerciseCard extends StatelessWidget {
  const _NextExerciseCard({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final next = session.nextExercise;
    final image = next?.name.contains('平板') == true
        ? FitnessTimerAssets.catFitnessPlank
        : FitnessTimerAssets.catFitnessDumbbellMain;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colors.fitness.withValues(alpha: 0.08),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: next != null
                  ? Image.asset(image, fit: BoxFit.cover)
                  : Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.fitness,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '下一项',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next?.name ?? '训练即将完成',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    next.targetText,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CompanionBubble extends StatelessWidget {
  const _CompanionBubble({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final text = switch (session.phase) {
      WorkoutSessionPhase.rest => '甜甜：喝口水，下一组会更稳。',
      WorkoutSessionPhase.setup => '甜甜：先选好训练计划，我们再开始。',
      _ => '甜甜：动作做稳，比做快更重要。',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.fitness.withValues(alpha: 0.08),
          ),
          child: ClipOval(
            child: Image.asset(
              FitnessTimerAssets.catAvatarFitness,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.paper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.fitness.withValues(alpha: 0.14)),
            ),
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.session, required this.controller});

  final WorkoutSessionState session;
  final WorkoutSessionController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final isSetup = session.phase == WorkoutSessionPhase.setup;
    final isRest = session.phase == WorkoutSessionPhase.rest;
    final actionLabel = isSetup
        ? '开始训练'
        : isRest
        ? '跳过休息'
        : '完成本组';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          _RoundAction(
            icon: Icons.flag_rounded,
            label: '结束',
            onTap: session.canSave ? controller.finish : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Semantics(
              button: true,
              label: actionLabel,
              child: GestureDetector(
                onTap: isSetup
                    ? controller.start
                    : isRest
                    ? controller.skipRest
                    : controller.completeCurrentSet,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(colors.fitness, colors.warning, 0.34)!,
                        colors.fitness,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: colors.fitness.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textOnAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _RoundAction(
            icon: session.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            label: session.isPaused ? '继续' : '暂停',
            onTap: isSetup ? null : controller.togglePause,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? colors.paper : colors.surfaceVariant,
                border: Border.all(
                  color: colors.fitness.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                icon,
                color: enabled ? colors.fitness : colors.textTertiary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: enabled ? colors.textPrimary : colors.textTertiary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.session,
    required this.onContinue,
    required this.onSave,
  });

  final WorkoutSessionState session;
  final VoidCallback onContinue;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '训练总结',
            style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            '${session.templateName} · ${session.completedSets}/${session.totalTargetSets} 组 · ${_formatDuration(Duration(seconds: session.totalElapsedSeconds))}',
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 18),
          ...session.completed.values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.plan.name,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${item.completedSets} 组',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinue,
                  child: const Text('继续训练'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.fitness,
                    foregroundColor: colors.textOnAccent,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('保存记录'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
