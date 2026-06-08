import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    hide expRepositoryProvider, focusRepositoryProvider, studyRepositoryProvider;
import '../../../shared/providers/focus_audio_provider.dart';
import '../../../shared/providers/focus_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/study_provider.dart';
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_bus.dart';
import '../utils/focus_assets.dart';
import '../utils/focus_options.dart';
import '../widgets/focus_sound_panel.dart';
import '../widgets/timer_display.dart';

const _sessionMint = Color(0xFF9DEBD8);
const _sessionMintDark = Color(0xFF34BAA5);
const _sessionCream = Color(0xFFF7E5C6);
const _sessionInk = Color(0xFF113541);

int _calculateFocusExp(int durationMinutes) => durationMinutes ~/ 10 + 5;

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
  bool _completionDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(focusCycleProvider.notifier).start(
          focusMinutes: widget.durationMinutes,
          totalRounds: widget.totalRounds,
          type: widget.type,
          title: widget.title,
          subject: widget.subject,
          soundType: widget.soundType,
        );
    _initAudio();
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

      final completed = ref.read(focusCycleProvider.notifier).advanceToNextPhase();
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
    final completed = ref.read(focusCycleProvider.notifier).advanceToNextPhase();
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
    final focusRepo = ref.read(focusRepositoryProvider);
    final studyRepo = ref.read(studyRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final phaseStartMs =
        cycleState.phaseStartAt?.millisecondsSinceEpoch ?? now;
    final actualDuration = completed
        ? widget.durationMinutes
        : ((cycleState.focusSeconds - cycleState.remainingSeconds) / 60).ceil();

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

    final sessionId = await focusRepo.insertFocusSession(session);

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
            '完成${focusTypeLabel(cycleState.type)}专注 '
            '第${cycleState.currentRound}轮 ${widget.durationMinutes}分钟',
          ),
          createdAt: drift.Value(now),
        ),
      );
      final newLevel = expService.calculateLevel(oldTotal + expValue);
      if (newLevel > oldLevel) {
        PetEventBus.instance.emit(
          PetEvent.levelUp(oldLevel: oldLevel, newLevel: newLevel),
        );
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
      expGained: drift.Value(
        completed ? _calculateFocusExp(widget.durationMinutes) : 0,
      ),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    final studyId = await studyRepo.insertStudyRecord(studyRecord);
    await focusRepo.updateFocusSessionStudyLink(sessionId, studyId);

    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(recentFocusSessionsProvider);
    ref.invalidate(todayStudyMinutesProvider);
    ref.invalidate(recentStudyRecordsProvider);
    ref.invalidate(dashboardProvider);

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
              '你完成了 ${widget.totalRounds} 轮专注，获得 ${_calculateFocusExp(widget.durationMinutes)} EXP。未来的自己会感谢你。',
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
        if (!didPop && cycleState.isRunning) _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: _sessionInk,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth >= constraints.maxHeight;
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
                if (isLandscape)
                  _LandscapeSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PortraitSession extends StatelessWidget {
  const _PortraitSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final timerSize = math.min(MediaQuery.sizeOf(context).width * 0.78, 360.0);
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(FocusAssets.deskPortrait, fit: BoxFit.fitWidth),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              _SessionTopBar(
                title: '番茄专注',
                onBack: onCancel,
                centered: true,
              ),
              const SizedBox(height: 14),
              _RoundStepper(cycleState: cycleState, dark: true),
              const SizedBox(height: 22),
              _SessionTitleBlock(cycleState: cycleState, centered: true),
              const SizedBox(height: 20),
              Center(
                child: TimerDisplay(
                  remaining: Duration(seconds: cycleState.remainingSeconds),
                  total: _totalFor(cycleState),
                  isBreak: cycleState.isBreak,
                  size: timerSize,
                  dark: true,
                  roundLabel: '第 ${cycleState.currentRound} / ${cycleState.totalRounds} 轮',
                  catAsset: FocusAssets.catForCycle(cycleState),
                ),
              ),
              const SizedBox(height: 18),
              FocusSoundPanel(
                initialSoundType: cycleState.soundType ?? 'none',
                compact: true,
                dark: true,
              ),
              const SizedBox(height: 22),
              _SessionControls(
                cycleState: cycleState,
                isCycleDone: isCycleDone,
                onCancel: onCancel,
                onPause: onPause,
                onResume: onResume,
                onSkipBreak: onSkipBreak,
                onReturn: onReturn,
              ),
              const SizedBox(height: 18),
              _NextPhaseCard(cycleState: cycleState),
              const SizedBox(height: 16),
              _EncourageNote(compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandscapeSession extends StatelessWidget {
  const _LandscapeSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final timerSize = math.min(height * 0.62, 460.0);
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(FocusAssets.deskLandscape, fit: BoxFit.fitWidth),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 22, 34, 26),
            child: Column(
              children: [
                _SessionTopBar(
                  title: '番茄专注',
                  onBack: onCancel,
                  centered: false,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 9,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RoundStepper(cycleState: cycleState, dark: true),
                            const SizedBox(height: 16),
                            _SessionTitleBlock(
                              cycleState: cycleState,
                              centered: true,
                            ),
                            const SizedBox(height: 14),
                            TimerDisplay(
                              remaining:
                                  Duration(seconds: cycleState.remainingSeconds),
                              total: _totalFor(cycleState),
                              isBreak: cycleState.isBreak,
                              size: timerSize,
                              dark: true,
                              roundLabel:
                                  '第 ${cycleState.currentRound} / ${cycleState.totalRounds} 轮',
                              catAsset: FocusAssets.catForCycle(cycleState),
                              showCat: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 10,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FocusSoundPanel(
                              initialSoundType: cycleState.soundType ?? 'none',
                              dark: true,
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: _SessionControls(
                                    cycleState: cycleState,
                                    isCycleDone: isCycleDone,
                                    onCancel: onCancel,
                                    onPause: onPause,
                                    onResume: onResume,
                                    onSkipBreak: onSkipBreak,
                                    onReturn: onReturn,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: _NextPhaseCard(
                                    cycleState: cycleState,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _EncourageNote(compact: false)),
                                Image.asset(
                                  FocusAssets.catForCycle(cycleState),
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({
    required this.title,
    required this.onBack,
    required this.centered,
  });

  final String title;
  final VoidCallback onBack;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        if (centered) const Spacer(),
        Padding(
          padding: EdgeInsets.only(left: centered ? 0 : 18),
          child: Text(
            title,
            style: const TextStyle(
              color: _sessionCream,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        if (centered) const Spacer(),
        if (centered) const SizedBox(width: 54),
      ],
    );
  }
}

class _RoundStepper extends StatelessWidget {
  const _RoundStepper({required this.cycleState, required this.dark});

  final FocusCycleState cycleState;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cycleState.totalRounds, (index) {
        final round = index + 1;
        final active = round == cycleState.currentRound && !cycleState.isBreak;
        final done = round < cycleState.currentRound ||
            (round == cycleState.currentRound && cycleState.isBreak);
        return Row(
          children: [
            Container(
              width: active ? 46 : 40,
              height: active ? 46 : 40,
              decoration: BoxDecoration(
                color: active
                    ? _sessionMint.withValues(alpha: 0.86)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done || active
                      ? _sessionCream
                      : _sessionCream.withValues(alpha: 0.58),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$round',
                  style: TextStyle(
                    color: active ? _sessionInk : _sessionCream,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (round != cycleState.totalRounds)
              Container(
                width: 34,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: _sessionCream.withValues(alpha: 0.58),
              ),
          ],
        );
      }),
    );
  }
}

class _SessionTitleBlock extends StatelessWidget {
  const _SessionTitleBlock({required this.cycleState, required this.centered});

  final FocusCycleState cycleState;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final title = cycleState.isBreak
        ? (cycleState.phase == FocusPhase.longBreak ? '长休息' : '短休息')
        : (cycleState.title.isEmpty
            ? '${focusTypeLabel(cycleState.type)}专注'
            : cycleState.title);
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _sessionCream,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (cycleState.subject.isNotEmpty && !cycleState.isBreak) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: _sessionMint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _sessionMint.withValues(alpha: 0.5)),
            ),
            child: Text(
              cycleState.subject,
              style: const TextStyle(
                color: _sessionMint,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.cycleState,
    required this.isCycleDone,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    if (isCycleDone) {
      return Center(
        child: _GlowButton(
          icon: Icons.check_rounded,
          label: '返回',
          onTap: onReturn,
          large: true,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlColumn(
          icon: cycleState.isBreak ? Icons.skip_next_rounded : Icons.close_rounded,
          label: cycleState.isBreak ? '跳过' : '取消',
          onTap: cycleState.isBreak ? onSkipBreak : onCancel,
          danger: !cycleState.isBreak,
        ),
        const SizedBox(width: 28),
        _GlowButton(
          icon: cycleState.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: cycleState.isRunning ? '暂停专注' : '继续专注',
          onTap: cycleState.isRunning ? onPause : onResume,
          large: true,
        ),
      ],
    );
  }
}

class _ControlColumn extends StatelessWidget {
  const _ControlColumn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.danger,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(icon: icon, onTap: onTap, danger: danger),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _sessionCream,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: danger
              ? const Color(0x331A0E0A)
              : const Color(0x220D3540),
          border: Border.all(color: _sessionCream.withValues(alpha: 0.72)),
        ),
        child: Icon(icon, color: _sessionCream, size: 26),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.large,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: large ? 86 : 64,
            height: large ? 86 : 64,
            decoration: BoxDecoration(
              color: _sessionMint.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _sessionMint.withValues(alpha: 0.48),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
            ),
            child: Icon(icon, color: Colors.white, size: large ? 44 : 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _sessionMint,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NextPhaseCard extends StatelessWidget {
  const _NextPhaseCard({required this.cycleState, this.compact = false});

  final FocusCycleState cycleState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nextTitle = cycleState.isBreak
        ? '下一阶段：专注'
        : cycleState.isLastRound
            ? '下一阶段：长休息'
            : '下一阶段：短休息';
    final nextTime = cycleState.isBreak
        ? '${cycleState.focusSeconds ~/ 60}:00'
        : cycleState.isLastRound
            ? '${cycleState.longBreakSeconds ~/ 60}:00'
            : '${cycleState.shortBreakSeconds ~/ 60}:00';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xEFFFF8EA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4CEAA), width: 1.2),
      ),
      child: Row(
        children: [
          Image.asset(
            cycleState.isBreak ? FocusAssets.iconPomodoro : FocusAssets.breakCup,
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextTitle,
                  style: const TextStyle(
                    color: Color(0xFF615043),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextTime,
                  style: const TextStyle(
                    color: _sessionMintDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B5747)),
        ],
      ),
    );
  }
}

class _EncourageNote extends StatelessWidget {
  const _EncourageNote({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 22,
        vertical: compact ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33082A35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _sessionCream.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(FocusAssets.particleStar, width: 22, height: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '你专注的每一分钟，都是未来的自己在感谢你。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _sessionCream,
                fontSize: compact ? 14 : 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(FocusAssets.particleHeart, width: 22, height: 22),
        ],
      ),
    );
  }
}

class _FocusIllustrationDialog extends StatelessWidget {
  const _FocusIllustrationDialog({
    required this.image,
    required this.title,
    required this.message,
    required this.primaryText,
    required this.onPrimary,
    this.secondaryImage,
    this.secondaryText,
    this.onSecondary,
  });

  final String image;
  final String? secondaryImage;
  final String title;
  final String message;
  final String primaryText;
  final VoidCallback onPrimary;
  final String? secondaryText;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: math.min(MediaQuery.sizeOf(context).width - 48, 390),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE7D8BF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 116,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(image, width: 112, height: 112),
                  if (secondaryImage != null)
                    Positioned(
                      right: 70,
                      bottom: 4,
                      child: Image.asset(
                        secondaryImage!,
                        width: 58,
                        height: 58,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2E3734),
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF73736C),
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (secondaryText != null && onSecondary != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: const Color(0xFFAF6A55),
                        side: const BorderSide(color: Color(0xFFE5B9A8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(secondaryText!),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      backgroundColor: _sessionMintDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(primaryText),
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

Duration _totalFor(FocusCycleState state) {
  if (state.phase == FocusPhase.focus) {
    return Duration(seconds: state.focusSeconds);
  }
  if (state.phase == FocusPhase.shortBreak) {
    return Duration(seconds: state.shortBreakSeconds);
  }
  return Duration(seconds: state.longBreakSeconds);
}
