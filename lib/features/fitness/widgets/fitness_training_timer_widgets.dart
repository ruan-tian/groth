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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '训练会话',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle,
            ),
          ),
          Text(
            elapsed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.fitness,
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
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF6B3E22) : const Color(0xFFB8A091),
          ),
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
                color: selected ? AppColors.fitness : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.fitness
                      : AppColors.fitness.withValues(alpha: 0.16),
                ),
              ),
              child: Center(
                child: Text(
                  template.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
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
    final exercise = session.currentExercise;
    final isRest = session.phase == WorkoutSessionPhase.rest;
    final image = isRest
        ? FitnessTimerAssets.catFitnessRest
        : exercise?.name.contains('平板') == true
        ? FitnessTimerAssets.catFitnessPlank
        : FitnessTimerAssets.catFitnessDumbbellMain;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
      decoration: _cardDecoration(),
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
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isRest ? '调整呼吸，准备下一组' : exercise?.name ?? '选择训练模板',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.numberMedium.copyWith(height: 1.08),
                ),
                const SizedBox(height: 10),
                if (exercise != null)
                  Text(
                    '第 ${session.currentSet} / ${exercise.targetSets} 组 · ${exercise.targetText}',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.fitness,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Image.asset(
                  FitnessTimerAssets.softShadowOval,
                  width: 112,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                Image.asset(
                  image,
                  width: 136,
                  height: 136,
                  fit: BoxFit.contain,
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            width: 236,
            height: 236,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 218,
                  height: 218,
                  child: CircularProgressIndicator(
                    value: progress == 0 ? null : progress,
                    strokeWidth: 16,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.fitness.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      isRest ? AppColors.textSecondary : AppColors.fitness,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(shown),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.isPaused
                          ? '已暂停'
                          : isRest
                          ? '休息中'
                          : isTimed
                          ? '本组剩余'
                          : '本组用时',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.fitness,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _safeProgress(int value, int total, {bool reverse = false}) {
    if (total <= 0) return 0;
    final progress = (value / total).clamp(0.0, 1.0);
    return reverse ? progress : progress;
  }
}

class _NextExerciseCard extends StatelessWidget {
  const _NextExerciseCard({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final next = session.nextExercise;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.fitness.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              next?.name.contains('平板') == true
                  ? FitnessTimerAssets.catFitnessPlank
                  : FitnessTimerAssets.itemDumbbell,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('下一项', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(next?.name ?? '训练即将完成', style: AppTextStyles.sectionTitle),
                if (next != null)
                  Text(
                    next.targetText,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9B6B4A)),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _StatCell(
            icon: Icons.local_fire_department_rounded,
            label: '消耗',
            value: '${session.estimatedCalories} kcal',
          ),
          _StatCell(
            icon: Icons.repeat_rounded,
            label: '组数',
            value: '${session.completedSets}/${session.totalTargetSets}',
          ),
          _StatCell(
            icon: Icons.fitness_center_rounded,
            label: '训练量',
            value: '${session.totalVolume} kg',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.fitness, size: 22),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.cardTitle),
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
    final text = switch (session.phase) {
      WorkoutSessionPhase.rest => '甜甜：喝口水，下一组会更稳。',
      WorkoutSessionPhase.setup => '甜甜：先选好训练计划，我们再开始。',
      _ => '甜甜：动作做稳，比做快更重要。',
    };
    return Row(
      children: [
        Image.asset(
          FitnessTimerAssets.catAvatarFitness,
          width: 52,
          height: 52,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.fitness.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
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
    final isSetup = session.phase == WorkoutSessionPhase.setup;
    final isRest = session.phase == WorkoutSessionPhase.rest;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.fitness.withValues(alpha: 0.12),
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
              label: isSetup
                  ? '开始训练'
                  : isRest
                  ? '跳过休息'
                  : '完成本组',
              child: GestureDetector(
              onTap: isSetup
                  ? controller.start
                  : isRest
                  ? controller.skipRest
                  : controller.completeCurrentSet,
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFAE67), Color(0xFFFF7A2F)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fitness.withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isSetup
                        ? '开始训练'
                        : isRest
                        ? '跳过休息'
                        : '完成本组',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
              color: enabled ? Colors.white : AppColors.border,
              border: Border.all(
                color: AppColors.fitness.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.fitness : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('训练总结', style: AppTextStyles.pageTitle),
          const SizedBox(height: 10),
          Text(
            '${session.templateName} · ${session.completedSets}/${session.totalTargetSets} 组 · ${_formatDuration(Duration(seconds: session.totalElapsedSeconds))}',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ...session.completed.values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.plan.name, style: AppTextStyles.cardTitle),
                  ),
                  Text('${item.completedSets} 组', style: AppTextStyles.body),
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
                    backgroundColor: AppColors.fitness,
                    foregroundColor: Colors.white,
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
