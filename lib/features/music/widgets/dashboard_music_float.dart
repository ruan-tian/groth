import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../models/music_player_state.dart';
import '../providers/music_player_provider.dart';
import '../utils/default_music_seed.dart';
import '../utils/music_assets.dart';
import '../utils/music_scene.dart';
import 'music_import_destination_sheet.dart';

part 'music_float_card.dart';
part 'music_library_sheet.dart';

class DashboardMusicFloat extends ConsumerStatefulWidget {
  const DashboardMusicFloat({super.key});

  @override
  ConsumerState<DashboardMusicFloat> createState() =>
      _DashboardMusicFloatState();
}

class _DashboardMusicFloatState extends ConsumerState<DashboardMusicFloat> {
  Offset? _dragOffset;
  bool _isRevealed = false;
  Timer? _autoDockTimer;

  @override
  void dispose() {
    _autoDockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MusicPlayerState>(musicPlayerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      ref.read(musicPlayerProvider.notifier).clearError();
    });

    final state = ref.watch(musicPlayerProvider);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final motionOff = MediaQuery.disableAnimationsOf(context);
          final layout = _MusicFloatLayout.from(
            context: context,
            constraints: constraints,
            state: state,
            dragOffset: _dragOffset,
            isRevealed: _isRevealed || _dragOffset != null,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (layout.isRevealed)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _dock,
                    child: const SizedBox.expand(),
                  ),
                ),
              AnimatedPositioned(
                duration: motionOff || _dragOffset != null
                    ? Duration.zero
                    : AppMotion.slow,
                curve: AppMotion.standard,
                left: layout.left,
                top: layout.top,
                width: layout.width,
                height: layout.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_isRevealed) {
                      _openPlayerSheet(context);
                    } else {
                      _revealTemporarily();
                    }
                  },
                  onPanStart: (_) => setState(() {
                    _autoDockTimer?.cancel();
                    _dragOffset = Offset(layout.left, layout.top);
                    _isRevealed = true;
                  }),
                  onPanUpdate: (details) => setState(() {
                    final current =
                        _dragOffset ?? Offset(layout.left, layout.top);
                    _dragOffset = layout.clamp(current + details.delta);
                  }),
                  onPanEnd: (_) => _finishDrag(layout),
                  child: _MusicFloatCard(
                    state: state,
                    side: layout.side,
                    isRevealed: layout.isRevealed,
                    onReveal: _revealTemporarily,
                    onOpenPlayer: () => _openPlayerSheet(context),
                    onImport: () =>
                        showMusicImportDestinationSheet(context, ref),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPlayerSheet(BuildContext context) async {
    final controller = ref.read(musicPlayerProvider.notifier);
    if (ref.read(musicPlayerProvider).isExpanded) return;

    _autoDockTimer?.cancel();
    if (mounted) setState(() => _isRevealed = false);
    controller.toggleExpanded();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.growthColors.shadow.withValues(alpha: 0.18),
      builder: (_) => const _MusicPlayerSheet(),
    );
    if (!mounted) return;
    controller.collapse();
  }

  void _finishDrag(_MusicFloatLayout layout) {
    final current = _dragOffset ?? Offset(layout.left, layout.top);
    final snapped = layout.snap(current);
    final normalized = layout.toNormalized(snapped);
    setState(() {
      _dragOffset = null;
      _isRevealed = true;
    });
    ref
        .read(musicPlayerProvider.notifier)
        .setFloatPosition(x: normalized.dx, y: normalized.dy);
    _scheduleAutoDock();
  }

  void _revealTemporarily() {
    if (!mounted) return;
    setState(() => _isRevealed = true);
    _scheduleAutoDock();
  }

  void _dock() {
    _autoDockTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _dragOffset = null;
      _isRevealed = false;
    });
  }

  void _scheduleAutoDock() {
    _autoDockTimer?.cancel();
    _autoDockTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _isRevealed = false);
    });
  }
}

enum _MusicDockSide { left, right }

class _MusicFloatLayout {
  const _MusicFloatLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.screenWidth,
    required this.side,
    required this.isRevealed,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double screenWidth;
  final _MusicDockSide side;
  final bool isRevealed;

  static _MusicFloatLayout from({
    required BuildContext context,
    required BoxConstraints constraints,
    required MusicPlayerState state,
    required Offset? dragOffset,
    required bool isRevealed,
  }) {
    final media = MediaQuery.of(context);
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final compact = screenWidth < 380;
    final width = isRevealed
        ? math.min(compact ? 216.0 : 244.0, screenWidth - 16.0)
        : 46.0;
    final height = isRevealed ? 66.0 : 68.0;
    final handlePeek = compact ? 24.0 : 26.0;
    final edgeInset = width - handlePeek;
    const bottomReserve = 106.0;
    final minX = isRevealed ? 0.0 : -edgeInset;
    final maxX = isRevealed
        ? math.max(0.0, screenWidth - width)
        : math.max(minX, screenWidth - handlePeek);
    final minY = media.padding.top + 8;
    final maxY = math.max(
      minY,
      screenHeight - media.padding.bottom - bottomReserve - height,
    );
    final side = state.floatX < 0.5
        ? _MusicDockSide.left
        : _MusicDockSide.right;
    final rawLeft = side == _MusicDockSide.left ? minX : maxX;
    final rawTop = minY + (maxY - minY) * state.floatY;
    final offset = dragOffset ?? Offset(rawLeft, rawTop);
    final clamped = _clampOffset(offset, minX, maxX, minY, maxY);
    final effectiveSide = clamped.dx + width / 2 < screenWidth / 2
        ? _MusicDockSide.left
        : _MusicDockSide.right;

    return _MusicFloatLayout(
      left: clamped.dx,
      top: clamped.dy,
      width: width,
      height: height,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      screenWidth: screenWidth,
      side: effectiveSide,
      isRevealed: isRevealed,
    );
  }

  Offset clamp(Offset value) => _clampOffset(value, minX, maxX, minY, maxY);

  Offset snap(Offset value) {
    final clamped = clamp(value);
    final centerX = clamped.dx + width / 2;
    final nextX = centerX < screenWidth / 2 ? minX : maxX;
    return Offset(nextX, clamped.dy);
  }

  Offset toNormalized(Offset value) {
    final clamped = clamp(value);
    final xSpan = math.max(1, maxX - minX);
    final ySpan = math.max(1, maxY - minY);
    return Offset(
      ((clamped.dx - minX) / xSpan).clamp(0.0, 1.0),
      ((clamped.dy - minY) / ySpan).clamp(0.0, 1.0),
    );
  }

  static Offset _clampOffset(
    Offset value,
    double minX,
    double maxX,
    double minY,
    double maxY,
  ) {
    return Offset(
      value.dx.clamp(minX, maxX).toDouble(),
      value.dy.clamp(minY, maxY).toDouble(),
    );
  }
}
