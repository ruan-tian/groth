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
  });

  final int durationMinutes;
  final String type;
  final String title;
  final String subject;
  final String? soundType;

  @override
  ConsumerState<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends ConsumerState<FocusSessionPage> {
  Timer? _timer;
  late int _remainingSeconds;
  late final int _totalSeconds;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  late final int _startTimeMs;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _isRunning = true;
    _startTimer();
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
    _timer?.cancel();
    ref.read(focusAudioStateProvider.notifier).stopNoise();
    super.dispose();
  }

  // ── Timer controls ──────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    ref.read(focusAudioStateProvider.notifier).pauseNoise();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    ref.read(focusAudioStateProvider.notifier).resumeNoise();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _startTimer();
  }

  void _cancelSession() {
    _timer?.cancel();
    ref.read(focusAudioStateProvider.notifier).stopNoise();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isCompleted = true;
    });
    _saveSession(completed: false);
  }

  void _completeSession() {
    _timer?.cancel();
    ref.read(focusAudioStateProvider.notifier).stopNoise();
    ref.read(focusAudioStateProvider.notifier).playBell('gentle_bell');
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isCompleted = true;
      _remainingSeconds = 0;
    });
    _saveSession(completed: true);
  }

  // ── Database operations ─────────────────────────────────────────────────

  Future<void> _saveSession({required bool completed}) async {
    if (_saved) return;
    _saved = true;

    final focusRepo = ref.read(focusRepositoryProvider);
    final studyRepo = ref.read(studyRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final actualDuration = completed
        ? widget.durationMinutes
        : ((_totalSeconds - _remainingSeconds) / 60).ceil();

    // 保存专注记录
    final session = FocusSessionsCompanion(
      type: drift.Value(widget.type),
      title: drift.Value(
        widget.title.isEmpty
            ? '${_getTypeLabel(widget.type)}专注'
            : widget.title,
      ),
      startTime: drift.Value(_startTimeMs),
      endTime: drift.Value(now),
      durationMinutes: drift.Value(actualDuration),
      completed: drift.Value(completed),
      soundType: drift.Value(widget.soundType),
      createdAt: drift.Value(now),
    );

    final sessionId = await focusRepo.insertFocusSession(session);

    // 完成时记录经验值
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
            '完成${_getTypeLabel(widget.type)}专注 ${widget.durationMinutes}分钟',
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

    // 自动归档到学习记录
    final subject = widget.subject.isNotEmpty ? widget.subject : null;
    final studyTitle = widget.title.isNotEmpty
        ? widget.title
        : '${_getTypeLabel(widget.type)}专注';

    final studyRecord = StudyRecordsCompanion(
      mode: const drift.Value('simple'),
      title: drift.Value(studyTitle),
      subject: drift.Value(subject),
      startTime: drift.Value(_startTimeMs),
      endTime: drift.Value(now),
      durationMinutes: drift.Value(actualDuration),
      focusLevel: drift.Value(completed ? 4 : 2),
      note: drift.Value(
        completed
            ? '专注完成 · ${_getTypeLabel(widget.type)}模式'
            : '中途中断 · 实际专注 $actualDuration 分钟',
      ),
      expGained: drift.Value(completed ? _calculateFocusExp(widget.durationMinutes) : 0),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    final studyId = await studyRepo.insertStudyRecord(studyRecord);

    // 关联专注记录到学习记录
    await focusRepo.updateFocusSessionStudyLink(sessionId, studyId);

    // 刷新相关 Provider
    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(recentFocusSessionsProvider);
    ref.invalidate(todayStudyMinutesProvider);
    ref.invalidate(recentStudyRecordsProvider);
    ref.invalidate(dashboardProvider);

    if (mounted) {
      // 发送宠物事件（专注完成或中断都算学习完成）
      PetEventBus.instance.emit(PetEvent.moduleCompleted(
        eventId: 'focus_${DateTime.now().millisecondsSinceEpoch}',
        type: PetEventType.studyCompleted,
        module: 'study',
      ));
    }

    if (mounted && completed) {
      _showCompletionDialog(actualDuration);
    } else if (mounted) {
      _showInterruptedSnackBar(actualDuration);
      context.pop();
    }
  }

  // ── Completion dialog ───────────────────────────────────────────────────

  void _showCompletionDialog(int duration) {
    final expValue = _calculateFocusExp(widget.durationMinutes);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration, color: _focusPrimary, size: 48),
        title: const Text('专注完成！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_getTypeLabel(widget.type)} · ${widget.durationMinutes}分钟',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (widget.subject.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.study.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.subject,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.study,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '+$expValue EXP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已自动归档到学习记录',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _focusPrimary,
            ),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  // ── Interrupted snackbar ────────────────────────────────────────────────

  void _showInterruptedSnackBar(int duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('专注已中断，记录 $duration 分钟 · 已归档到学习记录'),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Cancel confirmation ─────────────────────────────────────────────────

  void _showCancelDialog() {
    final elapsed = _totalSeconds - _remainingSeconds;
    final elapsedMinutes = (elapsed / 60).ceil();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('中断专注？'),
        content: Text(
          elapsedMinutes > 0
              ? '已专注 $elapsedMinutes 分钟，中断后将记录为未完成状态并归档到学习记录。'
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
    return PopScope(
      canPop: !_isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isRunning) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_getTypeLabel(widget.type)),
          centerTitle: true,
          backgroundColor: AppColors.background,
          automaticallyImplyLeading: !_isRunning,
          actions: [
            if (_isRunning)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _showCancelDialog,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Session info ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    // 标题行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getTypeIcon(widget.type),
                          color: _focusPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.title.isEmpty
                                ? '${_getTypeLabel(widget.type)}专注'
                                : widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.soundType != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.music_note,
                            color: AppColors.textTertiary,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    // 科目标签
                    if (widget.subject.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.study.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.subject,
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

              // ── Circular timer ──
              const Spacer(),
              Center(
                child: TimerDisplay(
                  remaining: Duration(seconds: _remainingSeconds),
                  total: Duration(seconds: _totalSeconds),
                ),
              ),
              const SizedBox(height: 24),

              // ── Sound panel (only during active session) ──
              if (!_isCompleted && widget.soundType != null)
                FocusSoundPanel(initialSoundType: widget.soundType!),

              const Spacer(),

              // ── Controls ──
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: !_isCompleted
                    ? TimerControls(
                        isRunning: _isRunning,
                        isPaused: _isPaused,
                        onStart: () {},
                        onPause: _pauseTimer,
                        onResume: _resumeTimer,
                        onCancel: _showCancelDialog,
                      )
                    : Center(
                        child: FilledButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.check),
                          label: const Text('返回'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _focusPrimary,
                            minimumSize: const Size(200, 48),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
