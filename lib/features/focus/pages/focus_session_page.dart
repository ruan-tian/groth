import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/focus_data.dart';
import '../../dashboard/providers/dashboard_provider.dart'
    hide
        expRepositoryProvider,
        focusRepositoryProvider,
        studyRepositoryProvider;
import '../../../shared/providers/focus_audio_provider.dart';
import '../providers/focus_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../study/providers/study_provider.dart';
import '../../../core/domain/pet/pet_event.dart';
import '../../../core/services/pet_event_bus.dart';
import '../../../core/services/focus_audio_service.dart';
import '../../plan/services/reminder_notification_service.dart';
import '../../music/providers/music_player_provider.dart';
import '../../../shared/constants/scenery_theme_catalog.dart';
import '../utils/focus_assets.dart';
import '../utils/focus_options.dart';
import '../widgets/focus_sound_panel.dart';
import '../widgets/timer_display.dart';

part '../widgets/focus_session_widgets.dart';

const _sessionCream = Color(0xFFF7E5C6);
const _focusSceneryThemeKey = 'focus_scenery_theme_index';
const _focusBackgroundToneKey = 'focus_background_tone';
const _focusBackgroundBlurKey = 'focus_background_blur';
const _focusBackgroundDimKey = 'focus_background_dim';
const _focusBackgroundMaterialKey = 'focus_background_material';
const _focusGlassOpacityKey = 'focus_glass_opacity';

enum _FocusBackdropTone {
  auto,
  mistBlue,
  warmCream,
  midnight,
  forest,
  mountain,
  dawnRose,
  lavender,
  lake,
  amber,
  ink,
  aurora,
  coral,
  sage,
  snow,
}

extension _FocusBackdropToneData on _FocusBackdropTone {
  String get value => name;

  String get label {
    switch (this) {
      case _FocusBackdropTone.auto:
        return '自动';
      case _FocusBackdropTone.mistBlue:
        return '雾蓝';
      case _FocusBackdropTone.warmCream:
        return '暖米';
      case _FocusBackdropTone.midnight:
        return '深夜';
      case _FocusBackdropTone.forest:
        return '墨绿';
      case _FocusBackdropTone.mountain:
        return '山青';
      case _FocusBackdropTone.dawnRose:
        return '晨粉';
      case _FocusBackdropTone.lavender:
        return '雾紫';
      case _FocusBackdropTone.lake:
        return '湖蓝';
      case _FocusBackdropTone.amber:
        return '琥珀';
      case _FocusBackdropTone.ink:
        return '墨黑';
      case _FocusBackdropTone.aurora:
        return '极光';
      case _FocusBackdropTone.coral:
        return '珊瑚';
      case _FocusBackdropTone.sage:
        return '鼠尾草';
      case _FocusBackdropTone.snow:
        return '雪雾';
    }
  }

  IconData get icon {
    switch (this) {
      case _FocusBackdropTone.auto:
        return Icons.auto_awesome_rounded;
      case _FocusBackdropTone.mistBlue:
        return Icons.water_drop_rounded;
      case _FocusBackdropTone.warmCream:
        return Icons.wb_sunny_rounded;
      case _FocusBackdropTone.midnight:
        return Icons.nightlight_round;
      case _FocusBackdropTone.forest:
        return Icons.eco_rounded;
      case _FocusBackdropTone.mountain:
        return Icons.landscape_rounded;
      case _FocusBackdropTone.dawnRose:
        return Icons.wb_twilight_rounded;
      case _FocusBackdropTone.lavender:
        return Icons.filter_vintage_rounded;
      case _FocusBackdropTone.lake:
        return Icons.waves_rounded;
      case _FocusBackdropTone.amber:
        return Icons.light_mode_rounded;
      case _FocusBackdropTone.ink:
        return Icons.contrast_rounded;
      case _FocusBackdropTone.aurora:
        return Icons.auto_awesome_rounded;
      case _FocusBackdropTone.coral:
        return Icons.local_florist_rounded;
      case _FocusBackdropTone.sage:
        return Icons.spa_rounded;
      case _FocusBackdropTone.snow:
        return Icons.ac_unit_rounded;
    }
  }

  Color resolve({required bool usingCustomTheme}) {
    switch (this) {
      case _FocusBackdropTone.auto:
        return usingCustomTheme
            ? const Color(0xFF819894)
            : const Color(0xFF8FA6A0);
      case _FocusBackdropTone.mistBlue:
        return const Color(0xFF9CAFB3);
      case _FocusBackdropTone.warmCream:
        return const Color(0xFFE1D2B8);
      case _FocusBackdropTone.midnight:
        return const Color(0xFF0B0F14);
      case _FocusBackdropTone.forest:
        return const Color(0xFF63796F);
      case _FocusBackdropTone.mountain:
        return const Color(0xFF6F8E88);
      case _FocusBackdropTone.dawnRose:
        return const Color(0xFFC7A1A4);
      case _FocusBackdropTone.lavender:
        return const Color(0xFFA59AB8);
      case _FocusBackdropTone.lake:
        return const Color(0xFF7CA8B3);
      case _FocusBackdropTone.amber:
        return const Color(0xFFC1A16F);
      case _FocusBackdropTone.ink:
        return const Color(0xFF111827);
      case _FocusBackdropTone.aurora:
        return const Color(0xFF5D7B8C);
      case _FocusBackdropTone.coral:
        return const Color(0xFFC98B7A);
      case _FocusBackdropTone.sage:
        return const Color(0xFF80987F);
      case _FocusBackdropTone.snow:
        return const Color(0xFFB6C9D0);
    }
  }

  Color get accent {
    switch (this) {
      case _FocusBackdropTone.auto:
      case _FocusBackdropTone.mountain:
        return const Color(0xFF1C8F82);
      case _FocusBackdropTone.mistBlue:
      case _FocusBackdropTone.lake:
        return const Color(0xFF2F8EA1);
      case _FocusBackdropTone.warmCream:
      case _FocusBackdropTone.amber:
        return const Color(0xFFD09A39);
      case _FocusBackdropTone.midnight:
        return const Color(0xFF111827);
      case _FocusBackdropTone.forest:
        return const Color(0xFF4D8F73);
      case _FocusBackdropTone.dawnRose:
        return const Color(0xFFC6757E);
      case _FocusBackdropTone.lavender:
        return const Color(0xFF806FAE);
      case _FocusBackdropTone.ink:
        return const Color(0xFF0B0F14);
      case _FocusBackdropTone.aurora:
        return const Color(0xFF50A6A0);
      case _FocusBackdropTone.coral:
        return const Color(0xFFC86E5A);
      case _FocusBackdropTone.sage:
        return const Color(0xFF698F65);
      case _FocusBackdropTone.snow:
        return const Color(0xFF7896A3);
    }
  }
}

_FocusBackdropTone _parseFocusBackdropTone(String? raw) {
  return _FocusBackdropTone.values.firstWhere(
    (tone) => tone.value == raw,
    orElse: () => _FocusBackdropTone.auto,
  );
}

enum _FocusBackdropMaterial {
  solid,
  frosted,
  liquid,
  crystal,
  prism,
  pearl,
  glow,
  dusk,
  noir,
  silk,
}

extension _FocusBackdropMaterialData on _FocusBackdropMaterial {
  String get value => name;

  String get label {
    switch (this) {
      case _FocusBackdropMaterial.solid:
        return '纯色';
      case _FocusBackdropMaterial.frosted:
        return '雾面';
      case _FocusBackdropMaterial.liquid:
        return '液态';
      case _FocusBackdropMaterial.crystal:
        return '晶面';
      case _FocusBackdropMaterial.prism:
        return '棱镜';
      case _FocusBackdropMaterial.pearl:
        return '珍珠';
      case _FocusBackdropMaterial.glow:
        return '柔光';
      case _FocusBackdropMaterial.dusk:
        return '夜幕';
      case _FocusBackdropMaterial.noir:
        return '暗调';
      case _FocusBackdropMaterial.silk:
        return '丝雾';
    }
  }

  String get description {
    switch (this) {
      case _FocusBackdropMaterial.solid:
        return '干净';
      case _FocusBackdropMaterial.frosted:
        return '自然';
      case _FocusBackdropMaterial.liquid:
        return '折射';
      case _FocusBackdropMaterial.crystal:
        return '亮边';
      case _FocusBackdropMaterial.prism:
        return '彩散';
      case _FocusBackdropMaterial.pearl:
        return '柔亮';
      case _FocusBackdropMaterial.glow:
        return '明亮';
      case _FocusBackdropMaterial.dusk:
        return '沉静';
      case _FocusBackdropMaterial.noir:
        return '低调';
      case _FocusBackdropMaterial.silk:
        return '柔雾';
    }
  }

  IconData get icon {
    switch (this) {
      case _FocusBackdropMaterial.solid:
        return Icons.palette_rounded;
      case _FocusBackdropMaterial.frosted:
        return Icons.blur_on_rounded;
      case _FocusBackdropMaterial.liquid:
        return Icons.water_drop_rounded;
      case _FocusBackdropMaterial.crystal:
        return Icons.diamond_rounded;
      case _FocusBackdropMaterial.prism:
        return Icons.filter_hdr_rounded;
      case _FocusBackdropMaterial.pearl:
        return Icons.bubble_chart_rounded;
      case _FocusBackdropMaterial.glow:
        return Icons.auto_awesome_rounded;
      case _FocusBackdropMaterial.dusk:
        return Icons.nights_stay_rounded;
      case _FocusBackdropMaterial.noir:
        return Icons.dark_mode_rounded;
      case _FocusBackdropMaterial.silk:
        return Icons.filter_vintage_rounded;
    }
  }
}

_FocusBackdropMaterial _parseFocusBackdropMaterial(String? raw) {
  return _FocusBackdropMaterial.values.firstWhere(
    (material) => material.value == raw,
    orElse: () => _FocusBackdropMaterial.frosted,
  );
}

int _parseFocusBackdropLevel(String? raw, {required int defaultValue}) {
  if (raw == null || raw.isEmpty) return defaultValue;
  if (raw == 'true') return defaultValue;
  if (raw == 'false') return 0;
  return (int.tryParse(raw) ?? defaultValue).clamp(0, 3);
}

double _focusBackdropBlurSigma(int level) {
  switch (level.clamp(0, 3)) {
    case 0:
      return 0;
    case 1:
      return 14;
    case 2:
      return 28;
    default:
      return 42;
  }
}

double _focusBackdropDimAlpha(int level, _FocusBackdropTone tone) {
  final base = tone == _FocusBackdropTone.midnight ? 0.06 : 0.08;
  switch (level.clamp(0, 3)) {
    case 0:
      return 0;
    case 1:
      return base;
    case 2:
      return base + 0.10;
    default:
      return base + 0.20;
  }
}

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
  bool _musicWasPlayingOnEnter = false;
  bool _focusStartedMusic = false;
  bool _soundPanelOpen = false;
  bool _controlsVisible = false;
  bool _locked = false;
  int? _selectedThemeIndex;
  _FocusBackdropTone _backgroundTone = _FocusBackdropTone.auto;
  _FocusBackdropMaterial _backgroundMaterial = _FocusBackdropMaterial.frosted;
  int _backgroundBlurLevel = 0;
  int _backgroundDimLevel = 0;
  int _glassOpacityLevel = 2;
  Timer? _hideTimer;
  late FocusAudioStateNotifier _audioNotifier;
  String? _currentSoundType;

  @override
  void initState() {
    super.initState();
    _audioNotifier = ref.read(focusAudioStateProvider.notifier);
    _musicWasPlayingOnEnter = ref.read(musicPlayerProvider).isPlaying;
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    unawaited(_loadSelectedTheme());
    unawaited(_loadBackgroundPreferences());
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
            soundType: _normalizeSessionSoundType(widget.soundType),
          );
      _initAudio();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    _stopSessionAudioForDispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusCycleProvider.notifier).recalculate();
    }
  }

  void _initAudio() {
    if (!mounted) return;
    final soundType = _normalizeSessionSoundType(
      ref.read(focusCycleProvider).soundType,
    );
    _currentSoundType = soundType;
    if (soundType == 'music') {
      unawaited(_startFocusMusic());
      return;
    }
    if (soundType != null && soundType.isNotEmpty && soundType != 'none') {
      unawaited(ref.read(musicPlayerProvider.notifier).pause());
      unawaited(
        ref.read(focusAudioStateProvider.notifier).startNoise(soundType),
      );
    }
  }

  Future<void> _startFocusMusic() async {
    final musicState = ref.read(musicPlayerProvider);
    if (!musicState.isPlaying && musicState.currentTrack != null) {
      _focusStartedMusic = true;
      await ref.read(musicPlayerProvider.notifier).togglePlayPause();
    } else if (musicState.currentTrack == null && mounted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先在音乐页面导入本地音乐')));
    }
  }

  void _pauseSessionAudio() {
    final soundType = ref.read(focusCycleProvider).soundType;
    if (soundType == 'music') {
      ref.read(musicPlayerProvider.notifier).pause();
      return;
    }
    ref.read(focusAudioStateProvider.notifier).pauseNoise();
  }

  void _resumeSessionAudio() {
    final soundType = ref.read(focusCycleProvider).soundType;
    if (soundType == 'music') {
      unawaited(_startFocusMusic());
      return;
    }
    unawaited(ref.read(focusAudioStateProvider.notifier).resumeNoise());
  }

  void _stopSessionAudio() {
    final soundType = ref.read(focusCycleProvider).soundType;
    if (soundType == 'music') {
      ref.read(musicPlayerProvider.notifier).pause();
      return;
    }
    ref.read(focusAudioStateProvider.notifier).stopNoise();
  }

  void _stopSessionAudioForDispose() {
    if (_currentSoundType == 'music') {
      if (!_musicWasPlayingOnEnter && _focusStartedMusic) {
        unawaited(ref.read(musicPlayerProvider.notifier).pause());
      }
    } else {
      unawaited(_audioNotifier.stopNoise());
    }
  }

  void _pauseTimer() {
    _pauseSessionAudio();
    ref.read(focusCycleProvider.notifier).pause();
  }

  void _resumeTimer() {
    _resumeSessionAudio();
    ref.read(focusCycleProvider.notifier).resume();
  }

  String? _normalizeSessionSoundType(String? soundType) {
    if (soundType == null || soundType.isEmpty || soundType == 'none') {
      return null;
    }
    if (soundType == 'music') return 'music';
    return FocusAudioService.normalizeSoundType(soundType);
  }

  void _handleSoundChanged(String? value) {
    final normalized = _normalizeSessionSoundType(value);
    _currentSoundType = normalized;
    ref.read(focusCycleProvider.notifier).setSoundType(normalized);

    if (normalized == 'music') {
      _focusStartedMusic = true;
      ref.read(focusAudioStateProvider.notifier).stopNoise();
      unawaited(_startFocusMusic());
      return;
    }

    if (normalized != null) {
      ref.read(musicPlayerProvider.notifier).pause();
      unawaited(
        ref.read(focusAudioStateProvider.notifier).changeSound(normalized),
      );
      return;
    }

    ref.read(focusAudioStateProvider.notifier).stopNoise();
  }

  void _toggleSoundPanel() {
    if (!mounted) return;
    setState(() => _soundPanelOpen = !_soundPanelOpen);
  }

  void _closeSoundPanel() {
    if (!mounted || !_soundPanelOpen) return;
    setState(() => _soundPanelOpen = false);
  }

  void _toggleControls() {
    if (!mounted) return;
    setState(() => _controlsVisible = !_controlsVisible);
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_controlsVisible) {
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _controlsVisible = false);
      });
    }
  }

  void _toggleLock() {
    if (!mounted) return;
    setState(() {
      if (_locked) {
        _locked = false;
        _controlsVisible = true;
      } else {
        _locked = true;
        _controlsVisible = false;
        _soundPanelOpen = false;
      }
    });
    _resetHideTimer();
  }

  Future<void> _loadSelectedTheme() async {
    final raw = await ref
        .read(settingRepositoryProvider)
        .getSetting(_focusSceneryThemeKey);
    if (raw == null || raw.isEmpty) return;
    final index = int.tryParse(raw);
    if (!mounted || index == null || SceneryThemeCatalog.themes.isEmpty) {
      return;
    }
    setState(() {
      _selectedThemeIndex = index.clamp(
        0,
        SceneryThemeCatalog.themes.length - 1,
      );
    });
  }

  Future<void> _loadBackgroundPreferences() async {
    final repo = ref.read(settingRepositoryProvider);
    final values = await Future.wait([
      repo.getSetting(_focusBackgroundToneKey),
      repo.getSetting(_focusBackgroundBlurKey),
      repo.getSetting(_focusBackgroundDimKey),
      repo.getSetting(_focusBackgroundMaterialKey),
      repo.getSetting(_focusGlassOpacityKey),
    ]);
    if (!mounted) return;
    setState(() {
      _backgroundTone = _parseFocusBackdropTone(values[0]);
      _backgroundBlurLevel = _parseFocusBackdropLevel(
        values[1],
        defaultValue: 0,
      );
      _backgroundDimLevel = _parseFocusBackdropLevel(
        values[2],
        defaultValue: 0,
      );
      _backgroundMaterial = _parseFocusBackdropMaterial(values[3]);
      _glassOpacityLevel = _parseFocusBackdropLevel(values[4], defaultValue: 2);
    });
  }

  void _setBackgroundTone(_FocusBackdropTone tone) {
    if (!mounted || tone == _backgroundTone) return;
    setState(() => _backgroundTone = tone);
    unawaited(
      ref
          .read(settingRepositoryProvider)
          .setSetting(_focusBackgroundToneKey, tone.value),
    );
  }

  void _setBackgroundMaterial(_FocusBackdropMaterial material) {
    if (!mounted || material == _backgroundMaterial) return;
    setState(() => _backgroundMaterial = material);
    unawaited(
      ref
          .read(settingRepositoryProvider)
          .setSetting(_focusBackgroundMaterialKey, material.value),
    );
  }

  void _setBackgroundBlurLevel(int level) {
    final normalized = level.clamp(0, 3);
    if (!mounted || normalized == _backgroundBlurLevel) return;
    setState(() => _backgroundBlurLevel = normalized);
    unawaited(
      ref
          .read(settingRepositoryProvider)
          .setSetting(_focusBackgroundBlurKey, normalized.toString()),
    );
  }

  void _setBackgroundDimLevel(int level) {
    final normalized = level.clamp(0, 3);
    if (!mounted || normalized == _backgroundDimLevel) return;
    setState(() => _backgroundDimLevel = normalized);
    unawaited(
      ref
          .read(settingRepositoryProvider)
          .setSetting(_focusBackgroundDimKey, normalized.toString()),
    );
  }

  void _setGlassOpacityLevel(int level) {
    final normalized = level.clamp(0, 3);
    if (!mounted || normalized == _glassOpacityLevel) return;
    setState(() => _glassOpacityLevel = normalized);
    unawaited(
      ref
          .read(settingRepositoryProvider)
          .setSetting(_focusGlassOpacityKey, normalized.toString()),
    );
  }

  Future<void> _showThemeSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FocusThemeSheet(
        selectedIndex: _selectedThemeIndex,
        themes: SceneryThemeCatalog.themes,
        backgroundTone: _backgroundTone,
        backgroundMaterial: _backgroundMaterial,
        backgroundBlurLevel: _backgroundBlurLevel,
        backgroundDimLevel: _backgroundDimLevel,
        glassOpacityLevel: _glassOpacityLevel,
        onBackgroundToneChanged: _setBackgroundTone,
        onBackgroundMaterialChanged: _setBackgroundMaterial,
        onBackgroundBlurLevelChanged: _setBackgroundBlurLevel,
        onBackgroundDimLevelChanged: _setBackgroundDimLevel,
        onGlassOpacityLevelChanged: _setGlassOpacityLevel,
      ),
    );
    if (!mounted || selected == null) return;
    final nextIndex = selected < 0 ? null : selected;
    setState(() => _selectedThemeIndex = nextIndex);
    unawaited(
      ref
          .read(settingRepositoryProvider)
          .setSetting(_focusSceneryThemeKey, nextIndex?.toString() ?? ''),
    );
  }

  void _skipBreak() {
    ref.read(focusCycleProvider.notifier).skipBreak();
    _phaseCompletionHandled = false;
    _initAudio();
  }

  Future<void> _cancelSession() async {
    _stopSessionAudio();
    await _saveFocusRound(completed: false);
    ref.read(focusCycleProvider.notifier).cancel();
    if (mounted) context.pop();
  }

  void _onPhaseComplete() {
    if (_phaseCompletionHandled) return;
    _phaseCompletionHandled = true;
    final cycleState = ref.read(focusCycleProvider);

    if (cycleState.phase == FocusPhase.focus) {
      _stopSessionAudio();
      ref.read(focusAudioStateProvider.notifier).playBell('gentle_bell');

      // 取消预调度通知（用户已回来，手动处理）
      ref.read(focusCycleProvider.notifier).cancelScheduledNotification();

      // 发送即时通知
      // ignore: unawaited_futures
      ref
          .read(reminderNotificationServiceProvider)
          .showImmediate(
            id: 5205,
            title: '专注时间结束',
            body: cycleState.isLastRound
                ? '所有轮次完成！休息一下吧～'
                : '第${cycleState.currentRound}轮完成！休息一下吧～',
            payload: 'focus_complete',
          );

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
    _stopSessionAudio();
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

    try {
      final cycleState = ref.read(focusCycleProvider);
      final saveKey =
          '${cycleState.sessionGroupId ?? 'local'}:${cycleState.currentRound}:$completed';
      if (_savedRoundKeys.contains(saveKey)) {
        return;
      }
      final focusRepo = ref.read(focusRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final phaseStartMs =
          cycleState.phaseStartAt?.millisecondsSinceEpoch ?? now;
      final actualDuration = completed
          ? widget.durationMinutes
          : ((cycleState.focusSeconds - cycleState.remainingSeconds) / 60)
                .ceil();
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
    } catch (e) {
      debugPrint('保存专注记录失败: $e');
    } finally {
      _saved = false;
    }
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
          unawaited(_cancelSession());
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
    // 使用 select 精细化 watch，避免每秒 remainingSeconds 变化触发全量 rebuild
    final colors = context.growthColors;
    final isRunning = ref.watch(focusCycleProvider.select((s) => s.isRunning));
    final phase = ref.watch(focusCycleProvider.select((s) => s.phase));
    final remainingSeconds = ref.watch(
      focusCycleProvider.select((s) => s.remainingSeconds),
    );
    final cycleState = ref.watch(focusCycleProvider);

    ref.listen<FocusCycleState>(focusCycleProvider, (prev, next) {
      if (prev != null && !prev.phaseCompleted && next.phaseCompleted) {
        _onPhaseComplete();
      }
    });

    final isCycleDone =
        !isRunning && phase == FocusPhase.longBreak && remainingSeconds <= 0;

    return PopScope(
      canPop: !isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isRunning) _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth >= constraints.maxHeight;
            final isCompactLandscape =
                isLandscape &&
                (constraints.maxWidth < 900 || constraints.maxHeight < 520);
            final selectedTheme = _selectedThemeIndex == null
                ? null
                : SceneryThemeCatalog.themeAt(_selectedThemeIndex!);
            final backgroundAsset = selectedTheme == null
                ? (isLandscape
                      ? FocusAssets.bgSessionLandscape
                      : FocusAssets.bgSessionPortrait)
                : (isLandscape
                      ? selectedTheme.landscapeAsset
                      : selectedTheme.portraitAsset);
            final usingCustomTheme = selectedTheme != null;
            return Stack(
              children: [
                Positioned.fill(
                  child: _FocusSessionBackground(
                    asset: backgroundAsset,
                    tone: _backgroundTone,
                    material: _backgroundMaterial,
                    blurLevel: _backgroundBlurLevel,
                    dimLevel: _backgroundDimLevel,
                    usingCustomTheme: usingCustomTheme,
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    FocusAssets.roomGlow,
                    fit: BoxFit.cover,
                    opacity: AlwaysStoppedAnimation(
                      usingCustomTheme ? 0.18 : 0.34,
                    ),
                  ),
                ),
                if (isCompactLandscape)
                  _CompactLandscapeSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    soundPanelOpen: _soundPanelOpen,
                    controlsVisible: _controlsVisible,
                    locked: _locked,
                    selectedTheme: selectedTheme,
                    usingCustomTheme: usingCustomTheme,
                    backgroundTone: _backgroundTone,
                    glassOpacityLevel: _glassOpacityLevel,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
                    onOpenThemeSheet: _showThemeSheet,
                    onSoundChanged: _handleSoundChanged,
                    onSoundPanelToggle: _toggleSoundPanel,
                    onSoundPanelClose: _closeSoundPanel,
                    onToggleControls: _toggleControls,
                    onToggleLock: _toggleLock,
                  )
                else if (isLandscape)
                  _LandscapeSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    soundPanelOpen: _soundPanelOpen,
                    controlsVisible: _controlsVisible,
                    locked: _locked,
                    selectedTheme: selectedTheme,
                    usingCustomTheme: usingCustomTheme,
                    backgroundTone: _backgroundTone,
                    glassOpacityLevel: _glassOpacityLevel,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
                    onOpenThemeSheet: _showThemeSheet,
                    onSoundChanged: _handleSoundChanged,
                    onSoundPanelToggle: _toggleSoundPanel,
                    onSoundPanelClose: _closeSoundPanel,
                    onToggleControls: _toggleControls,
                    onToggleLock: _toggleLock,
                  )
                else
                  _PortraitSession(
                    cycleState: cycleState,
                    isCycleDone: isCycleDone,
                    soundPanelOpen: _soundPanelOpen,
                    controlsVisible: _controlsVisible,
                    locked: _locked,
                    selectedTheme: selectedTheme,
                    usingCustomTheme: usingCustomTheme,
                    backgroundTone: _backgroundTone,
                    glassOpacityLevel: _glassOpacityLevel,
                    onCancel: _showCancelDialog,
                    onPause: _pauseTimer,
                    onResume: _resumeTimer,
                    onSkipBreak: _skipBreak,
                    onReturn: () => context.pop(),
                    onOpenThemeSheet: _showThemeSheet,
                    onSoundChanged: _handleSoundChanged,
                    onSoundPanelToggle: _toggleSoundPanel,
                    onSoundPanelClose: _closeSoundPanel,
                    onToggleControls: _toggleControls,
                    onToggleLock: _toggleLock,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
