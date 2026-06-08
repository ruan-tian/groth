import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    hide focusRepositoryProvider, studyRepositoryProvider, expRepositoryProvider;
import '../../../shared/providers/focus_audio_provider.dart';
import '../../../shared/providers/focus_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/study_provider.dart';
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_bus.dart';
import '../widgets/focus_sound_panel.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_display.dart';

// ─── Focus Colors ───────────────────────────────────────────────────────────

const Color _focusPrimary = Color(0xFF00897B);
const Color _breakColor = Color(0xFF059669);

// ─── Helper functions ───────────────────────────────────────────────────────

String _getTypeLabel(String type) {
  switch (type) {
    case 'pomodoro':
      return '番茄';
    case 'deep':
      return '深度';
    case 'ultra':
      return '超深度';
    case 'custom':
      return '自定义';
    default:
      return '专注';
  }
}

IconData _getTypeIcon(String type) {
  switch (type) {
    case 'pomodoro':
      return Icons.timer;
    case 'deep':
      return Icons.psychology;
    case 'ultra':
      return Icons.rocket_launch;
    case 'custom':
      return Icons.tune;
    default:
      return Icons.timer;
  }
}

int _calculateFocusExp(int durationMinutes) {
  final base = durationMinutes ~/ 10;
  return base + 5;
}

// ─── Focus Session Page ─────────────────────────────────────────────────────

class FocusSessionPage extends ConsumerStatefulWidget {
  const FocusSessionPage({
    super.key,
    required this.durationMinutes,
    required this.type,
    this.title = '',
    this.subject = '',
    this.soundType,
    this.totalRounds = 4,
  });

  final int durationMinutes;
  final String type;
  final String title;
  final String subject;
  final String? soundType;
  final int totalRounds;

  @override
  ConsumerState<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends ConsumerState<FocusSessionPage>
    with WidgetsBindingObserver {
  bool _saved = false;
  bool _phaseCompletionHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final notifier = ref.read(focusCycleProvider.notifier);
    notifier.start(
      focusMinutes: widget.durationMinutes,
      totalRounds: widget.totalRounds,
      type: widget.type,
      title: widget.title,
      subject: widget.subject,
      soundType: widget.soundType,
    );

    _initAudio();
  }

  void _initAudio() {
    final soundType = widget.soundType;
    if (soundType != null && soundType.isNotEmpty && soundType != 'none') {
      Future.microtask(() {
        if (mounted) {
          ref.read(focusAudioStateProvider.notifier).startNoise(soundType);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(focusAudioStateProvider.notifier).stopNoise();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusCycleProvider.notifier).recalculate();
    }
  }

  // ── Timer controls ──────────────────────────────────────────────────────

  void _pauseTimer() {
    ref.read(focusAudioStateProvider.notifier).pauseNoise();
    ref.read(focusCycleProvider.notifier).pause();
  }

  void _resumeTimer() {
    ref.read(focusAudioStateProvider.notifier).resumeNoise();
    ref.read(focusCycleProvider.notifier).resume();
  }

  void _skipBreak() {
    ref.read(focusCycleProvider.notifier).skipBreak();
    _phaseCompletionHandled = false;
    _initAudio();
  }

  void _cancelSession() {
    ref.read(focusAudioStateProvider.notifier).stopNoise();
    _saveFocusRound(completed: false);
    ref.read(focusCycleProvider.notifier).cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('专注已中断，已归档到学习记录'),
          backgroundColor: AppColors.warning,
        ),
      );
      context.pop();
    }
  }

  // ── Phase completion ────────────────────────────────────────────────────

  void _onPhaseComplete() {
    if (_phaseCompletionHandled) return;
    _phaseCompletionHandled = true;

    final cycleState = ref.read(focusCycleProvider);

    if (cycleState.phase == FocusPhase.focus) {
      // Focus phase completed
      ref.read(focusAudioStateProvider.notifier).stopNoise();
      ref.read(focusAudioStateProvider.notifier).playBell('gentle_bell');

      // Save this focus round
      _saveFocusRound(completed: true);

      // Pet event
      PetEventBus.instance.emit(PetEvent.moduleCompleted(
        eventId: 'focus_${DateTime.now().millisecondsSinceEpoch}',
        type: PetEventType.studyCompleted,
        module: 'study',
      ));

      // Advance to next phase
      final cycleComplete =
          ref.read(focusCycleProvider.notifier).advanceToNextPhase();

      if (cycleComplete) {
        // Entire cycle done (shouldn't happen here, longBreak comes first)
      } else {
        // Started a break
        _phaseCompletionHandled = false;
      }
    } else {
      // Break phase completed
      ref.read(focusAudioStateProvider.notifier).playBell('gentle_bell');
      ref.read(focusAudioStateProvider.notifier).stopNoise();

      final cycleComplete =
          ref.read(focusCycleProvider.notifier).advanceToNextPhase();

      if (!cycleComplete) {
        // Started next focus round
        _phaseCompletionHandled = false;
        _initAudio();
      } else {
        // Entire cycle complete
        setState(() {});
      }
    }
  }

  // ── Database operations ─────────────────────────────────────────────────

  Future<void> _saveFocusRound({required bool completed}) async {
    if (_saved) return;
    _saved = true;

    final cycleState = ref.read(focusCycleProvider);
    final focusRepo = ref.read(focusRepositoryProvider);
    final studyRepo = ref.read(studyRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final phaseStartMs =
        cycleState.phaseStartAt?.millisecondsSinceEpoch ?? now;
    final actualDuration = completed
        ? widget.durationMinutes
        : ((cycleState.focusSeconds - cycleState.remainingSeconds) / 60)
            .ceil();

    // Save focus session with round info
    final session = FocusSessionsCompanion(
      type: drift.Value(cycleState.type),
      title: drift.Value(
        cycleState.title.isEmpty
            ? '${_getTypeLabel(cycleState.type)}专注'
            : cycleState.title,
      ),
      startTime: drift.Value(phaseStartMs),
      endTime: drift.Value(now),
      durationMinutes: drift.Value(actualDuration),
      completed: drift.Value(completed),
      soundType: drift.Value(cycleState.soundType),
      roundIndex: drift.Value(cycleState.currentRound),
      sessionGroupId: drift.Value(cycleState.sessionGroupId),
      createdAt: drift.Value(now),
    );

    final sessionId = await focusRepo.insertFocusSession(session);

    // EXP
    if (completed) {
      final expValue = _calculateFocusExp(widget.durationMinutes);
      final expRepo = ref.read(expRepositoryProvider);
      final expService = ref.read(expServiceProvider);
      final oldTotal = await expRepo.getTotalExp();
      final oldLevel = expService.calculateLevel(oldTotal);
      await expRepo.insertExpLog(
        GrowthExpLogsCompanion(
          sourceType: const drift.Value('focus'),
          sourceId: drift.Value(sessionId),
          expValue: drift.Value(expValue),
          reason: drift.Value(
            '完成${_getTypeLabel(cycleState.type)}专注 '
            '第${cycleState.currentRound}轮 ${widget.durationMinutes}分钟',
          ),
          createdAt: drift.Value(now),
        ),
      );
      final newTotal = oldTotal + expValue;
      final newLevel = expService.calculateLevel(newTotal);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(PetEvent.levelUp(
          oldLevel: oldLevel,
          newLevel: newLevel,
        ));
      }
    }

    // Auto-archive to study records
    final subject =
        cycleState.subject.isNotEmpty ? cycleState.subject : null;
    final studyTitle = cycleState.title.isNotEmpty
        ? cycleState.title
        : '${_getTypeLabel(cycleState.type)}专注';

    final studyRecord = StudyRecordsCompanion(
      mode: const drift.Value('simple'),
      title: drift.Value(studyTitle),
      subject: drift.Value(subject),
      startTime: drift.Value(phaseStartMs),
      endTime: drift.Value(now),
      durationMinutes: drift.Value(actualDuration),
      focusLevel: drift.Value(completed ? 4 : 2),
      note: drift.Value(
        completed
            ? '专注完成 · ${_getTypeLabel(cycleState.type)}模式 · 第${cycleState.currentRound}轮'
            : '中途中断 · 实际专注 $actualDuration 分钟',
      ),
      expGained: drift.Value(
        completed ? _calculateFocusExp(widget.durationMinutes) : 0,
      ),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    final studyId = await studyRepo.insertStudyRecord(studyRecord);
    await focusRepo.updateFocusSessionStudyLink(sessionId, studyId);

    // Refresh providers
    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(recentFocusSessionsProvider);
    ref.invalidate(todayStudyMinutesProvider);
    ref.invalidate(recentStudyRecordsProvider);
    ref.invalidate(dashboardProvider);

    // Reset for next round
    _saved = false;
  }

  // ── Cancel dialog ───────────────────────────────────────────────────────

  void _showCancelDialog() {
    final cycleState = ref.read(focusCycleProvider);
    final elapsed = cycleState.focusSeconds - cycleState.remainingSeconds;
    final elapsedMinutes = (elapsed / 60).ceil();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('中断专注？'),
        content: Text(
          elapsedMinutes > 0
              ? '已专注 $elapsedMinutes 分钟（第${cycleState.currentRound}轮），'
                  '中断后将记录为未完成状态。'
              : '当前专注将被记录为未完成状态。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续专注'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelSession();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('确认中断'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cycleState = ref.watch(focusCycleProvider);

    // Listen for phase completion
    ref.listen<FocusCycleState>(focusCycleProvider, (prev, next) {
      if (prev != null &&
          prev.remainingSeconds > 0 &&
          next.remainingSeconds <= 0 &&
          next.isRunning) {
        _onPhaseComplete();
      }
    });

    final isCycleDone = !cycleState.isRunning &&
        cycleState.phase == FocusPhase.longBreak &&
        cycleState.remainingSeconds <= 0;

    return PopScope(
      canPop: !cycleState.isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && cycleState.isRunning) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        backgroundColor: cycleState.isBreak
            ? const Color(0xFFF0FDF4)
            : AppColors.background,
        appBar: AppBar(
          title: Text(_getTypeLabel(cycleState.type)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: !cycleState.isRunning,
          actions: [
            if (cycleState.isRunning)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _showCancelDialog,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Round indicator ──
              _buildRoundIndicator(cycleState),

              // ── Session info ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cycleState.isBreak
                              ? Icons.coffee
                              : _getTypeIcon(cycleState.type),
                          color: cycleState.isBreak
                              ? _breakColor
                              : _focusPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            cycleState.isBreak
                                ? (cycleState.phase == FocusPhase.longBreak
                                    ? '长休息'
                                    : '短休息')
                                : (cycleState.title.isEmpty
                                    ? '${_getTypeLabel(cycleState.type)}专注'
                                    : cycleState.title),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cycleState.soundType != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.music_note,
                            color: AppColors.textTertiary,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    // Subject tag
                    if (cycleState.subject.isNotEmpty && !cycleState.isBreak) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.study.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cycleState.subject,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.study,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Timer ──
              const Spacer(),
              Center(
                child: TimerDisplay(
                  remaining: Duration(seconds: cycleState.remainingSeconds),
                  total: Duration(
                    seconds: cycleState.phase == FocusPhase.focus
                        ? cycleState.focusSeconds
                        : cycleState.phase == FocusPhase.shortBreak
                            ? cycleState.shortBreakSeconds
                            : cycleState.longBreakSeconds,
                  ),
                  isBreak: cycleState.isBreak,
                ),
              ),
              const SizedBox(height: 24),

              // ── Sound panel ──
              if (cycleState.isRunning && cycleState.soundType != null)
                FocusSoundPanel(initialSoundType: cycleState.soundType!),

              const Spacer(),

              // ── Controls ──
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: isCycleDone
                    ? _buildReturnButton()
                    : cycleState.isBreak
                        ? _buildBreakControls(cycleState)
                        : TimerControls(
                            isRunning: cycleState.isRunning,
                            isPaused: !cycleState.isRunning &&
                                cycleState.remainingSeconds > 0,
                            onStart: () {},
                            onPause: _pauseTimer,
                            onResume: _resumeTimer,
                            onCancel: _showCancelDialog,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _buildRoundIndicator(FocusCycleState cycleState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(cycleState.totalRounds, (index) {
          final roundNum = index + 1;
          final isCompleted = roundNum < cycleState.currentRound ||
              (roundNum == cycleState.currentRound &&
                  cycleState.phase != FocusPhase.focus);
          final isCurrent = roundNum == cycleState.currentRound &&
              cycleState.phase == FocusPhase.focus;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isCurrent ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isCompleted
                  ? _breakColor
                  : isCurrent
                      ? _focusPrimary
                      : AppColors.border,
              borderRadius: BorderRadius.circular(5),
            ),
            child: isCurrent
                ? Center(
                    child: Text(
                      '$roundNum',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          );
        }),
      ),
    );
  }

  Widget _buildBreakControls(FocusCycleState cycleState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip break
        GestureDetector(
          onTap: _skipBreak,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.skip_next_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Pause / Resume
        GestureDetector(
          onTap: cycleState.isRunning ? _pauseTimer : _resumeTimer,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _breakColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _breakColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              cycleState.isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnButton() {
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.check),
        label: const Text('返回'),
        style: FilledButton.styleFrom(
          backgroundColor: _focusPrimary,
          minimumSize: const Size(200, 48),
        ),
      ),
    );
  }
}
