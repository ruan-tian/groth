import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pet_projection_provider.dart';
import '../../../core/constants/pet_assets.dart';
import 'particle_burst.dart';
import '../../../app/design/design.dart';

const int kMorningStartHour = 6;
const int kAfternoonStartHour = 12;
const int kEveningStartHour = 17;
const int kNightStartHour = 21;

const double kHeroPetMaxSize = 280;
const double kHeroPetMinSize = 168;
const Duration kGreetingDuration = Duration(milliseconds: 1800);
const Duration kSceneSwitchDuration = Duration(milliseconds: 340);

class PetSceneHero extends ConsumerStatefulWidget {
  const PetSceneHero({super.key, required this.level, required this.petName});

  final int level;
  final String petName;

  @override
  ConsumerState<PetSceneHero> createState() => _PetSceneHeroState();
}

class _PetSceneHeroState extends ConsumerState<PetSceneHero>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _breatheController;
  late final AnimationController _bounceController;
  late final AnimationController _particleController;
  late final ValueNotifier<bool> _burstTrigger;

  Timer? _greetingTimer;
  Timer? _tapMessageTimer;
  bool _showGreeting = true;
  bool _nextBurstIsHeart = true;
  Offset _burstCenter = Offset.zero;
  ParticleType _burstType = ParticleType.hearts;
  String? _tapMessage;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _burstTrigger = ValueNotifier<bool>(false);
    _greetingTimer = Timer(kGreetingDuration, () {
      if (mounted) {
        setState(() => _showGreeting = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _tapMessageTimer?.cancel();
    _floatController.dispose();
    _breatheController.dispose();
    _bounceController.dispose();
    _particleController.dispose();
    _burstTrigger.dispose();
    super.dispose();
  }

  void _syncMotionPreference() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _floatController.stop();
      _breatheController.stop();
      _particleController.stop();
      _floatController.value = 0;
      _breatheController.value = 0;
      _particleController.value = 0;
    } else {
      if (!_floatController.isAnimating) {
        _floatController.repeat(reverse: true);
      }
      if (!_breatheController.isAnimating) {
        _breatheController.repeat(reverse: true);
      }
      if (!_particleController.isAnimating) {
        _particleController.repeat();
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _burstCenter = details.localPosition;
    _burstType = _nextBurstIsHeart ? ParticleType.hearts : ParticleType.stars;
    _nextBurstIsHeart = !_nextBurstIsHeart;
    _burstTrigger.value = !_burstTrigger.value;
    _bounceController.forward(from: 0);

    setState(() {
      _tapMessage = _nextTapMessage();
      _showGreeting = false;
    });
    _tapMessageTimer?.cancel();
    _tapMessageTimer = Timer(kGreetingDuration, () {
      if (mounted) {
        setState(() => _tapMessage = null);
      }
    });
  }

  String _nextTapMessage() {
    final slot = _timeSlotForHour(DateTime.now().hour);
    switch (slot) {
      case PetCenterTimeSlot.morning:
        return '早安，今天也一起升级';
      case PetCenterTimeSlot.afternoon:
        return '我在这儿，专注一下吧';
      case PetCenterTimeSlot.evening:
        return '今天辛苦啦，记得复盘';
      case PetCenterTimeSlot.night:
        return '早点休息，明天继续';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final view = ref.watch(petCenterViewProvider);
    final slot = _timeSlotForHour(DateTime.now().hour);
    final petAsset = _petAssetFor(view, slot);
    final bubbleText = _bubbleTextFor(view, slot);
    final backgroundAsset = PetCenterAssets.backgroundForTime(slot);
    final tint = _tintForTime(slot);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final petSize = math
            .min(width * 0.54, height * 0.64)
            .clamp(kHeroPetMinSize, kHeroPetMaxSize)
            .toDouble();
        final petBottom = height * 0.095;
        final petLeft = (width - petSize) / 2;
        final narrowBubble = width < 380;
        final bubbleWidth = narrowBubble
            ? math.min(width - 32, 300.0)
            : math.min(width - 32, 360.0);
        final bubbleTop = math.max(76.0, height * 0.18);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _handleTapDown,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _SceneImage(
                  asset: backgroundAsset,
                  fit: BoxFit.cover,
                  fallbackColor: tint.background,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tint.overlayTop, tint.overlayBottom],
                    ),
                  ),
                ),
                _SceneImage(
                  asset: PetCenterAssets.roomGlow,
                  fit: BoxFit.cover,
                  opacity: tint.glowOpacity,
                ),
                if (!reduceMotion)
                  AnimatedBuilder(
                    animation: _particleController,
                    builder: (_, _) {
                      return _AmbientParticleLayer(
                        progress: _particleController.value,
                        slot: slot,
                      );
                    },
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -height * 0.02,
                  height: height * 0.38,
                  child: _SceneImage(
                    asset: PetCenterAssets.ground,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    opacity: 0.96,
                  ),
                ),
                ..._buildDecorations(width, height, petSize, reduceMotion),
                Positioned(
                  left: petLeft + petSize * 0.12,
                  right: petLeft + petSize * 0.12,
                  bottom: petBottom + petSize * 0.02,
                  height: petSize * 0.25,
                  child: _SceneImage(
                    asset: PetCenterAssets.softShadow,
                    fit: BoxFit.contain,
                    opacity: 0.54,
                  ),
                ),
                Positioned(
                  left: petLeft,
                  bottom: petBottom,
                  width: petSize,
                  height: petSize,
                  child: _AnimatedPet(
                    asset: petAsset,
                    floatController: _floatController,
                    breatheController: _breatheController,
                    bounceController: _bounceController,
                    reduceMotion: reduceMotion,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -height * 0.01,
                  height: height * 0.36,
                  child: IgnorePointer(
                    child: _SceneImage(
                      asset: PetCenterAssets.furniture,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                      opacity: 0.9,
                    ),
                  ),
                ),
                Positioned(
                  top: bubbleTop,
                  left: narrowBubble ? (width - bubbleWidth) / 2 : null,
                  right: narrowBubble ? null : math.max(16.0, width * 0.08),
                  width: bubbleWidth,
                  child: _PetSpeechBubble(
                    text: bubbleText,
                    accent: tint.accent,
                  ),
                ),
                Positioned.fill(
                  child: ParticleBurst(
                    trigger: _burstTrigger,
                    center: _burstCenter,
                    type: _burstType,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _petAssetFor(PetViewState? view, PetCenterTimeSlot slot) {
    if (_showGreeting) {
      return PetCenterAssets.petWave;
    }
    final mapped = _actionFromView(view);
    return PetCenterAssets.petForAction(mapped, slot);
  }

  String _bubbleTextFor(PetViewState? view, PetCenterTimeSlot slot) {
    if (_tapMessage != null) {
      return _tapMessage!;
    }
    if (_showGreeting) {
      return '${widget.petName}的小窝变漂亮啦';
    }
    final text = view?.bubbleText;
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }
    switch (slot) {
      case PetCenterTimeSlot.morning:
        return '新的一天开始啦';
      case PetCenterTimeSlot.afternoon:
        return '把节奏稳稳找回来';
      case PetCenterTimeSlot.evening:
        return '今天也有认真成长';
      case PetCenterTimeSlot.night:
        return '晚安，我陪你收尾';
    }
  }

  String? _actionFromView(PetViewState? view) {
    final action = view?.action;
    if (action != null && action != 'idle') {
      return action;
    }
    final path = view?.imagePath?.toLowerCase();
    if (path == null) return action;
    if (path.contains('thinking') ||
        path.contains('report') ||
        path.contains('ai')) {
      return 'think';
    }
    if (path.contains('happy') ||
        path.contains('done') ||
        path.contains('level')) {
      return 'happy';
    }
    if (path.contains('sleep') || path.contains('yawn')) {
      return 'sleep';
    }
    if (path.contains('read') ||
        path.contains('study') ||
        path.contains('focus')) {
      return 'read';
    }
    if (path.contains('wave') || path.contains('greet')) {
      return 'wave';
    }
    return action;
  }

  List<Widget> _buildDecorations(
    double width,
    double height,
    double petSize,
    bool reduceMotion,
  ) {
    final assets = PetCenterAssets.decoForLevel(widget.level);
    final anchors = <Offset>[
      Offset(width * 0.19, height * 0.31),
      Offset(width * 0.78, height * 0.29),
      Offset(width * 0.18, height * 0.66),
      Offset(width * 0.82, height * 0.63),
      Offset(width * 0.66, height * 0.2),
    ];

    return List.generate(assets.length, (index) {
      final asset = assets[index];
      final anchor = anchors[index % anchors.length];
      final size = math.min(54.0, math.max(34.0, petSize * 0.18));
      final phase = index * 0.18;

      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final dy = reduceMotion
              ? 0.0
              : math.sin((_floatController.value + phase) * math.pi * 2) * 4;
          return Positioned(
            left: anchor.dx - size / 2,
            top: anchor.dy - size / 2 + dy,
            width: size,
            height: size,
            child: child!,
          );
        },
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.86,
            child: _SceneImage(asset: asset, fit: BoxFit.contain),
          ),
        ),
      );
    });
  }
}

class _AnimatedPet extends StatelessWidget {
  const _AnimatedPet({
    required this.asset,
    required this.floatController,
    required this.breatheController,
    required this.bounceController,
    required this.reduceMotion,
  });

  final String asset;
  final AnimationController floatController;
  final AnimationController breatheController;
  final AnimationController bounceController;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          floatController,
          breatheController,
          bounceController,
        ]),
        builder: (context, child) {
          final floatY = reduceMotion
              ? 0.0
              : Tween<double>(begin: 0, end: -6)
                    .chain(CurveTween(curve: Curves.easeInOut))
                    .transform(floatController.value);
          final breathe = reduceMotion
              ? 1.0
              : Tween<double>(begin: 1, end: 1.025)
                    .chain(CurveTween(curve: Curves.easeInOut))
                    .transform(breatheController.value);
          final bounce = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(
                begin: 1.0,
                end: 1.08,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
              weight: 45,
            ),
            TweenSequenceItem(
              tween: Tween(
                begin: 1.08,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeOutBack)),
              weight: 55,
            ),
          ]).transform(bounceController.value);

          return Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.scale(
              scale: breathe * bounce,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: AnimatedSwitcher(
          duration: kSceneSwitchDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(begin: 0.96, end: 1).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: Image.asset(
            asset,
            key: ValueKey(asset),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const Icon(
              Icons.pets_rounded,
              size: 112,
              color: Color(0xFFE69AAC),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetSpeechBubble extends StatelessWidget {
  const _PetSpeechBubble({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Stack(
        key: ValueKey(text),
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.fromLTRB(17, 11, 17, 12),
            decoration: BoxDecoration(
              color: context.growthColors.card.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: context.growthColors.card.withValues(alpha: 0.94),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: Color(0xFF5D4E57),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -12,
            width: 34,
            height: 22,
            child: Image.asset(
              PetCenterAssets.bubbleTail,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientParticleLayer extends StatelessWidget {
  const _AmbientParticleLayer({required this.progress, required this.slot});

  final double progress;
  final PetCenterTimeSlot slot;

  @override
  Widget build(BuildContext context) {
    final particles = _particleConfigFor(slot);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: List.generate(particles.length, (index) {
              final particle = particles[index];
              final cycle = (progress + particle.phase) % 1.0;
              final wave = math.sin((cycle + particle.phase) * math.pi * 2);
              final x = constraints.maxWidth * particle.anchor.dx + wave * 8;
              final y =
                  constraints.maxHeight *
                  ((particle.anchor.dy + cycle * particle.travel) % 1.0);
              final opacity = (0.18 + math.sin(cycle * math.pi) * 0.42)
                  .clamp(0.0, 0.62)
                  .toDouble();

              return Positioned(
                left: x,
                top: y,
                width: particle.size,
                height: particle.size,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: wave * 0.18,
                    child: Image.asset(
                      particle.asset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  List<_FloatingParticle> _particleConfigFor(PetCenterTimeSlot slot) {
    final ambientAsset = switch (slot) {
      PetCenterTimeSlot.morning => PetCenterAssets.particlePetals,
      PetCenterTimeSlot.afternoon => PetCenterAssets.particleSparkle,
      PetCenterTimeSlot.evening => PetCenterAssets.particleHeart,
      PetCenterTimeSlot.night => PetCenterAssets.particleStar,
    };
    return [
      _FloatingParticle(ambientAsset, const Offset(0.15, 0.16), 0.26, 0.0, 22),
      _FloatingParticle(ambientAsset, const Offset(0.72, 0.12), 0.3, 0.18, 18),
      _FloatingParticle(ambientAsset, const Offset(0.42, 0.28), 0.24, 0.36, 16),
      _FloatingParticle(ambientAsset, const Offset(0.85, 0.38), 0.22, 0.56, 20),
      _FloatingParticle(
        PetCenterAssets.particleSparkle,
        const Offset(0.24, 0.48),
        0.18,
        0.74,
        15,
      ),
      _FloatingParticle(
        PetCenterAssets.particleStar,
        const Offset(0.6, 0.58),
        0.16,
        0.9,
        14,
      ),
    ];
  }
}

class _FloatingParticle {
  const _FloatingParticle(
    this.asset,
    this.anchor,
    this.travel,
    this.phase,
    this.size,
  );

  final String asset;
  final Offset anchor;
  final double travel;
  final double phase;
  final double size;
}

class _SceneImage extends StatelessWidget {
  const _SceneImage({
    required this.asset,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.opacity = 1,
    this.fallbackColor,
  });

  final String asset;
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      opacity: AlwaysStoppedAnimation(opacity),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) {
        final color = fallbackColor;
        if (color != null) {
          return ColoredBox(color: color);
        }
        return const SizedBox.shrink();
      },
    );
    return RepaintBoundary(child: image);
  }
}

class _TimeTint {
  const _TimeTint({
    required this.background,
    required this.overlayTop,
    required this.overlayBottom,
    required this.accent,
    required this.glowOpacity,
  });

  final Color background;
  final Color overlayTop;
  final Color overlayBottom;
  final Color accent;
  final double glowOpacity;
}

PetCenterTimeSlot _timeSlotForHour(int hour) {
  if (hour >= kMorningStartHour && hour < kAfternoonStartHour) {
    return PetCenterTimeSlot.morning;
  }
  if (hour >= kAfternoonStartHour && hour < kEveningStartHour) {
    return PetCenterTimeSlot.afternoon;
  }
  if (hour >= kEveningStartHour && hour < kNightStartHour) {
    return PetCenterTimeSlot.evening;
  }
  return PetCenterTimeSlot.night;
}

_TimeTint _tintForTime(PetCenterTimeSlot slot) {
  switch (slot) {
    case PetCenterTimeSlot.morning:
      return const _TimeTint(
        background: Color(0xFFFFF1DD),
        overlayTop: Color(0x10FFFFFF),
        overlayBottom: Color(0x28FFE1B9),
        accent: Color(0xFFE7A05F),
        glowOpacity: 0.32,
      );
    case PetCenterTimeSlot.afternoon:
      return const _TimeTint(
        background: Color(0xFFEAF6FF),
        overlayTop: Color(0x18FFFFFF),
        overlayBottom: Color(0x224DB5C7),
        accent: Color(0xFF4FAFC1),
        glowOpacity: 0.24,
      );
    case PetCenterTimeSlot.evening:
      return const _TimeTint(
        background: Color(0xFFFFE0C6),
        overlayTop: Color(0x16FFFFFF),
        overlayBottom: Color(0x2AEF8F72),
        accent: Color(0xFFE88B65),
        glowOpacity: 0.34,
      );
    case PetCenterTimeSlot.night:
      return const _TimeTint(
        background: Color(0xFFDBE0F5),
        overlayTop: Color(0x183A3F78),
        overlayBottom: Color(0x384C558B),
        accent: Color(0xFF737FBD),
        glowOpacity: 0.18,
      );
  }
}
