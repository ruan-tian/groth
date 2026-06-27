part of '../pages/focus_session_page.dart';

class _FocusSessionBackground extends StatelessWidget {
  const _FocusSessionBackground({
    required this.asset,
    required this.tone,
    required this.material,
    required this.blurLevel,
    required this.dimLevel,
    required this.usingCustomTheme,
  });

  final String asset;
  final _FocusBackdropTone tone;
  final _FocusBackdropMaterial material;
  final int blurLevel;
  final int dimLevel;
  final bool usingCustomTheme;

  @override
  Widget build(BuildContext context) {
    final sideColor = tone.resolve(usingCustomTheme: usingCustomTheme);
    final blurSigma = _focusBackdropBlurSigma(blurLevel);
    final mainBlurSigma = blurLevel.clamp(0, 3) * 1.6;
    final dimAlpha = _focusBackdropDimAlpha(dimLevel, tone);
    final blurEnabled = blurSigma > 0;
    final sideTintAlpha = switch (material) {
      _FocusBackdropMaterial.solid => 0.18,
      _FocusBackdropMaterial.frosted => 0.10,
      _FocusBackdropMaterial.liquid => 0.05,
      _FocusBackdropMaterial.crystal => 0.07,
      _FocusBackdropMaterial.prism => 0.05,
      _FocusBackdropMaterial.pearl => 0.08,
      _FocusBackdropMaterial.glow => 0.06,
      _FocusBackdropMaterial.dusk => 0.16,
      _FocusBackdropMaterial.noir => 0.18,
      _FocusBackdropMaterial.silk => 0.12,
    };
    final mainFit = BoxFit.cover;
    final mainBlur = mainBlurSigma;

    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      color: sideColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (blurEnabled)
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.slow),
              switchInCurve: AppMotion.standard,
              switchOutCurve: Curves.easeOutCubic,
              layoutBuilder: _focusFullScreenSwitcherLayout,
              child: SizedBox.expand(
                key: ValueKey('blur-$asset'),
                child: ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Transform.scale(
                      scale: 1.10 + blurLevel.clamp(0, 3) * 0.04,
                      child: Image.asset(
                        asset,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    sideColor.withValues(alpha: 0.92),
                    sideColor,
                    Color.lerp(sideColor, Colors.black, 0.10)!,
                  ],
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.slow),
            switchInCurve: AppMotion.standard,
            switchOutCurve: Curves.easeOutCubic,
            layoutBuilder: _focusFullScreenSwitcherLayout,
            child: SizedBox.expand(
              key: ValueKey('main-$asset-$blurLevel'),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: mainBlur,
                  sigmaY: mainBlur,
                ),
                child: Image.asset(
                  asset,
                  width: double.infinity,
                  height: double.infinity,
                  fit: mainFit,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          _FocusBackdropMaterialOverlay(
            tone: tone,
            material: material,
            sideColor: sideColor,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: sideTintAlpha),
            ),
          ),
          if (dimAlpha > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: dimAlpha),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _focusFullScreenSwitcherLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) {
  return Stack(
    fit: StackFit.expand,
    children: [...previousChildren, ?currentChild],
  );
}

class _FocusBackdropMaterialOverlay extends StatelessWidget {
  const _FocusBackdropMaterialOverlay({
    required this.tone,
    required this.material,
    required this.sideColor,
  });

  final _FocusBackdropTone tone;
  final _FocusBackdropMaterial material;
  final Color sideColor;

  @override
  Widget build(BuildContext context) {
    final accent = tone.accent;
    switch (material) {
      case _FocusBackdropMaterial.solid:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  sideColor,
                  Colors.white,
                  0.10,
                )!.withValues(alpha: 0.20),
                sideColor.withValues(alpha: 0.24),
                Color.lerp(
                  sideColor,
                  Colors.black,
                  0.12,
                )!.withValues(alpha: 0.24),
              ],
            ),
          ),
        );
      case _FocusBackdropMaterial.frosted:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.08),
              ],
              stops: const [0, 0.52, 1],
            ),
          ),
        );
      case _FocusBackdropMaterial.liquid:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    accent.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                  stops: const [0, 0.54, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.46, -0.70),
                  radius: 0.78,
                  colors: [
                    Colors.white.withValues(alpha: 0.34),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.84, 0.72),
                  radius: 0.72,
                  colors: [accent.withValues(alpha: 0.20), Colors.transparent],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.crystal:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.24),
                    accent.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.10),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.95, -0.28),
                  end: const Alignment(0.78, 0.46),
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.28, 0.50, 0.72],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.prism:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Color.lerp(
                      accent,
                      const Color(0xFF77BDE4),
                      0.38,
                    )!.withValues(alpha: 0.10),
                    const Color(0xFFFFCFA3).withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                  stops: const [0, 0.36, 0.68, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.90, -0.72),
                  end: const Alignment(0.86, 0.58),
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.18),
                    Color.lerp(
                      accent,
                      Colors.white,
                      0.52,
                    )!.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.20, 0.43, 0.54, 0.78],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.pearl:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.24),
                    const Color(0xFFF2EADF).withValues(alpha: 0.10),
                    accent.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.06),
                  ],
                  stops: const [0, 0.42, 0.76, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.38, -0.52),
                  radius: 0.82,
                  colors: [
                    Colors.white.withValues(alpha: 0.26),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.44, 1],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.glow:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.07),
                    Colors.black.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.68),
                  radius: 0.86,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.dusk:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF06151B).withValues(alpha: 0.32),
                    accent.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.92,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.noir:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020408).withValues(alpha: 0.30),
                    Color.lerp(
                      accent,
                      const Color(0xFF101823),
                      0.76,
                    )!.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.40),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.92,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0.45, 1],
                ),
              ),
            ),
          ],
        );
      case _FocusBackdropMaterial.silk:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                accent.withValues(alpha: 0.06),
                Colors.black.withValues(alpha: 0.12),
              ],
            ),
          ),
        );
    }
  }
}

class _PortraitSession extends StatelessWidget {
  const _PortraitSession({
    required this.cycleState,
    required this.isCycleDone,
    required this.soundPanelOpen,
    required this.controlsVisible,
    required this.locked,
    required this.selectedTheme,
    required this.usingCustomTheme,
    required this.backgroundTone,
    required this.glassOpacityLevel,
    required this.onToggleLock,
    required this.onOpenThemeSheet,
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
  final bool locked;
  final SceneryTheme? selectedTheme;
  final bool usingCustomTheme;
  final _FocusBackdropTone backgroundTone;
  final int glassOpacityLevel;
  final VoidCallback onToggleLock;
  final VoidCallback onOpenThemeSheet;
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
    final stageTop = (padding.top + safeHeight * 0.38 - stageHeight / 2).clamp(
      padding.top + 48.0,
      size.height - stageHeight - 200.0,
    );
    final accent = backgroundTone.accent;
    final showTopChrome = controlsVisible;
    final showUnlockedChrome = controlsVisible && !locked;

    return Stack(
      children: [
        // 1. Full-screen gesture layer. It stays below top controls so lock and
        // theme buttons remain tappable.
        _FocusSessionTapLayer(
          size: size,
          controlsVisible: controlsVisible,
          locked: locked,
          onToggleControls: onToggleControls,
        ),

        if (!usingCustomTheme)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(FocusAssets.deskPortrait, fit: BoxFit.fitWidth),
          ),

        _TopSessionChrome(
          top: padding.top + 8,
          left: 20,
          right: 20,
          centeredBack: false,
          showActions: showUnlockedChrome,
          showLock: showTopChrome,
          locked: locked,
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
          selectedTheme: selectedTheme,
          onCancel: onCancel,
          onOpenThemeSheet: onOpenThemeSheet,
          onToggleLock: onToggleLock,
        ),

        // 3. 计时器主体
        Positioned(
          top: stageTop,
          left: 0,
          right: 0,
          child: _CenteredTimerStage(
            cycleState: cycleState,
            timerSize: timerSize,
            showCat: true,
            showTitle: controlsVisible,
            accent: accent,
            glassOpacityLevel: glassOpacityLevel,
          ),
        ),

        // 5. 控制按钮（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          top: showUnlockedChrome
              ? stageTop + stageHeight + 20
              : size.height + 100,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: showUnlockedChrome ? 1.0 : 0.0,
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
              accent: accent,
              glassOpacityLevel: glassOpacityLevel,
            ),
          ),
        ),

        // 6. 底部栏（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 42,
          right: 42,
          bottom: showUnlockedChrome ? padding.bottom + 18 : -120,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: showUnlockedChrome ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showUnlockedChrome,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NextPhasePill(
                    cycleState: cycleState,
                    compact: true,
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
                  ),
                  const SizedBox(height: 10),
                  _FocusSoundDock(
                    initialSoundType: cycleState.soundType ?? 'none',
                    onTap: onSoundPanelToggle,
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
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
    required this.locked,
    required this.selectedTheme,
    required this.usingCustomTheme,
    required this.backgroundTone,
    required this.glassOpacityLevel,
    required this.onToggleLock,
    required this.onOpenThemeSheet,
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
  final bool locked;
  final SceneryTheme? selectedTheme;
  final bool usingCustomTheme;
  final _FocusBackdropTone backgroundTone;
  final int glassOpacityLevel;
  final VoidCallback onToggleLock;
  final VoidCallback onOpenThemeSheet;
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
    final accent = backgroundTone.accent;
    final showTopChrome = controlsVisible;
    final showUnlockedChrome = controlsVisible && !locked;

    return Stack(
      children: [
        // 1. Full-screen gesture layer. It stays below top controls so lock and
        // theme buttons remain tappable.
        _FocusSessionTapLayer(
          size: size,
          controlsVisible: controlsVisible,
          locked: locked,
          onToggleControls: onToggleControls,
        ),

        if (!usingCustomTheme)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(FocusAssets.deskLandscape, fit: BoxFit.fitWidth),
          ),

        _TopSessionChrome(
          top: padding.top + 12,
          left: 30,
          right: 30,
          centeredBack: false,
          showActions: showUnlockedChrome,
          showLock: showTopChrome,
          locked: locked,
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
          selectedTheme: selectedTheme,
          onCancel: onCancel,
          onOpenThemeSheet: onOpenThemeSheet,
          onToggleLock: onToggleLock,
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
            accent: accent,
            glassOpacityLevel: glassOpacityLevel,
          ),
        ),

        // 5. 右侧面板（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          right: showUnlockedChrome ? 38 : -400,
          top: padding.top + safeHeight * 0.31,
          width: math.min(360.0, size.width * 0.28),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: showUnlockedChrome ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showUnlockedChrome,
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
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
                  ),
                  const SizedBox(height: 24),
                  _NextPhasePill(
                    cycleState: cycleState,
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
                  ),
                  const SizedBox(height: 12),
                  _FocusSoundDock(
                    initialSoundType: cycleState.soundType ?? 'none',
                    onTap: onSoundPanelToggle,
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
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
    required this.locked,
    required this.selectedTheme,
    required this.usingCustomTheme,
    required this.backgroundTone,
    required this.glassOpacityLevel,
    required this.onToggleLock,
    required this.onOpenThemeSheet,
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
  final bool locked;
  final SceneryTheme? selectedTheme;
  final bool usingCustomTheme;
  final _FocusBackdropTone backgroundTone;
  final int glassOpacityLevel;
  final VoidCallback onToggleLock;
  final VoidCallback onOpenThemeSheet;
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
    final accent = backgroundTone.accent;
    final showTopChrome = controlsVisible;
    final showUnlockedChrome = controlsVisible && !locked;

    return Stack(
      children: [
        // 1. Full-screen gesture layer. It stays below top controls so lock and
        // theme buttons remain tappable.
        _FocusSessionTapLayer(
          size: size,
          controlsVisible: controlsVisible,
          locked: locked,
          onToggleControls: onToggleControls,
        ),

        if (!usingCustomTheme)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(FocusAssets.deskLandscape, fit: BoxFit.fitWidth),
          ),

        _TopSessionChrome(
          top: padding.top + 12,
          left: 30,
          right: 30,
          centeredBack: false,
          showActions: showUnlockedChrome,
          showLock: showTopChrome,
          locked: locked,
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
          selectedTheme: selectedTheme,
          onCancel: onCancel,
          onOpenThemeSheet: onOpenThemeSheet,
          onToggleLock: onToggleLock,
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
            accent: accent,
            glassOpacityLevel: glassOpacityLevel,
          ),
        ),

        // 5. 右侧面板（点击显示/隐藏，带动画）
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          right: showUnlockedChrome ? 38 : -400,
          top: padding.top + safeHeight * 0.31,
          width: math.min(360.0, size.width * 0.28),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: showUnlockedChrome ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !showUnlockedChrome,
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
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
                  ),
                  const SizedBox(height: 24),
                  _NextPhasePill(
                    cycleState: cycleState,
                    compact: true,
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
                  ),
                  const SizedBox(height: 12),
                  _FocusSoundDock(
                    initialSoundType: cycleState.soundType ?? 'none',
                    onTap: onSoundPanelToggle,
                    compact: true,
                    accent: accent,
                    glassOpacityLevel: glassOpacityLevel,
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

class _FocusSessionTapLayer extends StatelessWidget {
  const _FocusSessionTapLayer({
    required this.size,
    required this.controlsVisible,
    required this.locked,
    required this.onToggleControls,
  });

  final Size size;
  final bool controlsVisible;
  final bool locked;
  final VoidCallback onToggleControls;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          if (_shouldToggle(details.localPosition)) {
            onToggleControls();
          }
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  bool _shouldToggle(Offset position) {
    if (locked) return !controlsVisible;
    if (!controlsVisible) return true;

    final edgeX = size.width * 0.16;
    final edgeY = size.height * 0.16;
    final nearHorizontalEdge =
        position.dx <= edgeX || position.dx >= size.width - edgeX;
    final nearVerticalEdge =
        position.dy <= edgeY || position.dy >= size.height - edgeY;
    return nearHorizontalEdge || nearVerticalEdge;
  }
}

double _focusGlassOpacity(
  int level, {
  required double minimum,
  required double maximum,
}) {
  final normalized = level.clamp(0, 3);
  final t = switch (normalized) {
    0 => 0.0,
    1 => 0.38,
    2 => 0.68,
    _ => 1.0,
  };
  return minimum + (maximum - minimum) * t;
}

class _TopSessionChrome extends StatelessWidget {
  const _TopSessionChrome({
    required this.top,
    required this.left,
    required this.right,
    required this.centeredBack,
    required this.showActions,
    required this.showLock,
    required this.locked,
    required this.accent,
    required this.glassOpacityLevel,
    required this.selectedTheme,
    required this.onCancel,
    required this.onOpenThemeSheet,
    required this.onToggleLock,
  });

  final double top;
  final double left;
  final double right;
  final bool centeredBack;
  final bool showActions;
  final bool showLock;
  final bool locked;
  final Color accent;
  final int glassOpacityLevel;
  final SceneryTheme? selectedTheme;
  final VoidCallback onCancel;
  final VoidCallback onOpenThemeSheet;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    final visible = showActions || showLock;
    final rightButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showActions) ...[
          _ThemeButton(
            theme: selectedTheme,
            accent: accent,
            glassOpacityLevel: glassOpacityLevel,
            onTap: onOpenThemeSheet,
          ),
          const SizedBox(width: 8),
        ],
        if (showLock)
          _LockButton(
            locked: locked,
            accent: accent,
            glassOpacityLevel: glassOpacityLevel,
            onToggle: onToggleLock,
          ),
      ],
    );

    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: 56,
            child: centeredBack
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showActions)
                        Center(
                          child: _SmallBackButton(
                            accent: accent,
                            glassOpacityLevel: glassOpacityLevel,
                            onTap: onCancel,
                          ),
                        ),
                      Positioned(right: 0, child: rightButtons),
                    ],
                  )
                : Row(
                    children: [
                      if (showActions)
                        _SmallBackButton(
                          accent: accent,
                          glassOpacityLevel: glassOpacityLevel,
                          onTap: onCancel,
                        ),
                      const Spacer(),
                      rightButtons,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SmallBackButton extends StatelessWidget {
  const _SmallBackButton({
    required this.accent,
    required this.glassOpacityLevel,
    required this.onTap,
  });
  final Color accent;
  final int glassOpacityLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: 0.12,
      maximum: 0.28,
    );
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: glassAlpha),
              border: Border.all(
                color: Colors.white.withValues(alpha: glassAlpha + 0.24),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.close_rounded,
              size: 28,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockButton extends StatelessWidget {
  const _LockButton({
    required this.locked,
    required this.accent,
    required this.glassOpacityLevel,
    required this.onToggle,
  });
  final bool locked;
  final Color accent;
  final int glassOpacityLevel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: 0.12,
      maximum: 0.30,
    );
    return GestureDetector(
      onTap: onToggle,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (locked ? accent : Colors.white).withValues(
                alpha: locked ? glassAlpha + 0.12 : glassAlpha,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: locked ? glassAlpha + 0.28 : glassAlpha + 0.24,
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: locked ? 0.24 : 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 23,
              color: locked
                  ? Colors.white.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.theme,
    required this.accent,
    required this.glassOpacityLevel,
    required this.onTap,
  });

  final SceneryTheme? theme;
  final Color accent;
  final int glassOpacityLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = theme?.name ?? '默认书桌';
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: 0.12,
      maximum: 0.28,
    );
    return Tooltip(
      message: '切换皮肤 · $name',
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: glassAlpha),
                border: Border.all(
                  color: Colors.white.withValues(alpha: glassAlpha + 0.24),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.wallpaper_rounded,
                size: 23,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusThemeSheet extends StatelessWidget {
  const _FocusThemeSheet({
    required this.selectedIndex,
    required this.themes,
    required this.backgroundTone,
    required this.backgroundMaterial,
    required this.backgroundBlurLevel,
    required this.backgroundDimLevel,
    required this.glassOpacityLevel,
    required this.onBackgroundToneChanged,
    required this.onBackgroundMaterialChanged,
    required this.onBackgroundBlurLevelChanged,
    required this.onBackgroundDimLevelChanged,
    required this.onGlassOpacityLevelChanged,
  });

  final int? selectedIndex;
  final List<SceneryTheme> themes;
  final _FocusBackdropTone backgroundTone;
  final _FocusBackdropMaterial backgroundMaterial;
  final int backgroundBlurLevel;
  final int backgroundDimLevel;
  final int glassOpacityLevel;
  final ValueChanged<_FocusBackdropTone> onBackgroundToneChanged;
  final ValueChanged<_FocusBackdropMaterial> onBackgroundMaterialChanged;
  final ValueChanged<int> onBackgroundBlurLevelChanged;
  final ValueChanged<int> onBackgroundDimLevelChanged;
  final ValueChanged<int> onGlassOpacityLevelChanged;

  @override
  Widget build(BuildContext context) {
    var currentTone = backgroundTone;
    var currentMaterial = backgroundMaterial;
    var blurLevel = backgroundBlurLevel;
    var dimLevel = backgroundDimLevel;
    var glassLevel = glassOpacityLevel;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        final colors = context.growthColors;
        final size = MediaQuery.sizeOf(context);
        final orientation = MediaQuery.orientationOf(context);
        final columns = orientation == Orientation.landscape
            ? (size.width >= 980 ? 5 : 4)
            : 2;
        final sheetHeight = math.min(
          size.height * (orientation == Orientation.landscape ? 0.92 : 0.82),
          720.0,
        );
        final tileAspectRatio = orientation == Orientation.landscape
            ? 1.24
            : 0.72;

        return Container(
          height: sheetHeight,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.wallpaper_rounded,
                      color: colors.focus,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '番茄钟皮肤',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '默认 + ${themes.length} 套',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FocusBackdropControls(
                  tone: currentTone,
                  material: currentMaterial,
                  blurLevel: blurLevel,
                  dimLevel: dimLevel,
                  glassLevel: glassLevel,
                  onToneChanged: (tone) {
                    setSheetState(() => currentTone = tone);
                    onBackgroundToneChanged(tone);
                  },
                  onMaterialChanged: (material) {
                    setSheetState(() => currentMaterial = material);
                    onBackgroundMaterialChanged(material);
                  },
                  onBlurLevelChanged: (level) {
                    setSheetState(() => blurLevel = level);
                    onBackgroundBlurLevelChanged(level);
                  },
                  onDimLevelChanged: (level) {
                    setSheetState(() => dimLevel = level);
                    onBackgroundDimLevelChanged(level);
                  },
                  onGlassLevelChanged: (level) {
                    setSheetState(() => glassLevel = level);
                    onGlassOpacityLevelChanged(level);
                  },
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: tileAspectRatio,
                  ),
                  itemCount: themes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _FocusDefaultThemeTile(
                        selected: selectedIndex == null,
                        orientation: orientation,
                        onTap: () => Navigator.of(context).pop(-1),
                      );
                    }
                    final themeIndex = index - 1;
                    final theme = themes[themeIndex];
                    final selected = themeIndex == selectedIndex;
                    return _FocusThemeTile(
                      theme: theme,
                      selected: selected,
                      orientation: orientation,
                      onTap: () => Navigator.of(context).pop(themeIndex),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FocusBackdropControls extends StatelessWidget {
  const _FocusBackdropControls({
    required this.tone,
    required this.material,
    required this.blurLevel,
    required this.dimLevel,
    required this.glassLevel,
    required this.onToneChanged,
    required this.onMaterialChanged,
    required this.onBlurLevelChanged,
    required this.onDimLevelChanged,
    required this.onGlassLevelChanged,
  });

  final _FocusBackdropTone tone;
  final _FocusBackdropMaterial material;
  final int blurLevel;
  final int dimLevel;
  final int glassLevel;
  final ValueChanged<_FocusBackdropTone> onToneChanged;
  final ValueChanged<_FocusBackdropMaterial> onMaterialChanged;
  final ValueChanged<int> onBlurLevelChanged;
  final ValueChanged<int> onDimLevelChanged;
  final ValueChanged<int> onGlassLevelChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final accent = tone.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.blur_on_rounded, color: accent, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '背景适配',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '侧边不刺眼',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final item in _FocusBackdropTone.values) ...[
                  _FocusBackdropToneChip(
                    tone: item,
                    selected: tone == item,
                    onTap: () => onToneChanged(item),
                  ),
                  if (item != _FocusBackdropTone.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _FocusBackdropMaterialSelector(
            material: material,
            accent: accent,
            onChanged: onMaterialChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FocusBackdropLevelSelector(
                  icon: Icons.gradient_rounded,
                  label: '模糊',
                  level: blurLevel,
                  accent: accent,
                  onChanged: onBlurLevelChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FocusBackdropLevelSelector(
                  icon: Icons.contrast_rounded,
                  label: '暗淡',
                  level: dimLevel,
                  accent: accent,
                  onChanged: onDimLevelChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FocusBackdropLevelSelector(
            icon: Icons.opacity_rounded,
            label: '玻璃',
            level: glassLevel,
            accent: accent,
            onChanged: onGlassLevelChanged,
          ),
        ],
      ),
    );
  }
}

class _FocusBackdropToneChip extends StatelessWidget {
  const _FocusBackdropToneChip({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final _FocusBackdropTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final swatch = tone.resolve(usingCustomTheme: true);
    final accent = tone.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colors.card.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.42)
                  : colors.border.withValues(alpha: 0.56),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: swatch.computeLuminance() > 0.5
                            ? const Color(0xFF233032)
                            : Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Icon(
                tone.icon,
                color: selected ? accent : colors.textTertiary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                tone.label,
                style: TextStyle(
                  color: selected ? accent : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusBackdropMaterialSelector extends StatelessWidget {
  const _FocusBackdropMaterialSelector({
    required this.material,
    required this.accent,
    required this.onChanged,
  });

  final _FocusBackdropMaterial material;
  final Color accent;
  final ValueChanged<_FocusBackdropMaterial> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in _FocusBackdropMaterial.values) ...[
            GestureDetector(
              onTap: () => onChanged(item),
              child: Builder(
                builder: (context) {
                  final itemAccent = _focusMaterialAccent(item, accent);
                  final selected = material == item;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 86,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                itemAccent.withValues(alpha: 0.22),
                                accent.withValues(alpha: 0.09),
                                Colors.white.withValues(alpha: 0.08),
                              ],
                            )
                          : null,
                      color: selected
                          ? null
                          : colors.card.withValues(alpha: 0.66),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? itemAccent.withValues(alpha: 0.52)
                            : colors.border.withValues(alpha: 0.46),
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: itemAccent.withValues(alpha: 0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 15,
                          color: selected ? itemAccent : colors.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? itemAccent
                                      : colors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: 9.5,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (item != _FocusBackdropMaterial.values.last)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

Color _focusMaterialAccent(_FocusBackdropMaterial material, Color toneAccent) {
  switch (material) {
    case _FocusBackdropMaterial.solid:
      return Color.lerp(toneAccent, const Color(0xFF23383A), 0.22)!;
    case _FocusBackdropMaterial.frosted:
      return Color.lerp(toneAccent, const Color(0xFF8ED3DD), 0.36)!;
    case _FocusBackdropMaterial.liquid:
      return Color.lerp(toneAccent, const Color(0xFF7FD9EA), 0.42)!;
    case _FocusBackdropMaterial.crystal:
      return Color.lerp(toneAccent, const Color(0xFFE9F3FF), 0.40)!;
    case _FocusBackdropMaterial.prism:
      return Color.lerp(toneAccent, const Color(0xFF7FA7EA), 0.42)!;
    case _FocusBackdropMaterial.pearl:
      return Color.lerp(toneAccent, const Color(0xFFF4E8D8), 0.42)!;
    case _FocusBackdropMaterial.glow:
      return Color.lerp(toneAccent, const Color(0xFFE3B65E), 0.46)!;
    case _FocusBackdropMaterial.dusk:
      return Color.lerp(toneAccent, const Color(0xFF506078), 0.58)!;
    case _FocusBackdropMaterial.noir:
      return Color.lerp(toneAccent, const Color(0xFF1A1D24), 0.62)!;
    case _FocusBackdropMaterial.silk:
      return Color.lerp(toneAccent, const Color(0xFFE7D8C7), 0.36)!;
  }
}

class _FocusBackdropLevelSelector extends StatelessWidget {
  const _FocusBackdropLevelSelector({
    required this.icon,
    required this.label,
    required this.level,
    required this.accent,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int level;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    const labels = ['关', '柔', '中', '强'];

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == level
                            ? accent.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: i == level
                              ? accent.withValues(alpha: 0.36)
                              : colors.border.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: i == level ? accent : colors.textTertiary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                if (i != labels.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusDefaultThemeTile extends StatelessWidget {
  const _FocusDefaultThemeTile({
    required this.selected,
    required this.orientation,
    required this.onTap,
  });

  final bool selected;
  final Orientation orientation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FocusThemePreviewTile(
      asset: orientation == Orientation.landscape
          ? FocusAssets.bgSessionLandscape
          : FocusAssets.bgSessionPortrait,
      name: '默认书桌',
      selected: selected,
      onTap: onTap,
    );
  }
}

class _FocusThemeTile extends StatelessWidget {
  const _FocusThemeTile({
    required this.theme,
    required this.selected,
    required this.orientation,
    required this.onTap,
  });

  final SceneryTheme theme;
  final bool selected;
  final Orientation orientation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FocusThemePreviewTile(
      asset: theme.assetForOrientation(orientation),
      name: theme.name,
      selected: selected,
      onTap: onTap,
    );
  }
}

Color _focusThemeAccentForAsset(String asset) {
  final match = RegExp(r'scene_(\d+)_').firstMatch(asset);
  final number = int.tryParse(match?.group(1) ?? '') ?? 0;
  if (number <= 0) return const Color(0xFF1C8F82);
  const palette = <Color>[
    Color(0xFF4FA7B8),
    Color(0xFFA575B7),
    Color(0xFFD5A247),
    Color(0xFFD88372),
    Color(0xFF5F9E82),
    Color(0xFF4A91C2),
    Color(0xFF8B9A5A),
    Color(0xFF9D7AC2),
    Color(0xFF71A86B),
    Color(0xFF8BB3C7),
    Color(0xFF526E93),
    Color(0xFFC4839A),
  ];
  return palette[(number - 1) % palette.length];
}

class _FocusThemePreviewTile extends StatelessWidget {
  const _FocusThemePreviewTile({
    required this.asset,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final accent = _focusThemeAccentForAsset(asset);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.92)
                  : colors.border.withValues(alpha: 0.58),
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: selected ? 0.18 : 0.10),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 9,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
    required this.accent,
    required this.glassOpacityLevel,
    this.compact = false,
  });

  final FocusCycleState cycleState;
  final double timerSize;
  final bool showCat;
  final bool showTitle;
  final Color accent;
  final int glassOpacityLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('focus_timer_stage'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundDots(cycleState: cycleState, compact: compact, accent: accent),
        SizedBox(height: compact ? 6 : 8),
        TimerDisplay(
          remaining: Duration(seconds: cycleState.remainingSeconds),
          total: _totalFor(cycleState),
          isBreak: cycleState.isBreak,
          size: timerSize,
          dark: true,
          roundLabel:
              '第 ${cycleState.currentRound} / ${cycleState.totalRounds} 轮',
          showCat: showCat,
          catAsset: FocusAssets.catForCycle(cycleState),
          title: cycleState.isBreak
              ? (cycleState.phase == FocusPhase.longBreak ? '长休息' : '短休息')
              : (cycleState.title.isEmpty
                    ? '${focusTypeLabel(cycleState.type)}专注'
                    : cycleState.title),
          subject: cycleState.subject.isNotEmpty ? cycleState.subject : null,
          showTitle: showTitle,
          accentColor: accent,
          glassOpacityLevel: glassOpacityLevel,
        ),
      ],
    );
  }
}

class _RoundDots extends StatelessWidget {
  const _RoundDots({
    required this.cycleState,
    required this.compact,
    required this.accent,
  });

  final FocusCycleState cycleState;
  final bool compact;
  final Color accent;

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
            ? accent.withValues(alpha: 0.95)
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
    required this.accent,
    required this.glassOpacityLevel,
    this.compact = false,
  });

  final String initialSoundType;
  final VoidCallback onTap;
  final Color accent;
  final int glassOpacityLevel;
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
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: 0.14,
      maximum: 0.30,
    );

    return Semantics(
      button: true,
      label: '展开专注声音',
      child: GestureDetector(
        key: const ValueKey('focus_sound_dock'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: compact ? 46 : 50,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 14,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: glassAlpha),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: glassAlpha + 0.20),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    color: accent.withValues(alpha: 0.92),
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
                            color: accent,
                            fontSize: 11.5,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Icon(
                          Icons.tune_rounded,
                          color: accent.withValues(alpha: 0.88),
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

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.cycleState,
    required this.isCycleDone,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onSkipBreak,
    required this.onReturn,
    required this.accent,
    required this.glassOpacityLevel,
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
  final Color accent;
  final int glassOpacityLevel;
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
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
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
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
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
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
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
    required this.accent,
    required this.glassOpacityLevel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool compact;
  final bool subdued;
  final Color accent;
  final int glassOpacityLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: icon,
          onTap: onTap,
          danger: danger,
          size: compact ? 48 : 60,
          subtle: subdued,
          accent: accent,
          glassOpacityLevel: glassOpacityLevel,
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
    required this.accent,
    required this.glassOpacityLevel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final double size;
  final bool subtle;
  final Color accent;
  final int glassOpacityLevel;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final buttonAccent = danger
        ? Color.lerp(accent, colors.danger, 0.36)!
        : accent;
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: subtle ? 0.12 : 0.14,
      maximum: subtle ? 0.24 : 0.32,
    );
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: glassAlpha),
              border: Border.all(
                color: Colors.white.withValues(alpha: glassAlpha + 0.18),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: buttonAccent.withValues(alpha: subtle ? 0.10 : 0.20),
                  blurRadius: subtle ? 14 : 22,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: subtle ? 0.80 : 0.94),
              size: size * 0.44,
            ),
          ),
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
    required this.accent,
    required this.glassOpacityLevel,
    this.compact = false,
    this.subdued = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool large;
  final Color accent;
  final int glassOpacityLevel;
  final bool compact;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final buttonSize = compact ? 68.0 : (large ? 94.0 : 68.0);
    final labelColor = Color.lerp(_sessionCream, accent, 0.18)!;
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: subdued ? 0.22 : 0.28,
      maximum: subdued ? 0.36 : 0.48,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.white,
                    accent,
                    accent.computeLuminance() < 0.18 ? 0.16 : 0.24,
                  )!.withValues(alpha: glassAlpha),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: subdued ? 0.24 : 0.38),
                      blurRadius: subdued ? 22 : 34,
                      spreadRadius: subdued ? 1 : 3,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.24),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.64),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _LiquidButtonPainter(
                        accent: accent,
                        subdued: subdued,
                      ),
                    ),
                    Center(
                      child: Icon(
                        icon,
                        color: colors.textOnAccent.withValues(alpha: 0.96),
                        size: compact
                            ? 31
                            : large
                            ? 46
                            : 33,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 7),
        Text(
          label,
          style: TextStyle(
            color: labelColor.withValues(alpha: subdued ? 0.78 : 1),
            fontSize: compact ? 12 : 14,
            height: 1.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LiquidButtonPainter extends CustomPainter {
  const _LiquidButtonPainter({required this.accent, required this.subdued});

  final Color accent;
  final bool subdued;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final darkAccent = accent.computeLuminance() < 0.18;

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.width * 0.025)
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: subdued ? 0.30 : 0.48),
          accent.withValues(alpha: darkAccent ? 0.30 : 0.18),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: subdued ? 0.30 : 0.48),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius - 2.5, rimPaint);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, size.width * 0.052)
      ..color = Colors.white.withValues(alpha: subdued ? 0.24 : 0.36)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.70),
      -math.pi * 0.78,
      math.pi * 0.38,
      false,
      highlightPaint,
    );

    final poolPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.52),
        radius: 0.62,
        colors: [
          Colors.white.withValues(alpha: subdued ? 0.18 : 0.28),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius - 3, poolPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidButtonPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.subdued != subdued;
  }
}

class _NextPhasePill extends StatelessWidget {
  const _NextPhasePill({
    required this.cycleState,
    required this.accent,
    required this.glassOpacityLevel,
    this.compact = false,
  });

  final FocusCycleState cycleState;
  final Color accent;
  final int glassOpacityLevel;
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
    final glassAlpha = _focusGlassOpacity(
      glassOpacityLevel,
      minimum: 0.14,
      maximum: 0.30,
    );
    return ClipRRect(
      key: const ValueKey('next_phase_pill'),
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: compact ? 50 : 54,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: glassAlpha),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: glassAlpha + 0.20),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                        color: accent,
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
        ),
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
