import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../plan/services/reminder_notification_service.dart';
import '../models/workout_session_state.dart';
import '../providers/workout_session_provider.dart';
import '../utils/fitness_timer_assets.dart';

part '../widgets/fitness_training_timer_widgets.dart';
part '../widgets/fitness_training_timer_sheets.dart';

class FitnessTrainingTimerPage extends ConsumerStatefulWidget {
  const FitnessTrainingTimerPage({super.key});

  @override
  ConsumerState<FitnessTrainingTimerPage> createState() =>
      _FitnessTrainingTimerPageState();
}

class _FitnessTrainingTimerPageState
    extends ConsumerState<FitnessTrainingTimerPage> {
  int? _selectedTemplateId;
  bool _loadedInitialTemplate = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final templates = ref.watch(fitnessWorkoutTemplatesProvider);
    final session = ref.watch(workoutSessionProvider);

    ref.listen(fitnessWorkoutTemplatesProvider, (_, next) {
      final list = next.valueOrNull;
      if (_loadedInitialTemplate || list == null || list.isEmpty) return;
      _loadedInitialTemplate = true;
      _loadTemplate(list.first);
    });

    return Scaffold(
      backgroundColor: colors.softOrange,
      body: SafeArea(
        child: templates.when(
          data: (items) {
            _ensureInitialTemplateLoaded(items);
            return _buildContent(items, session);
          },
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.fitness)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '训练模板加载失败: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _ensureInitialTemplateLoaded(List<FitnessWorkoutTemplate> templates) {
    if (_loadedInitialTemplate || templates.isEmpty) return;
    _loadedInitialTemplate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadTemplate(templates.first);
    });
  }

  Widget _buildContent(
    List<FitnessWorkoutTemplate> templates,
    WorkoutSessionState session,
  ) {
    final controller = ref.read(workoutSessionProvider.notifier);
    return Column(
      children: [
        _HeaderBar(
          elapsed: _formatDuration(
            Duration(seconds: session.totalElapsedSeconds),
          ),
          onBack: () => context.pop(),
          onTemplates: () => _showTemplateSheet(templates),
          onEdit: session.exercises.isEmpty ? null : _showEditPlanSheet,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              _TemplateStrip(
                templates: templates,
                selectedTemplateId: _selectedTemplateId,
                onSelect: _loadTemplate,
              ),
              const SizedBox(height: 14),
              if (session.phase == WorkoutSessionPhase.summary)
                _SummaryCard(
                  session: session,
                  onContinue: controller.reset,
                  onSave: session.canSave
                      ? () => _showSaveSheet(session)
                      : null,
                )
              else ...[
                _CurrentExerciseCard(session: session),
                const SizedBox(height: 14),
                _TimerPanel(session: session),
                const SizedBox(height: 14),
                _StatsStrip(session: session),
                const SizedBox(height: 14),
                _NextExerciseCard(session: session),
                const SizedBox(height: 14),
                _CompanionBubble(session: session),
              ],
            ],
          ),
        ),
        if (session.phase != WorkoutSessionPhase.summary)
          _BottomControls(session: session, controller: controller),
      ],
    );
  }

  Future<void> _loadTemplate(FitnessWorkoutTemplate template) async {
    _selectedTemplateId = template.id;
    final exercises = await ref
        .read(fitnessRepositoryProvider)
        .getWorkoutTemplateExercises(template.id);
    if (!mounted) return;
    ref.read(workoutSessionProvider.notifier).loadTemplate(template, exercises);
    setState(() {});
  }

  Future<void> _showTemplateSheet(
    List<FitnessWorkoutTemplate> templates,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplatePickerSheet(
        templates: templates,
        selectedTemplateId: _selectedTemplateId,
        onSelect: (template) {
          Navigator.pop(context);
          _loadTemplate(template);
        },
      ),
    );
  }

  Future<void> _showEditPlanSheet() async {
    final session = ref.read(workoutSessionProvider);
    final result = await showModalBottomSheet<_PlanEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanEditorSheet(session: session),
    );
    if (result == null || !mounted) return;

    ref
        .read(workoutSessionProvider.notifier)
        .setCustomPlan(
          templateName: result.templateName,
          bodyPart: result.bodyPart,
          exercises: result.exercises,
        );

    if (result.saveAsTemplate) {
      await _saveCustomTemplate(result);
      ref.invalidate(fitnessWorkoutTemplatesProvider);
    }
  }

  Future<void> _saveCustomTemplate(_PlanEditResult result) async {
    final repo = ref.read(fitnessRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    await repo.insertWorkoutTemplate(
      FitnessWorkoutTemplatesCompanion.insert(
        name: result.templateName,
        bodyPart: result.bodyPart,
        goalType: const Value('custom'),
        description: const Value('训练会话中保存的自定义模板'),
        isBuiltIn: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
      result.exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;
        return FitnessWorkoutTemplateExercisesCompanion.insert(
          templateId: 0,
          exerciseName: exercise.name,
          exerciseType: Value(exercise.typeCode),
          targetSets: exercise.targetSets,
          targetReps: Value(exercise.targetReps),
          targetSeconds: Value(exercise.targetSeconds),
          weightKg: Value(exercise.weightKg),
          restSeconds: Value(exercise.restSeconds),
          sortOrder: Value(index),
          note: Value(exercise.note),
          createdAt: now,
        );
      }).toList(),
    );
  }

  Future<void> _showSaveSheet(WorkoutSessionState session) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveSummarySheet(
        session: session,
        onSave: (intensity, fatigue, feeling) =>
            _saveWorkout(session, intensity, fatigue, feeling),
      ),
    );
    if (saved == true && mounted) {
      ref.read(workoutSessionProvider.notifier).reset();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveWorkout(
    WorkoutSessionState session,
    int intensity,
    int fatigue,
    String feeling,
  ) async {
    final repo = ref.read(fitnessRepositoryProvider);
    final expService = ref.read(expServiceProvider);
    final expRepo = ref.read(expRepositoryProvider);
    final now = DateTime.now();
    final durationMinutes = (session.totalElapsedSeconds / 60).ceil().clamp(
      1,
      999,
    );

    final exp = expService.calculateFitnessExp(
      durationMinutes: durationMinutes,
      intensityLevel: intensity,
      exerciseCount: session.completed.length,
      hasFeeling: feeling.trim().isNotEmpty,
    );

    final oldTotal = await expRepo.getTotalExp();
    final oldLevel = expService.calculateLevel(oldTotal);

    await repo.saveFitnessRecordWithExp(
      record: FitnessRecordsCompanion(
        mode: const Value('professional'),
        title: Value(session.templateName),
        bodyPart: Value(session.bodyPart),
        startTime: Value((session.startedAt ?? now).millisecondsSinceEpoch),
        endTime: Value(now.millisecondsSinceEpoch),
        durationMinutes: Value(durationMinutes),
        fatigueLevel: Value(fatigue),
        intensityLevel: Value(intensity),
        feeling: Value(feeling.trim().isEmpty ? null : feeling.trim()),
        note: Value(
          '训练会话完成 ${session.completedSets}/${session.totalTargetSets} 组',
        ),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
      exercises: session.completed.entries.map((entry) {
        final index = entry.key;
        final progress = entry.value;
        return FitnessExercisesCompanion.insert(
          fitnessRecordId: 0,
          exerciseName: progress.plan.name,
          sets: progress.completedSets,
          reps: progress.plan.targetReps ?? 0,
          weight: Value(progress.plan.weightKg),
          restSeconds: Value(progress.plan.restSeconds),
          exerciseType: Value(progress.plan.typeCode),
          durationSeconds: Value(progress.plan.targetSeconds),
          sortOrder: Value(index),
          note: Value(progress.plan.note),
          createdAt: now.millisecondsSinceEpoch,
        );
      }),
      exp: exp,
      reason: '健身: ${session.templateName} ($durationMinutes分钟)',
      createdAt: now.millisecondsSinceEpoch,
    );

    final newLevel = expService.calculateLevel(oldTotal + exp);
    if (newLevel > oldLevel) {
      PetEventBus.instance.emit(
        PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
      );
    }
    PetEventBus.instance.emit(
      PetEvent.moduleCompleted(
        eventId: 'fitness_${now.millisecondsSinceEpoch}',
        type: PetEventType.fitnessCompleted,
        module: 'fitness',
      ),
    );

    await ref
        .read(reminderNotificationServiceProvider)
        .showImmediate(
          id: 5206,
          title: '训练完成',
          body: '${session.templateName} 已完成，辛苦啦！记录一下今天的感受吧',
          payload: 'fitness_complete',
        );

    ref.invalidate(recentFitnessRecordsProvider);
    ref.invalidate(todayFitnessMinutesProvider);
    ref.invalidate(weeklyFitnessCountProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(fitnessChartDataProvider(7));
    ref.invalidate(fitnessChartDataProvider(30));
    ref.invalidate(fitnessChartDataProvider(365));
  }
}
