part of '../pages/focus_session_page.dart';

class _PortraitSession extends StatelessWidget {
  const _PortraitSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.soundPanelOpen,
    required this.controlsVisible,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
    required this.onSoundChanged,
    required this.onSoundPanelToggle,
    required this.onSoundPanelClose,
    required this.onToggleControls,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final bool soundPanelOpen;
  final bool controlsVisible;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final ValueChanged<String?> onSoundChanged;
  final VoidCallback onSoundPanelToggle;
  final VoidCallback onSoundPanelClose;
  final VoidCallback onToggleControls;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final safeHeight = size.height - padding.vertical;
    final timerSize = math.min(
      size.width * 0.88,
      math.min(safeHeight * 0.52, 420.0),
    );
    final stageHeight = 8 + timerSize;
    final stageTop = (padding.top + safeHeight * 0.38 - stageHeight / 2)
        .clamp(padding.top + 48.0, size.height - stageHeight - 200.0);

    return Stack(
      children: [
        // 1. 桌面前景图
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Image.asset(FocusAssets.deskPortrait, fit: BoxFit.fitWidth),
        ),

        // 2. 半透明返回按钮
        Positioned(
          top: padding.top + 8,
          left: 0, right: 0,
          child: Center(child: _SmallBackButton(onTap: onCancel)),
        ),

        // 3. 计时器主体
        Positioned(
          top: stageTop,
          left: 0, right: 0,
          child: _CenteredTimerStage(
            cycleState: cycleState,
            timerSize: timerSize,
            showCat: true,
            showTitle: controlsVisible,
          ),
        ),

        // 4. 全屏手势层（在计时器下面，控制按钮上面）
        if (!controlsVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleControls,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

        // 5. 控制按钮（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 0, right: 0,
          top: controlsVisible
              ? stageTop + stageHeight + 20
              : size.height + 100,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: controlsVisible ? 1.0 : 0.0,
            child: _SessionControls(
              cycleState: cycleState,
              isCycleDone: isCycleDone,
              onCancel: onCancel,
              onPause: onPause,
              onResume: onResume,
              onSkipBreak: onSkipBreak,
              onReturn: onReturn,
              compact: false,
              subdued: false,
            ),
          ),
        ),

        // 6. 底部栏（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 42, right: 42,
          bottom: controlsVisible
              ? padding.bottom + 18
              : -120,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: controlsVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !controlsVisible,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NextPhasePill(cycleState: cycleState, compact: true),
                  const SizedBox(height: 10),
                  _FocusSoundDock(
                    initialSoundType: cycleState.soundType ?? 'none',
                    onTap: onSoundPanelToggle,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 7. 声音面板
        if (soundPanelOpen)
          _FocusSoundOverlay(
            landscape: false,
            initialSoundType: cycleState.soundType ?? 'none',
            onClose: onSoundPanelClose,
            onSoundChanged: onSoundChanged,
          ),
      ],
    );
  }
}

class _LandscapeSession extends StatelessWidget {
  const _LandscapeSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.soundPanelOpen,
    required this.controlsVisible,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
    required this.onSoundChanged,
    required this.onSoundPanelToggle,
    required this.onSoundPanelClose,
    required this.onToggleControls,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final bool soundPanelOpen;
  final bool controlsVisible;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final ValueChanged<String?> onSoundChanged;
  final VoidCallback onSoundPanelToggle;
  final VoidCallback onSoundPanelClose;
  final VoidCallback onToggleControls;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final safeHeight = size.height - padding.vertical;
    final timerSize = math.min(
      math.min(safeHeight * 0.82, size.width * 0.48),
      640.0,
    );
    final stageTop = padding.top + safeHeight * 0.50 - timerSize / 2 - 8;

    return Stack(
      children: [
        // 1. 桌面前景图
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Image.asset(FocusAssets.deskLandscape, fit: BoxFit.fitWidth),
        ),

        // 2. 半透明返回按钮（左对齐）
        Positioned(
          top: padding.top + 12, left: 30,
          child: _SmallBackButton(onTap: onCancel),
        ),

        // 3. 计时器主体（居中偏左）
        Positioned(
          top: stageTop,
          left: size.width * 0.05,
          width: size.width * 0.55,
          child: _CenteredTimerStage(
            cycleState: cycleState,
            timerSize: timerSize,
            showCat: true,
            showTitle: controlsVisible,
          ),
        ),

        // 4. 全屏手势层
        if (!controlsVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleControls,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

        // 5. 右侧面板（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          right: controlsVisible ? 38 : -400,
          top: padding.top + safeHeight * 0.31,
          width: math.min(360.0, size.width * 0.28),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: controlsVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !controlsVisible,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SessionControls(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    onCancel: onCancel,
                    onPause: onPause,
                    onResume: onResume,
                    onSkipBreak: onSkipBreak,
                    onReturn: onReturn,
                    subdued: true,
                  ),
                  const SizedBox(height: 24),
                  _NextPhasePill(cycleState: cycleState),
                  const SizedBox(height: 12),
                  _FocusSoundDock(
                    initialSoundType: cycleState.soundType ?? 'none',
                    onTap: onSoundPanelToggle,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 6. 声音面板
        if (soundPanelOpen)
          _FocusSoundOverlay(
            landscape: true,
            initialSoundType: cycleState.soundType ?? 'none',
            onClose: onSoundPanelClose,
            onSoundChanged: onSoundChanged,
          ),
      ],
    );
  }
}

class _CompactLandscapeSession extends StatelessWidget {
  const _CompactLandscapeSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.soundPanelOpen,
    required this.controlsVisible,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
    required this.onSoundChanged,
    required this.onSoundPanelToggle,
    required this.onSoundPanelClose,
    required this.onToggleControls,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final bool soundPanelOpen;
  final bool controlsVisible;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final ValueChanged<String?> onSoundChanged;
  final VoidCallback onSoundPanelToggle;
  final VoidCallback onSoundPanelClose;
  final VoidCallback onToggleControls;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final safeHeight = size.height - padding.vertical;
    final timerSize = math.min(
      math.min(safeHeight * 0.82, size.width * 0.48),
      640.0,
    );
    final stageTop = padding.top + safeHeight * 0.50 - timerSize / 2 - 8;

    return Stack(
      children: [
        // 1. 桌面前景图
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Image.asset(FocusAssets.deskLandscape, fit: BoxFit.fitWidth),
        ),

        // 2. 半透明返回按钮（左对齐）
        Positioned(
          top: padding.top + 12, left: 30,
          child: _SmallBackButton(onTap: onCancel),
        ),

        // 3. 计时器主体（居中偏左）
        Positioned(
          top: stageTop,
          left: size.width * 0.05,
          width: size.width * 0.55,
          child: _CenteredTimerStage(
            cycleState: cycleState,
            timerSize: timerSize,
            showCat: true,
            showTitle: controlsVisible,
            compact: true,
          ),
        ),

        // 4. 全屏手势层
        if (!controlsVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleControls,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

        // 5. 右侧面板（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          right: controlsVisible ? 38 : -400,
          top: padding.top + safeHeight * 0.31,
          width: math.min(360.0, size.width * 0.28),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: controlsVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !controlsVisible,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SessionControls(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    onCancel: onCancel,
                    onPause: onPause,
                    onResume: onResume,
                    onSkipBreak: onSkipBreak,
                    onReturn: onReturn,
                    compact: true,
                    subdued: true,
                  ),
                  const SizedBox(height: 24),
                  _NextPhasePill(cycleState: cycleState, compact: true),
                  const SizedBox(height: 12),
                  _FocusSoundDock(
                    initialSoundType: cycleState.soundType ?? 'none',
                    onTap: onSoundPanelToggle,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 6. 声音面板
        if (soundPanelOpen)
          _FocusSoundOverlay(
            landscape: true,
            initialSoundType: cycleState.soundType ?? 'none',
            onClose: onSoundPanelClose,
            onSoundChanged: onSoundChanged,
            compact: true,
          ),
      ],
    );
  }
}

class _SmallBackButton extends StatelessWidget {
  const _SmallBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _sessionCream.withValues(alpha: 0.15),
          border: Border.all(color: _sessionCream.withValues(alpha: 0.25)),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 20,
          color: _sessionCream.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _CenteredTimerStage extends StatelessWidget {
  const _CenteredTimerStage({
    required this.cycleState,
    required this.timerSize,
    required this.showCat,
    required this.showTitle,
    this.compact = false,
  });

  final FocusCycleState cycleState;
  final double timerSize;
  final bool showCat;
  final bool showTitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('focus_timer_stage'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundDots(cycleState: cycleState, compact: compact),
        SizedBox(height: compact ? 6 : 8),
        TimerDisplay(
          remaining: Duration(seconds: cycleState.remainingSeconds),
          total: _totalFor(cycleState),
          isBreak: cycleState.isBreak,
          size: timerSize,
          dark: true,
          roundLabel: '第 ${cycleState.currentRound} / ${cycleState.totalRounds} 轮',
          showCat: showCat,
          catAsset: FocusAssets.catForCycle(cycleState),
          title: cycleState.isBreak
              ? (cycleState.phase == FocusPhase.longBreak ? '长休息' : '短休息')
              : (cycleState.title.isEmpty
                  ? '${focusTypeLabel(cycleState.type)}专注'
                  : cycleState.title),
          subject: cycleState.subject.isNotEmpty ? cycleState.subject : null,
          showTitle: showTitle,
        ),
      ],
    );
  }
}

class _RoundDots extends StatelessWidget {
  const _RoundDots({required this.cycleState, required this.compact});

  final FocusCycleState cycleState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('focus_round_dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cycleState.totalRounds, (index) {
        final round = index + 1;
        final active = round == cycleState.currentRound;
        final done =
            round < cycleState.currentRound ||
            (round == cycleState.currentRound && cycleState.isBreak);
        final size = active ? (compact ? 8.0 : 9.0) : (compact ? 6.0 : 7.0);
        final color = active
            ? _sessionMint.withValues(alpha: 0.95)
            : done
            ? _sessionCream.withValues(alpha: 0.72)
            : _sessionCream.withValues(alpha: 0.34);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: active
                ? Border.all(color: _sessionCream.withValues(alpha: 0.68))
                : null,
          ),
        );
      }),
    );
  }
}

class _FocusSoundDock extends ConsumerWidget {
  const _FocusSoundDock({
    required this.initialSoundType,
    required this.onTap,
    this.compact = false,
  });

  final String initialSoundType;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final audioState = ref.watch(focusAudioStateProvider);
    final musicState = ref.watch(musicPlayerProvider);
    final selected = initialSoundType.isEmpty ? 'none' : initialSoundType;
    final current = selected == 'none'
        ? (audioState.currentSoundType ?? selected)
        : selected;
    final isMusic = current == 'music';
    final volume = isMusic ? musicState.volume : audioState.volume;
    final title = _focusSoundDockTitle(current, musicState.currentTrack?.title);
    final subtitle = _focusSoundDockSubtitle(current, volume, isMusic);

    return Semantics(
      button: true,
      label: '展开专注声音',
      child: GestureDetector(
        key: const ValueKey('focus_sound_dock'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: compact ? 46 : 50,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border.withValues(alpha: 0.54)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_rounded,
                color: colors.focus.withValues(alpha: 0.92),
                size: compact ? 17 : 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: compact ? 12 : 13,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10.5,
                          height: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              compact
                  ? Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.focus,
                        fontSize: 11.5,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      Icons.tune_rounded,
                      color: colors.focus.withValues(alpha: 0.88),
                      size: 17,
                    ),
              if (!compact) const SizedBox(width: 2),
              if (!compact)
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: colors.textTertiary,
                  size: 17,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _focusSoundDockTitle(String current, String? currentTrackTitle) {
  if (current == 'music') return currentTrackTitle ?? '本地音乐';
  if (current == 'none') return '专注声音';
  String? label;
  for (final option in focusSoundOptions) {
    if (option.value == current) {
      label = option.label;
      break;
    }
  }
  return label ?? '白噪音';
}

String _focusSoundDockSubtitle(String current, double volume, bool isMusic) {
  if (current == 'none') return '安静';
  final percent = '${(volume * 100).round()}%';
  if (isMusic) return '本地音乐 · $percent';
  return percent;
}

class _FocusSoundOverlay extends StatelessWidget {
  const _FocusSoundOverlay({
    required this.landscape,
    required this.initialSoundType,
    required this.onClose,
    required this.onSoundChanged,
    this.compact = false,
  });

  final bool landscape;
  final String initialSoundType;
  final VoidCallback onClose;
  final ValueChanged<String?> onSoundChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxHeight = size.height * (landscape ? 0.70 : 0.42);
    final panel = SingleChildScrollView(
      child: FocusSoundPanel(
        initialSoundType: initialSoundType,
        compact: true,
        dark: true,
        onSoundChanged: onSoundChanged,
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('focus_sound_overlay_barrier'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        if (landscape)
          Positioned(
            key: const ValueKey('focus_sound_drawer'),
            top: math.max(padding.top + 74, (size.height - maxHeight) / 2),
            right: compact ? 18 : 28,
            width: compact
                ? math.min(340, size.width * 0.42).toDouble()
                : math.min(380, size.width * 0.28).toDouble(),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: GestureDetector(onTap: () {}, child: panel),
            ),
          )
        else
          Positioned(
            key: const ValueKey('focus_sound_sheet'),
            left: 14,
            right: 14,
            bottom: padding.bottom + 10,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: GestureDetector(onTap: () {}, child: panel),
            ),
          ),
      ],
    );
  }
}

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({
    required this.title,
    required this.onBack,
    required this.centered,
    this.compact = false,
  });

  final String title;
  final VoidCallback onBack;
  final bool centered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
          size: compact ? 44 : 48,
          subtle: true,
        ),
        if (centered) const Spacer(),
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: centered ? 0 : 18),
            child: Text(
              title,
              style: TextStyle(
                color: _sessionCream,
                fontSize: compact ? 22 : 30,
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

class _SessionTitleBlock extends StatelessWidget {
  const _SessionTitleBlock({
    required this.cycleState,
    required this.centered,
    this.compact = false,
  });

  final FocusCycleState cycleState;
  final bool centered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = cycleState.isBreak
        ? (cycleState.phase == FocusPhase.longBreak ? '长休息' : '短休息')
        : (cycleState.title.isEmpty
              ? '${focusTypeLabel(cycleState.type)}专注'
              : cycleState.title);
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _sessionCream,
            fontSize: compact ? 20 : 28,
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
              style: TextStyle(
                color: _sessionMint,
                fontSize: compact ? 12 : 15,
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
    this.compact = false,
    this.subdued = false,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final bool compact;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    if (isCycleDone) {
      return Center(
        child: _GlowButton(
          icon: Icons.check_rounded,
          label: '返回',
          onTap: onReturn,
          large: true,
          compact: compact,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlColumn(
          icon: cycleState.isBreak
              ? Icons.skip_next_rounded
              : Icons.close_rounded,
          label: cycleState.isBreak ? '跳过' : '取消',
          onTap: cycleState.isBreak ? onSkipBreak : onCancel,
          danger: !cycleState.isBreak,
          compact: compact,
          subdued: subdued,
        ),
        SizedBox(width: compact ? 18 : 30),
        _GlowButton(
          icon: cycleState.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: cycleState.isRunning ? '暂停专注' : '继续专注',
          onTap: cycleState.isRunning ? onPause : onResume,
          large: true,
          compact: compact,
          subdued: subdued,
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
    required this.compact,
    required this.subdued,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool compact;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: icon,
          onTap: onTap,
          danger: danger,
          size: compact ? 44 : 52,
          subtle: subdued,
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            color: _sessionCream.withValues(alpha: subdued ? 0.72 : 0.92),
            fontSize: compact ? 11 : 13,
            height: 1.0,
            fontWeight: FontWeight.w700,
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
    this.size = 54,
    this.subtle = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final double size;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: danger
              ? colors.danger.withValues(alpha: subtle ? 0.14 : 0.18)
              : colors.surfaceVariant.withValues(alpha: subtle ? 0.22 : 0.34),
          border: Border.all(
            color: colors.border.withValues(alpha: subtle ? 0.48 : 0.72),
          ),
        ),
        child: Icon(
          icon,
          color: colors.textPrimary.withValues(alpha: subtle ? 0.86 : 1),
          size: size * 0.46,
        ),
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
    this.compact = false,
    this.subdued = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool large;
  final bool compact;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final buttonSize = compact ? 64.0 : (large ? 88.0 : 64.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: colors.focus.withValues(alpha: 0.90),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.focus.withValues(alpha: 0.48),
                  blurRadius: subdued ? 18 : 24,
                  spreadRadius: subdued ? 2 : 4,
                ),
              ],
              border: Border.all(color: colors.card.withValues(alpha: 0.76)),
            ),
            child: Icon(
              icon,
              color: colors.textOnAccent,
              size: compact
                  ? 30
                  : large
                  ? 44
                  : 32,
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 7),
        Text(
          label,
          style: TextStyle(
            color: colors.focus.withValues(alpha: subdued ? 0.78 : 1),
            fontSize: compact ? 12 : 14,
            height: 1.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NextPhasePill extends StatelessWidget {
  const _NextPhasePill({required this.cycleState, this.compact = false});

  final FocusCycleState cycleState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final nextPhase = cycleState.isBreak
        ? '专注'
        : cycleState.isLastRound
        ? '长休息'
        : '短休息';
    final nextTime = cycleState.isBreak
        ? '${cycleState.focusSeconds ~/ 60}:00'
        : cycleState.isLastRound
        ? '${cycleState.longBreakSeconds ~/ 60}:00'
        : '${cycleState.shortBreakSeconds ~/ 60}:00';
    return Container(
      key: const ValueKey('next_phase_pill'),
      height: compact ? 50 : 54,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: 5),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withValues(alpha: 0.54)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            cycleState.isBreak
                ? FocusAssets.iconPomodoro
                : FocusAssets.breakCup,
            width: compact ? 30 : 33,
            height: compact ? 30 : 33,
          ),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '下一阶段 · $nextPhase',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: compact ? 11 : 12,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  nextTime,
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.focus,
                    fontSize: compact ? 16.5 : 18,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
            size: compact ? 17 : 19,
          ),
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
    final colors = context.growthColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: math.min(MediaQuery.sizeOf(context).width - 48, 390),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.20),
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
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
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
                        foregroundColor: colors.danger,
                        side: BorderSide(
                          color: colors.danger.withValues(alpha: 0.32),
                        ),
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
                      backgroundColor: colors.focus,
                      foregroundColor: colors.textOnAccent,
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
