import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../models/music_player_state.dart';
import '../providers/music_player_provider.dart';
import '../utils/music_assets.dart';

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
    final motionOff = MediaQuery.disableAnimationsOf(context);

    return Positioned.fill(
      child: PopScope(
        canPop: !state.isExpanded,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && state.isExpanded) {
            ref.read(musicPlayerProvider.notifier).collapse();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _MusicFloatLayout.from(
              context: context,
              constraints: constraints,
              state: state,
              dragOffset: _dragOffset,
            );
            return Stack(
              children: [
                IgnorePointer(
                  ignoring: !state.isExpanded,
                  child: AnimatedOpacity(
                    duration: motionOff ? Duration.zero : AppMotion.normal,
                    opacity: state.isExpanded ? 1 : 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          ref.read(musicPlayerProvider.notifier).collapse(),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
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
                    onTap: state.isExpanded
                        ? null
                        : () => ref
                              .read(musicPlayerProvider.notifier)
                              .toggleExpanded(),
                    onPanStart: state.isExpanded
                        ? null
                        : (_) => setState(() {
                            _dragOffset = Offset(layout.left, layout.top);
                          }),
                    onPanUpdate: state.isExpanded
                        ? null
                        : (details) => setState(() {
                            final current =
                                _dragOffset ?? Offset(layout.left, layout.top);
                            _dragOffset = layout.clamp(current + details.delta);
                          }),
                    onPanEnd: state.isExpanded
                        ? null
                        : (_) => _finishDrag(layout),
                    child: _MusicFloatCard(state: state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _finishDrag(_MusicFloatLayout layout) {
    final current = _dragOffset ?? Offset(layout.left, layout.top);
    final snapped = layout.snap(current);
    final normalized = layout.toNormalized(snapped);
    setState(() {
      _dragOffset = null;
    });
    ref
        .read(musicPlayerProvider.notifier)
        .setFloatPosition(x: normalized.dx, y: normalized.dy);
  }
}

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

  static _MusicFloatLayout from({
    required BuildContext context,
    required BoxConstraints constraints,
    required MusicPlayerState state,
    required Offset? dragOffset,
  }) {
    final media = MediaQuery.of(context);
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final expandedWidth = math.min(screenWidth - 24, 360.0);
    final collapsedWidth = 92.0;
    final width = state.isExpanded ? expandedWidth : collapsedWidth;
    final height = state.isExpanded ? 418.0 : 132.0;
    const margin = 12.0;
    final bottomReserve = state.isExpanded ? 16.0 : 92.0;
    final minX = margin;
    final maxX = math.max(margin, screenWidth - width - margin);
    final minY = media.padding.top + 8;
    final maxY = math.max(
      minY,
      screenHeight - media.padding.bottom - bottomReserve - height,
    );
    final rawLeft = minX + (maxX - minX) * state.floatX;
    final rawTop = minY + (maxY - minY) * state.floatY;
    final offset = dragOffset ?? Offset(rawLeft, rawTop);
    final clamped = _clampOffset(offset, minX, maxX, minY, maxY);

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
