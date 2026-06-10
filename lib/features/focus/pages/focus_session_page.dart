import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    hide
        expRepositoryProvider,
        focusRepositoryProvider,
        studyRepositoryProvider;
import '../../../shared/providers/focus_audio_provider.dart';
import '../../../shared/providers/focus_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/study_provider.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../utils/focus_assets.dart';
import '../utils/focus_options.dart';
import '../widgets/focus_sound_panel.dart';
import '../widgets/timer_display.dart';

part '../widgets/focus_session_widgets.dart';

const _sessionMint = Color(0xFF9DEBD8);
const _sessionMintDark = Color(0xFF34BAA5);
const _sessionCream = Color(0xFFF7E5C6);
const _sessionInk = Color(0xFF113541);

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
  final Set<String> _savedRoundKeys = {};
  bool _phaseCompletionHandled = false;
  bool _completionDialogShown = false;
  late FocusAudioStateNotifier _audioNotifier;

  @override
  void initState() {
    super.initState();
    _audioNotifier = ref.read(focusAudioStateProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(focusCycleProvider.notifier)
          .start(
            focusMinutes: widget.durationMinutes,
            totalRounds: widget.totalRounds,
            type: widget.type,
            title: widget.title,
            subject: widget.subject,
            soundType: widget.soundType,
          );
    });
    _initAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_audioNotifier.stopNoise());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusCycleProvider.notifier).recalculate();
    }
  }

  void _initAudio() {
    final soundType = ref.read(focusCycleProvider).soundType;
    if (soundType != null && soundType.isNotEmpty && soundType != 'none') {
      Future.microtask(() {
        if (mounted) {
          ref.read(focusAudioStateProvider.notifier).startNoise(soundType);
        }
      });
    }
  }

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
    if (mounted) context.pop();
  }

  void _onPhaseComplete() {
    if (_phaseCompletionHandled) return;
    _phaseCompletionHandled = true;
    final cycleState = ref.read(focusCycleProvider);

    if (cycleState.phase == FocusPhase.focus) {
      ref.read(focusAudioStateProvider.notifier).stopNoise();
      ref.read(focusAudioStateProvider.notifier).playBell('gentle_bell');
      _saveFocusRound(completed: true);

      PetEventBus.instance.emit(
        PetEvent.moduleCompleted(
          eventId: 'focus_${DateTime.now().millisecondsSinceEpoch}',
          type: PetEventType.studyCompleted,
          module: 'study',
        ),
      );

      final completed = ref
          .read(focusCycleProvider.notifier)
          .advanceToNextPhase();
      _phaseCompletionHandled = false;
      if (!completed) {
        _showStatusDialog(
          title: cycleState.isLastRound ? '进入长休息' : '进入短休息',
          message: '这一轮完成啦，喝口水，让大脑轻轻放松一下。',
          image: FocusAssets.breakCup,
          secondaryImage: FocusAssets.catRest,
          primaryText: '知道啦',
        );
      }
      return;
    }

    ref.read(focusAudioStateProvider.notifier).playBell('gentle_bell');
    ref.read(focusAudioStateProvider.notifier).stopNoise();
    final completed = ref
        .read(focusCycleProvider.notifier)
        .advanceToNextPhase();
    if (completed) {
      _showCompletionDialog();
    } else {
      _phaseCompletionHandled = false;
      _initAudio();
    }
  }

  Future<void> _saveFocusRound({required bool completed}) async {
    if (_saved) return;
    _saved = true;

    final cycleState = ref.read(focusCycleProvider);
    final saveKey =
        '${cycleState.sessionGroupId ?? 'local'}:${cycleState.currentRound}:$completed';
    if (_savedRoundKeys.contains(saveKey)) {
      _saved = false;
      return;
    }
    final focusRepo = ref.read(focusRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final phaseStartMs = cycleState.phaseStartAt?.millisecondsSinceEpoch ?? now;
    final actualDuration = completed
        ? widget.durationMinutes
        : ((cycleState.focusSeconds - cycleState.remainingSeconds) / 60).ceil();
    final expService = ref.read(expServiceProvider);
    final expValue = expService.calculateFocusExp(
      durationMinutes: widget.durationMinutes,
      completed: completed,
    );
    final expReason = completed
        ? '完成${focusTypeLabel(cycleState.type)}专注 '
              '第${cycleState.currentRound}轮 ${widget.durationMinutes}分钟'
        : null;
    int? oldLevel;
    int? newLevel;
    if (completed) {
      final expRepo = ref.read(expRepositoryProvider);
      final oldTotal = await expRepo.getTotalExp();
      oldLevel = expService.calculateLevel(oldTotal);
      newLevel = expService.calculateLevel(oldTotal + expValue);
    }

    final session = FocusSessionsCompanion(
      type: drift.Value(cycleState.type),
      title: drift.Value(
        cycleState.title.isEmpty
            ? '${focusTypeLabel(cycleState.type)}专注'
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

    if (cycleState.sessionGroupId != null) {
      final existingSession = await focusRepo.getFocusSessionByGroupRound(
        groupId: cycleState.sessionGroupId!,
        roundIndex: cycleState.currentRound,
        completed: completed,
      );
      if (existingSession != null) {
        _savedRoundKeys.add(saveKey);
        _saved = false;
        return;
      }
    }

    final subject = cycleState.subject.isNotEmpty ? cycleState.subject : null;
    final studyTitle = cycleState.title.isNotEmpty
        ? cycleState.title
        : '${focusTypeLabel(cycleState.type)}专注';
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
            ? '专注完成 · ${focusTypeLabel(cycleState.type)}模式 · 第${cycleState.currentRound}轮'
            : '中途打断 · 实际专注 $actualDuration 分钟',
      ),
      expGained: drift.Value(expValue),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    final result = await focusRepo.saveFocusRound(
      session: session,
      studyRecord: studyRecord,
      expValue: completed ? expValue : null,
      expReason: expReason,
      createdAt: now,
    );
    if (result.inserted &&
        completed &&
        oldLevel != null &&
        newLevel != null &&
        newLevel > oldLevel) {
      PetEventBus.instance.emit(
        PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
      );
    }

    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(recentFocusSessionsProvider);
    ref.invalidate(todayStudyMinutesProvider);
    ref.invalidate(recentStudyRecordsProvider);
    ref.invalidate(dashboardProvider);

    _savedRoundKeys.add(saveKey);
    _saved = false;
  }

  void _showCancelDialog() {
    final cycleState = ref.read(focusCycleProvider);
    final elapsed = cycleState.focusSeconds - cycleState.remainingSeconds;
    final elapsedMinutes = (elapsed / 60).ceil();

    showDialog(
      context: context,
      builder: (ctx) => _FocusIllustrationDialog(
        image: FocusAssets.interruptWarning,
        title: '中断专注？',
        message: elapsedMinutes > 0
            ? '已经专注 $elapsedMinutes 分钟。中断后会记录为未完成状态。'
            : '当前专注会记录为未完成状态。',
        primaryText: '继续专注',
        secondaryText: '确认中断',
        onPrimary: () => Navigator.of(ctx).pop(),
        onSecondary: () {
          Navigator.of(ctx).pop();
          _cancelSession();
        },
      ),
    );
  }

  void _showStatusDialog({
    required String title,
    required String message,
    required String image,
    required String primaryText,
    String? secondaryImage,
  }) {
    if (!mounted) return;
    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _FocusIllustrationDialog(
          image: image,
          secondaryImage: secondaryImage,
          title: title,
          message: message,
          primaryText: primaryText,
          onPrimary: () => Navigator.of(ctx).pop(),
        ),
      );
    });
  }

  void _showCompletionDialog() {
    if (_completionDialogShown || !mounted) return;
    _completionDialogShown = true;
    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _FocusIllustrationDialog(
          image: FocusAssets.successBadge,
          secondaryImage: FocusAssets.expReward,
          title: '专注完成',
          message:
              '你完成了 ${widget.totalRounds} 轮专注，获得 ${ref.read(expServiceProvider).calculateFocusExp(durationMinutes: widget.durationMinutes)} EXP。未来的自己会感谢你。',
          primaryText: '返回',
          onPrimary: () {
            Navigator.of(ctx).pop();
            context.pop();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cycleState = ref.watch(focusCycleProvider);

    ref.listen<FocusCycleState>(focusCycleProvider, (prev, next) {
      if (prev != null && !prev.phaseCompleted && next.phaseCompleted) {
        _onPhaseComplete();
      }
    });

    final isCycleDone =
        !cycleState.isRunning &&
        cycleState.phase == FocusPhase.longBreak &&
        cycleState.remainingSeconds <= 0;

    return PopScope(
      canPop: !cycleState.isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && cycleState.isRunning) _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: _sessionInk,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth >= constraints.maxHeight;
            final isCompactLandscape =
                isLandscape &&
                (constraints.maxWidth < 900 || constraints.maxHeight < 520);
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    isLandscape
                        ? FocusAssets.bgSessionLandscape
                        : FocusAssets.bgSessionPortrait,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    FocusAssets.roomGlow,
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.34),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF061C29).withValues(alpha: 0.28),
                  ),
                ),
                if (isCompactLandscape)
                  _CompactLandscapeSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
                    onSoundChanged: (value) {
                      ref.read(focusCycleProvider.notifier).setSoundType(value);
                    },
                  )
                else if (isLandscape)
                  _LandscapeSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
                    onSoundChanged: (value) {
                      ref.read(focusCycleProvider.notifier).setSoundType(value);
                    },
                  )
                else
                  _PortraitSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
                    onSoundChanged: (value) {
                      ref.read(focusCycleProvider.notifier).setSoundType(value);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
