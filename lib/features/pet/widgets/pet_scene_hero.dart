import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'particle_burst.dart';

// =============================================================================
// Constants — named, documented, zero magic numbers
// =============================================================================

// -- Time-of-day buckets (hour ranges, start-inclusive, end-exclusive) --------

/// Morning: 06:00 – 11:59
const int kMorningStartHour = 6;
const int kAfternoonStartHour = 12;
const int kEveningStartHour = 17;
const int kNightStartHour = 21;

// -- Gradient palettes per time-of-day ---------------------------------------

/// Warm peach gradient for morning (6:00–12:00).
const List<Color> kMorningGradient = [
  Color(0xFFFFF0E6),
  Color(0xFFFFE4CC),
];

/// Soft blue gradient for afternoon (12:00–17:00).
const List<Color> kAfternoonGradient = [
  Color(0xFFE8F0FE),
  Color(0xFFD4E4FF),
];

/// Lavender gradient for evening (17:00–21:00).
const List<Color> kEveningGradient = [
  Color(0xFFF0E6FF),
  Color(0xFFE0D4F5),
];

/// Deep indigo gradient for night (21:00–6:00).
const List<Color> kNightGradient = [
  Color(0xFFE0E0F0),
  Color(0xFFC8C8E0),
];

// -- Pet image assets per time-of-day ----------------------------------------

/// Morning pet image path.
const String kPetImageMorning = 'assets/pet/emotions/打招呼.png';

/// Afternoon pet image path.
const String kPetImageAfternoon = 'assets/pet/life/敲键盘.png';

/// Evening pet image path.
const String kPetImageEvening = 'assets/pet/life/听音乐.png';

/// Night pet image path.
const String kPetImageNight = 'assets/pet/emotions/好困.png';

// -- Pet image dimensions ----------------------------------------------------

/// Width and height of the pet image (square).
const double kPetImageSize = 160.0;

// -- Floating animation -------------------------------------------------------

/// Duration of one float cycle (up or down).
const Duration kFloatDuration = Duration(seconds: 3);

/// Maximum vertical offset for the float animation (negative = up).
const double kFloatOffsetY = -4.0;

// -- Breathing animation ------------------------------------------------------

/// Duration of one breath cycle (expand or contract).
const Duration kBreatheDuration = Duration(seconds: 4);

/// Maximum scale factor for the breathing animation.
const double kBreatheMaxScale = 1.03;

// -- Tap bounce animation -----------------------------------------------------

/// Duration of the tap-bounce scale animation.
const Duration kBounceDuration = Duration(milliseconds: 300);

/// Peak scale factor when the pet bounces on tap.
const double kBouncePeakScale = 1.1;

// -- Speech bubble ------------------------------------------------------------

/// Border radius of the speech bubble.
const double kBubbleBorderRadius = 16.0;

/// Background opacity of the speech bubble.
const double kBubbleBackgroundOpacity = 0.9;

/// Font size for the bubble message text.
const double kBubbleFontSize = 13.0;

/// Color for the bubble message text.
const Color kBubbleTextColor = Color(0xFF5D4E37);

/// Width of the triangle tail at its base.
const double kTailWidth = 12.0;

/// Height of the triangle tail.
const double kTailHeight = 8.0;

// -- Message rotation ---------------------------------------------------------

/// Interval between message rotations.
const Duration kMessageRotationInterval = Duration(minutes: 5);

// -- Decoration emoji ---------------------------------------------------------

/// Font size for floating decoration emoji.
const double kDecorationFontSize = 20.0;

/// Opacity for floating decoration emoji.
const double kDecorationOpacity = 0.7;

// -- Ground gradient ----------------------------------------------------------

/// The warm color the ground gradient fades to.
const Color kGroundColor = Color(0xFFF5EDE4);

/// Fraction of the hero height occupied by the ground gradient.
const double kGroundHeightFraction = 0.12;

// =============================================================================
// Time-of-day helpers
// =============================================================================

/// Represents the four time-of-day periods used for theming.
///
/// Named `PetTimeOfDay` to avoid clashing with Flutter's built-in [TimeOfDay].
enum PetTimeOfDay {
  morning,
  afternoon,
  evening,
  night,
}

/// Returns the [PetTimeOfDay] for the given [hour] (0–23).
PetTimeOfDay _petTimeOfDayForHour(int hour) {
  if (hour >= kMorningStartHour && hour < kAfternoonStartHour) {
    return PetTimeOfDay.morning;
  } else if (hour >= kAfternoonStartHour && hour < kEveningStartHour) {
    return PetTimeOfDay.afternoon;
  } else if (hour >= kEveningStartHour && hour < kNightStartHour) {
    return PetTimeOfDay.evening;
  } else {
    return PetTimeOfDay.night;
  }
}

/// Returns the gradient colors for the given [PetTimeOfDay].
List<Color> _gradientColorsFor(PetTimeOfDay tod) {
  switch (tod) {
    case PetTimeOfDay.morning:
      return kMorningGradient;
    case PetTimeOfDay.afternoon:
      return kAfternoonGradient;
    case PetTimeOfDay.evening:
      return kEveningGradient;
    case PetTimeOfDay.night:
      return kNightGradient;
  }
}

/// Returns the pet image asset path for the given [PetTimeOfDay].
String _petImageFor(PetTimeOfDay tod) {
  switch (tod) {
    case PetTimeOfDay.morning:
      return kPetImageMorning;
    case PetTimeOfDay.afternoon:
      return kPetImageAfternoon;
    case PetTimeOfDay.evening:
      return kPetImageEvening;
    case PetTimeOfDay.night:
      return kPetImageNight;
  }
}

/// Returns the message pool for the given [PetTimeOfDay].
List<String> _messagesFor(PetTimeOfDay tod) {
  switch (tod) {
    case PetTimeOfDay.morning:
      return const [
        '早安！新的一天开始了～',
        '早上好，今天也要加油！',
        '甜甜等你好久了～',
      ];
    case PetTimeOfDay.afternoon:
      return const [
        '下午好，继续加油！',
        '学习辛苦啦～',
        '要不要休息一下？',
      ];
    case PetTimeOfDay.evening:
      return const [
        '晚上好，今天辛苦了',
        '放松一下吧～',
        '回顾一下今天的收获？',
      ];
    case PetTimeOfDay.night:
      return const [
        '该睡觉了哦～',
        '晚安，明天见！',
        '今天也辛苦了',
      ];
  }
}

// =============================================================================
// Decoration configuration per level range
// =============================================================================

/// A decoration item: an emoji and the anchor position around the pet.
class _DecorationConfig {
  const _DecorationConfig({
    required this.emoji,
    required this.anchor,
    required this.duration,
  });

  final String emoji;

  /// Normalized position relative to the pet center:
  /// x: -1.0 (far left) → 1.0 (far right)
  /// y: -1.0 (above) → 1.0 (below)
  final Offset anchor;

  /// Float animation duration for this decoration.
  final Duration duration;
}

/// Returns the decoration configs for the given [level].
List<_DecorationConfig> _decorationsForLevel(int level) {
  if (level >= 20) {
    return const [
      _DecorationConfig(
        emoji: '📚',
        anchor: Offset(-1.2, -0.8),
        duration: Duration(seconds: 3),
      ),
      _DecorationConfig(
        emoji: '✏️',
        anchor: Offset(1.2, -0.8),
        duration: Duration(seconds: 4),
      ),
      _DecorationConfig(
        emoji: '🎯',
        anchor: Offset(-1.2, 0.8),
        duration: Duration(seconds: 3, milliseconds: 500),
      ),
      _DecorationConfig(
        emoji: '⭐',
        anchor: Offset(1.2, 0.8),
        duration: Duration(seconds: 5),
      ),
      _DecorationConfig(
        emoji: '🏆',
        anchor: Offset(1.4, 0.0),
        duration: Duration(seconds: 4, milliseconds: 200),
      ),
    ];
  } else if (level >= 11) {
    return const [
      _DecorationConfig(
        emoji: '📚',
        anchor: Offset(-1.2, -0.8),
        duration: Duration(seconds: 3),
      ),
      _DecorationConfig(
        emoji: '✏️',
        anchor: Offset(1.2, -0.8),
        duration: Duration(seconds: 4),
      ),
      _DecorationConfig(
        emoji: '🎯',
        anchor: Offset(-1.2, 0.8),
        duration: Duration(seconds: 3, milliseconds: 500),
      ),
      _DecorationConfig(
        emoji: '⭐',
        anchor: Offset(1.2, 0.8),
        duration: Duration(seconds: 5),
      ),
    ];
  } else if (level >= 6) {
    return const [
      _DecorationConfig(
        emoji: '📚',
        anchor: Offset(-1.2, -0.8),
        duration: Duration(seconds: 3),
      ),
      _DecorationConfig(
        emoji: '✏️',
        anchor: Offset(1.2, -0.8),
        duration: Duration(seconds: 4),
      ),
      _DecorationConfig(
        emoji: '🎯',
        anchor: Offset(1.2, 0.8),
        duration: Duration(seconds: 3, milliseconds: 500),
      ),
    ];
  } else {
    // Level 1–5: 2 decorations
    return const [
      _DecorationConfig(
        emoji: '📚',
        anchor: Offset(-1.2, -0.6),
        duration: Duration(seconds: 3),
      ),
      _DecorationConfig(
        emoji: '✏️',
        anchor: Offset(1.2, -0.6),
        duration: Duration(seconds: 4),
      ),
    ];
  }
}

// =============================================================================
// Speech bubble tail painter
// =============================================================================

/// Paints a small upward-pointing triangle tail for the speech bubble.
class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2 - kTailWidth / 2, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width / 2 + kTailWidth / 2, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

// =============================================================================
// PetSceneHero widget
// =============================================================================

/// The hero section of the pet center page — the top 40% where the pet "lives".
///
/// Displays a time-aware gradient background, the pet image with floating and
/// breathing animations, a rotating speech bubble, level-based decorations,
/// and tap-to-burst particle effects.
class PetSceneHero extends ConsumerStatefulWidget {
  const PetSceneHero({
    super.key,
    required this.level,
    required this.petName,
  });

  /// Current pet level — controls decoration density.
  final int level;

  /// Pet name — used in speech bubble messages.
  final String petName;

  @override
  ConsumerState<PetSceneHero> createState() => _PetSceneHeroState();
}

class _PetSceneHeroState extends ConsumerState<PetSceneHero>
    with TickerProviderStateMixin {
  // -- Animation controllers --------------------------------------------------

  /// Controls the gentle vertical float of the pet.
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  /// Controls the subtle breathing scale of the pet.
  late final AnimationController _breatheController;
  late final Animation<double> _breatheAnimation;

  /// Controls the tap-bounce scale of the pet.
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  // -- Particle burst trigger -------------------------------------------------

  /// ValueNotifier toggled on each tap to fire a [ParticleBurst].
  late final ValueNotifier<bool> _burstTrigger;

  /// Alternates between heart and star particles on successive taps.
  bool _nextBurstIsHeart = true;

  /// The particle type for the current (most recent) burst.
  ParticleType _activeBurstType = ParticleType.hearts;

  /// The center position of the latest tap (for particle origin).
  Offset _burstCenter = Offset.zero;

  // -- Message rotation -------------------------------------------------------

  /// Timer that rotates the speech bubble message.
  Timer? _messageTimer;

  /// Index into the current time-of-day message pool.
  int _messageIndex = 0;

  /// The currently displayed message text.
  late String _currentMessage;

  // -- Decoration float controllers -------------------------------------------

  /// One controller per decoration emoji for independent floating.
  final List<AnimationController> _decorationControllers = [];
  final List<Animation<double>> _decorationAnimations = [];

  // -- Time-of-day snapshot ---------------------------------------------------

  /// Captured once at init; updates on message rotation boundary.
  late PetTimeOfDay _tod;

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _tod = _petTimeOfDayForHour(DateTime.now().hour);

    // -- Float animation ------------------------------------------------------
    _floatController = AnimationController(
      vsync: this,
      duration: kFloatDuration,
    );
    _floatAnimation = Tween<double>(
      begin: 0,
      end: kFloatOffsetY,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    _floatController.repeat(reverse: true);

    // -- Breathe animation ----------------------------------------------------
    _breatheController = AnimationController(
      vsync: this,
      duration: kBreatheDuration,
    );
    _breatheAnimation = Tween<double>(
      begin: 1.0,
      end: kBreatheMaxScale,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));
    _breatheController.repeat(reverse: true);

    // -- Bounce animation (one-shot, triggered by tap) ------------------------
    _bounceController = AnimationController(
      vsync: this,
      duration: kBounceDuration,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: kBouncePeakScale)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: kBouncePeakScale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_bounceController);

    // -- Particle burst -------------------------------------------------------
    _burstTrigger = ValueNotifier<bool>(false);

    // -- Decoration animations ------------------------------------------------
    _initDecorationAnimations();

    // -- Message rotation -----------------------------------------------------
    _currentMessage = _messagesFor(_tod).first;
    _messageTimer = Timer.periodic(kMessageRotationInterval, (_) {
      _rotateMessage();
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _floatController.dispose();
    _breatheController.dispose();
    _bounceController.dispose();
    _burstTrigger.dispose();
    for (final c in _decorationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ===========================================================================
  // Decoration setup
  // ===========================================================================

  /// Creates one [AnimationController] per decoration emoji.
  void _initDecorationAnimations() {
    final decorations = _decorationsForLevel(widget.level);
    for (final deco in decorations) {
      final controller = AnimationController(
        vsync: this,
        duration: deco.duration,
      );
      final animation = Tween<double>(
        begin: 0,
        end: -3.0, // Each decoration floats up by 3px
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      controller.repeat(reverse: true);
      _decorationControllers.add(controller);
      _decorationAnimations.add(animation);
    }
  }

  // ===========================================================================
  // Message rotation
  // ===========================================================================

  void _rotateMessage() {
    final messages = _messagesFor(_tod);
    setState(() {
      _messageIndex = (_messageIndex + 1) % messages.length;
      _currentMessage = messages[_messageIndex];
    });
  }

  // ===========================================================================
  // Tap handling
  // ===========================================================================

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();

    // Determine burst type BEFORE toggling so this burst uses the current type.
    _activeBurstType =
        _nextBurstIsHeart ? ParticleType.hearts : ParticleType.stars;

    // Fire particle burst at the tap position.
    _burstCenter = details.localPosition;
    _burstTrigger.value = !_burstTrigger.value;

    // Toggle for the NEXT tap.
    _nextBurstIsHeart = !_nextBurstIsHeart;

    // Trigger pet bounce.
    _bounceController.forward(from: 0);
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final gradientColors = _gradientColorsFor(_tod);
    final petImagePath = _petImageFor(_tod);

    return LayoutBuilder(
      builder: (context, constraints) {
        final heroWidth = constraints.maxWidth;
        final heroHeight = constraints.maxHeight;
        final petCenter = Offset(heroWidth / 2, heroHeight * 0.42);

        return GestureDetector(
          onTapDown: _handleTapDown,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // -- Layer 0: Time-aware gradient background --------------------
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // -- Layer 1: Ground / floor illusion ---------------------------
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: heroHeight * kGroundHeightFraction,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kGroundColor.withValues(alpha: 0.0),
                        kGroundColor.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // -- Layer 2: Floating decorations ------------------------------
              ..._buildDecorationLayer(petCenter),

              // -- Layer 3: Pet image with float + breathe + bounce -----------
              Positioned(
                left: petCenter.dx - kPetImageSize / 2,
                top: petCenter.dy - kPetImageSize / 2,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _floatAnimation,
                    _breatheAnimation,
                    _bounceAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: Transform.scale(
                        scale: _breatheAnimation.value * _bounceAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: kPetImageSize,
                    height: kPetImageSize,
                    child: Image.asset(
                      petImagePath,
                      width: kPetImageSize,
                      height: kPetImageSize,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            '🐱',
                            style: TextStyle(fontSize: 80),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // -- Layer 4: Speech bubble with tail ---------------------------
              Positioned(
                left: petCenter.dx - 80,
                top: petCenter.dy + kPetImageSize / 2 + 12,
                child: _buildSpeechBubble(),
              ),

              // -- Layer 5: Particle burst overlay ----------------------------
              Positioned.fill(
                child: ParticleBurst(
                  trigger: _burstTrigger,
                  center: _burstCenter,
                  type: _activeBurstType,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Sub-widgets
  // ===========================================================================

  /// Builds the speech bubble with a triangle tail pointing up.
  Widget _buildSpeechBubble() {
    final bubbleColor = Colors.white.withValues(alpha: kBubbleBackgroundOpacity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Triangle tail (points up toward the pet).
        SizedBox(
          width: kTailWidth,
          height: kTailHeight,
          child: CustomPaint(
            painter: _BubbleTailPainter(color: bubbleColor),
          ),
        ),
        // Bubble body.
        Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(kBubbleBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _currentMessage,
              key: ValueKey(_currentMessage),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: kBubbleFontSize,
                color: kBubbleTextColor,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the floating decoration emoji layer.
  List<Widget> _buildDecorationLayer(Offset petCenter) {
    final decoConfigs = _decorationsForLevel(widget.level);
    final List<Widget> widgets = [];
    final spreadX = kPetImageSize * 0.85;
    final spreadY = kPetImageSize * 0.7;

    for (var i = 0; i < decoConfigs.length; i++) {
      if (i >= _decorationAnimations.length) break;

      final deco = decoConfigs[i];
      final dx = petCenter.dx + deco.anchor.dx * spreadX;
      final dy = petCenter.dy + deco.anchor.dy * spreadY;

      widgets.add(
        AnimatedBuilder(
          animation: _decorationAnimations[i],
          builder: (context, child) {
            return Positioned(
              left: dx - 14,
              top: dy - 14 + _decorationAnimations[i].value,
              child: child!,
            );
          },
          child: Opacity(
            opacity: kDecorationOpacity,
            child: Text(
              deco.emoji,
              style: const TextStyle(fontSize: kDecorationFontSize),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}
