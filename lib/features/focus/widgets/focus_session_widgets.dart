part of '../pages/focus_session_page.dart';

class _PortraitSession extends StatelessWidget {
  const _PortraitSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
    required this.onSoundChanged,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final ValueChanged<String?> onSoundChanged;

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
              _SessionTopBar(title: '', onBack: onCancel, centered: true),
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
                  roundLabel:
                      '第 ${cycleState.currentRound} / ${cycleState.totalRounds} 轮',
                  catAsset: FocusAssets.catForCycle(cycleState),
                ),
              ),
              const SizedBox(height: 18),
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
              FocusSoundPanel(
                initialSoundType: cycleState.soundType ?? 'none',
                compact: true,
                dark: true,
                onSoundChanged: onSoundChanged,
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
    required this.onSoundChanged,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final ValueChanged<String?> onSoundChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height;
    final width = size.width;
    // 横屏时根据高度和宽度综合计算，更保守
    final timerSize = math.min(math.min(height * 0.5, width * 0.28), 380.0);
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
                      // 左侧：计时器区域（固定）
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
                              remaining: Duration(
                                seconds: cycleState.remainingSeconds,
                              ),
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
                      // 右侧：控制区域（可滚动）
                      Expanded(
                        flex: 10,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                              const SizedBox(height: 18),
                              FocusSoundPanel(
                                initialSoundType:
                                    cycleState.soundType ?? 'none',
                                compact: true,
                                dark: true,
                                onSoundChanged: onSoundChanged,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _EncourageNote(compact: true),
                                  ),
                                  Image.asset(
                                    FocusAssets.catForCycle(cycleState),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ],
                          ),
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

class _CompactLandscapeSession extends StatelessWidget {
  const _CompactLandscapeSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
    required this.onSoundChanged,
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final ValueChanged<String?> onSoundChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final availableHeight =
        size.height - MediaQuery.paddingOf(context).vertical - 22;
    final timerSize = math.min(
      math.max(116.0, availableHeight * 0.46),
      math.min(size.width * 0.27, 220.0),
    );
    final leftWidth = math.max(246.0, size.width * 0.36);
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
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Row(
              children: [
                SizedBox(
                  width: leftWidth,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SessionTopBar(
                                title: '',
                                onBack: onCancel,
                                centered: true,
                                compact: true,
                              ),
                              const SizedBox(height: 5),
                              _RoundStepper(
                                cycleState: cycleState,
                                dark: true,
                                compact: true,
                              ),
                              const SizedBox(height: 4),
                              _SessionTitleBlock(
                                cycleState: cycleState,
                                centered: true,
                                compact: true,
                              ),
                              const SizedBox(height: 4),
                              TimerDisplay(
                                remaining: Duration(
                                  seconds: cycleState.remainingSeconds,
                                ),
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
                      );
                    },
                  ),
                ),
                SizedBox(width: size.width < 760 ? 10 : 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        child: ListView(
                          padding: EdgeInsets.only(
                            top: 2,
                            bottom: MediaQuery.paddingOf(context).bottom + 8,
                          ),
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
                            ),
                            const SizedBox(height: 10),
                            FocusSoundPanel(
                              initialSoundType: cycleState.soundType ?? 'none',
                              compact: true,
                              dark: true,
                              onSoundChanged: onSoundChanged,
                            ),
                            const SizedBox(height: 10),
                            _NextPhaseCard(
                              cycleState: cycleState,
                              compact: true,
                            ),
                            if (constraints.maxHeight > 380) ...[
                              const SizedBox(height: 10),
                              _EncourageNote(compact: true),
                            ],
                          ],
                        ),
                      );
                    },
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
        _RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
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

class _RoundStepper extends StatelessWidget {
  const _RoundStepper({
    required this.cycleState,
    required this.dark,
    this.compact = false,
  });

  final FocusCycleState cycleState;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cycleState.totalRounds, (index) {
        final round = index + 1;
        final active = round == cycleState.currentRound && !cycleState.isBreak;
        final done =
            round < cycleState.currentRound ||
            (round == cycleState.currentRound && cycleState.isBreak);
        return Row(
          children: [
            Container(
              width: active ? (compact ? 34 : 46) : (compact ? 30 : 40),
              height: active ? (compact ? 34 : 46) : (compact ? 30 : 40),
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
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (round != cycleState.totalRounds)
              Container(
                width: compact ? 18 : 34,
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
  });

  final FocusCycleState cycleState;
  final bool isCycleDone;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipBreak;
  final VoidCallback onReturn;
  final bool compact;

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
        ),
        SizedBox(width: compact ? 16 : 28),
        _GlowButton(
          icon: cycleState.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: cycleState.isRunning ? '暂停专注' : '继续专注',
          onTap: cycleState.isRunning ? onPause : onResume,
          large: true,
          compact: compact,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: icon,
          onTap: onTap,
          danger: danger,
          size: compact ? 42 : 54,
        ),
        SizedBox(height: compact ? 5 : 8),
        Text(
          label,
          style: TextStyle(
            color: _sessionCream,
            fontSize: compact ? 12 : 15,
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
    this.size = 54,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final double size;

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
              ? colors.danger.withValues(alpha: 0.18)
              : colors.surfaceVariant.withValues(alpha: 0.34),
          border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        ),
        child: Icon(icon, color: colors.textPrimary, size: size * 0.48),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool large;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final buttonSize = compact ? 58.0 : (large ? 86.0 : 64.0);
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
                  blurRadius: 24,
                  spreadRadius: 4,
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
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.focus,
            fontSize: compact ? 13 : 16,
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
    final colors = context.growthColors;
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
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border, width: 1.2),
      ),
      child: Row(
        children: [
          Image.asset(
            cycleState.isBreak
                ? FocusAssets.iconPomodoro
                : FocusAssets.breakCup,
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
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextTime,
                  style: TextStyle(
                    color: colors.focus,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
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
    final colors = context.growthColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 22,
        vertical: compact ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border.withValues(alpha: 0.42)),
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
                color: colors.textPrimary,
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
