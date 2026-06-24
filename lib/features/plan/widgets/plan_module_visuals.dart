import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../pet/providers/pet_ai_result_provider.dart';
import '../../pet/providers/pet_orchestrator_provider.dart';
import '../../pet/providers/pet_projection_provider.dart';
import '../../../core/domain/pet/pet_scene_model.dart';
import '../../../core/constants/pet_assets.dart';
import '../utils/plan_module_assets.dart';

class PlanModuleVisualHeader extends ConsumerStatefulWidget {
  const PlanModuleVisualHeader({
    super.key,
    required this.module,
    required this.color,
    this.height,
  });

  final PlanModuleType module;
  final Color color;
  final double? height;

  @override
  ConsumerState<PlanModuleVisualHeader> createState() =>
      _PlanModuleVisualHeaderState();
}

class _PlanModuleVisualHeaderState
    extends ConsumerState<PlanModuleVisualHeader> {
  final _random = math.Random();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _registerAmbient();
    });
    _scheduleNextRotation();
  }

  @override
  void didUpdateWidget(covariant PlanModuleVisualHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module != widget.module) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _registerAmbient();
      });
      _scheduleNextRotation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextRotation() {
    _timer?.cancel();
    // Match the pet scene idle rhythm: slow, random, and system-driven.
    final seconds = 25 + _random.nextInt(21);
    _timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      final states = _petModule.idleStates;
      if (states.length <= 1) return;
      var next = _random.nextInt(states.length);
      if (next == _index) next = (next + 1) % states.length;
      setState(() => _index = next);
      _registerAmbient();
      _scheduleNextRotation();
    });
  }

  void _registerAmbient() {
    final definition = _petModule.definition;
    final idleStates = definition.idleStates;
    final state = idleStates[_index.clamp(0, idleStates.length - 1).toInt()];
    ref
        .read(petOrchestratorProvider.notifier)
        .setModuleAmbient(
          _petModule.name,
          state.assetPath,
          definition.ambientMessages,
        );
  }

  PetModuleType get _petModule => widget.module.petModuleType;

  @override
  Widget build(BuildContext context) {
    final module = _petModule;
    final definition = module.definition;
    final view = ref.watch(modulePetViewProvider(module.name));
    final latestAnalysis = ref.watch(latestPetAnalysisProvider(module.name));
    final idleStates = definition.idleStates;
    final fallbackImage =
        idleStates[_index.clamp(0, idleStates.length - 1).toInt()].assetPath;
    final imagePath = fallbackImage;
    final message =
        latestAnalysis.valueOrNull?.petMessage ??
        view?.bubbleText ??
        definition.welcomeMessage;

    return Semantics(
      button: true,
      label: '打开宠物中心',
      child: GestureDetector(
        onTap: () => context.push('/pet-center'),
        child: Container(
          height: widget.height ?? 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(color: widget.color.withValues(alpha: 0.16)),
            boxShadow: AppShadows.hero(widget.color),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  PlanModuleAssets.premiumV2PetBanner(widget.module),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    PlanModuleAssets.premiumPetBanner(widget.module),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            context.growthColors.card,
                            _parseColor(definition.softColorHex),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 128,
                        child: _FloatingPetImage(
                          imagePath: imagePath,
                          color: widget.color,
                          fallbackImagePath: definition.defaultImagePath,
                          size: 112,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _PetSpeechBubble(
                            moduleLabel: definition.label,
                            message: message,
                            color: widget.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

class _FloatingPetImage extends StatefulWidget {
  const _FloatingPetImage({
    required this.imagePath,
    required this.color,
    required this.fallbackImagePath,
    this.size = 104,
  });

  final String imagePath;
  final Color color;
  final String fallbackImagePath;
  final double size;

  @override
  State<_FloatingPetImage> createState() => _FloatingPetImageState();
}

class _FloatingPetImageState extends State<_FloatingPetImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: widget.size * 0.04,
              child: Container(
                width: widget.size * 0.78,
                height: widget.size * 0.18,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: widget.size * 0.98,
              height: widget.size * 0.98,
              decoration: BoxDecoration(
                color: context.growthColors.card.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(widget.size * 0.30),
                border: Border.all(color: context.growthColors.card, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: context.growthColors.card.withValues(alpha: 0.90),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
            ),
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
              child: Transform.scale(
                scale: 1.08,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    context.growthColors.textOnAccent,
                    BlendMode.srcIn,
                  ),
                  child: _PetAssetImage(
                    imagePath: widget.imagePath,
                    fallbackImagePath: widget.fallbackImagePath,
                    size: widget.size * 0.90,
                  ),
                ),
              ),
            ),
            _PetAssetImage(
              imagePath: widget.imagePath,
              fallbackImagePath: widget.fallbackImagePath,
              size: widget.size * 0.88,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAssetImage extends StatelessWidget {
  const _PetAssetImage({
    required this.imagePath,
    required this.fallbackImagePath,
    required this.size,
  });

  final String imagePath;
  final String fallbackImagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Image.asset(
        fallbackImagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Image.asset(
          PetAssets.commonFallback,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _PetSpeechBubble extends StatelessWidget {
  const _PetSpeechBubble({
    required this.moduleLabel,
    required this.message,
    required this.color,
  });

  final String moduleLabel;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 272),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: context.growthColors.card.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.growthColors.card),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '甜甜',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      moduleLabel,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  message,
                  key: ValueKey(message),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: context.growthColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -8,
          top: 48,
          child: CustomPaint(
            size: const Size(9, 14),
            painter: _BubbleTailPainter(
              bubbleColor: context.growthColors.card.withValues(alpha: 0.93),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color bubbleColor;
  _BubbleTailPainter({required this.bubbleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension PlanModulePetModuleX on PlanModuleType {
  PetModuleType get petModuleType {
    return switch (this) {
      PlanModuleType.study => PetModuleType.study,
      PlanModuleType.fitness => PetModuleType.fitness,
      PlanModuleType.journal => PetModuleType.journal,
      PlanModuleType.diet => PetModuleType.diet,
      PlanModuleType.sleep => PetModuleType.sleep,
    };
  }
}

class PlanModuleActionImageCard extends StatelessWidget {
  const PlanModuleActionImageCard({
    super.key,
    required this.module,
    required this.color,
    required this.onTap,
    this.title,
    this.caption,
    this.buttonLabel,
    this.height,
  });

  final PlanModuleType module;
  final Color color;
  final VoidCallback onTap;
  final String? title;
  final String? caption;
  final String? buttonLabel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title ?? PlanModuleAssets.actionTitle(module),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height ?? 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: context.growthColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xxxl),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                  boxShadow: AppShadows.hero(color),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xxxl),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        PlanModuleAssets.premiumHeroScene(module),
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, _, _) => Image.asset(
                          PlanModuleAssets.premiumV2HeroScene(module),
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, _, _) => DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  color.withValues(alpha: 0.12),
                                  context.growthColors.card,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? 20 : 24,
                            18,
                            isCompact ? 100 : 140,
                            16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ActionCardCopy(
                                  module: module,
                                  color: color,
                                  compact: isCompact,
                                  title: title,
                                  caption: caption,
                                  buttonLabel: buttonLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PlanModuleRecordEntryCard extends StatelessWidget {
  const PlanModuleRecordEntryCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
           decoration: _premiumCardDecoration(color, context),
          child: Row(
            children: [
              _SoftIconTile(color: color, icon: icon, size: 58),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        color: context.growthColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: context.growthColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: context.growthColors.textOnAccent,
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      buttonLabel,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: context.growthColors.textOnAccent,
                        letterSpacing: 0,
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

class PlanModuleWeeklyCard extends StatelessWidget {
  const PlanModuleWeeklyCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.count,
    required this.goal,
    required this.unit,
    required this.onTap,
    this.onLongPress,
  });

  final Color color;
  final IconData icon;
  final String title;
  final int? count;
  final int goal;
  final String unit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final safeCount = count ?? 0;
    final weekdays = const ['一', '二', '三', '四', '五', '六', '日'];
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: _premiumCardDecoration(color, context),
          child: Column(
            children: [
              Row(
                children: [
                  _SoftIconTile(color: color, icon: icon, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: context.growthColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Text(
                    count == null ? '--' : '$safeCount/$goal $unit',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.growthColors.textTertiary,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final completed = index < safeCount;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? color.withValues(alpha: 0.16)
                          : color.withValues(alpha: 0.08),
                      border: Border.all(
                        color: completed
                            ? color.withValues(alpha: 0.22)
                            : color.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        weekdays[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: completed
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: completed
                              ? color
                              : context.growthColors.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftIconTile extends StatelessWidget {
  const _SoftIconTile({
    required this.color,
    required this.icon,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.smd),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

BoxDecoration _premiumCardDecoration(Color color, BuildContext context) {
  return BoxDecoration(
    color: context.growthColors.card,
    borderRadius: BorderRadius.circular(AppRadius.xxxl),
    border: Border.all(color: color.withValues(alpha: 0.12)),
    boxShadow: AppShadows.hero(color),
  );
}

class _ActionCardCopy extends StatelessWidget {
  const _ActionCardCopy({
    required this.module,
    required this.color,
    required this.compact,
    this.title,
    this.caption,
    this.buttonLabel,
  });

  final PlanModuleType module;
  final Color color;
  final bool compact;
  final String? title;
  final String? caption;
  final String? buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? PlanModuleAssets.actionTitle(module),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.growthColors.textPrimary,
            fontSize: compact ? 20 : 24,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption ?? PlanModuleAssets.actionCaption(module),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.growthColors.textSecondary,
            fontSize: compact ? 12 : 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 24,
            vertical: compact ? 11 : 13,
          ),
          decoration: BoxDecoration(
            color: context.growthColors.card.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.growthColors.card),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_actionIcon(module), color: color, size: compact ? 18 : 21),
              SizedBox(width: compact ? 8 : 10),
              Flexible(
                child: Text(
                  buttonLabel ?? PlanModuleAssets.actionButtonLabel(module),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 14 : 17,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _actionIcon(PlanModuleType module) {
    return switch (module) {
      PlanModuleType.study => Icons.timer_rounded,
      PlanModuleType.fitness => Icons.fitness_center_rounded,
      PlanModuleType.journal => Icons.edit_note_rounded,
      PlanModuleType.diet => Icons.water_drop_rounded,
      PlanModuleType.sleep => Icons.bedtime_rounded,
    };
  }
}
