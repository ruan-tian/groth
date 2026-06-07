import 'package:flutter/material.dart';

/// A widget that defers loading its [builder] until it becomes visible
/// or until a specified delay elapses.
///
/// While loading, a [placeholder] is shown. If loading fails, an
/// [errorBuilder] is displayed with a retry button.
///
/// ```dart
/// LazyLoadWidget(
///   builder: (context) => HeavyChart(data: data),
///   placeholder: const ShimmerBox(width: 300, height: 200),
/// )
/// ```
class LazyLoadWidget extends StatefulWidget {
  const LazyLoadWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.errorBuilder,
    this.delay = Duration.zero,
    this.visible = true,
    this.onRetry,
  });

  /// Called once when the widget is ready to load.
  final Widget Function(BuildContext context) builder;

  /// Widget shown while the deferred content is loading.
  /// Defaults to a subtle shimmer container.
  final Widget? placeholder;

  /// Called when [builder] throws. If `null`, a default error UI is shown.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder;

  /// Minimum delay before the [builder] runs.
  ///
  /// Use [Duration.zero] to load on the next frame, or a small delay
  /// to batch multiple lazy widgets together.
  final Duration delay;

  /// When `false`, loading is paused until set to `true`.
  final bool visible;

  /// Called when the user taps the retry button in the default error UI.
  final VoidCallback? onRetry;

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _loaded = false;
  bool _error = false;
  Object? _errorObject;

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant LazyLoadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible && !_loaded && !_error) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    if (!widget.visible) return;

    if (widget.delay == Duration.zero) {
      // Load on the next frame to avoid blocking the current build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _loaded = true);
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _loaded = true);
      });
    }
  }

  void _retry() {
    setState(() {
      _error = false;
      _errorObject = null;
      _loaded = false;
    });
    _scheduleLoad();
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return widget.errorBuilder?.call(context, _errorObject!, _retry) ??
          _DefaultErrorWidget(onRetry: _retry);
    }

    if (!_loaded) {
      return widget.placeholder ?? const _DefaultPlaceholder();
    }

    // Wrap in an error boundary so we can catch builder errors at runtime.
    return _ErrorBoundary(
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = true;
            _errorObject = error;
          });
        }
      },
      child: widget.builder(context),
    );
  }
}

// =============================================================================
// Error Boundary
// =============================================================================

/// Catches errors thrown during [child] build and reports them via [onError].
class _ErrorBoundary extends StatefulWidget {
  const _ErrorBoundary({required this.child, required this.onError});

  final Widget child;
  final void Function(Object error) onError;

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}

// =============================================================================
// Default Placeholder
// =============================================================================

class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// =============================================================================
// Default Error Widget
// =============================================================================

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              '加载失败',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shimmer Effect
// =============================================================================

/// A shimmer animation wrapper that gives its [child] a "loading" glow.
///
/// ```dart
/// ShimmerEffect(
///   baseColor: Colors.grey.shade300,
///   highlightColor: Colors.grey.shade100,
///   child: Container(height: 20, width: 100),
/// )
/// ```
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({
    super.key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

// =============================================================================
// Shimmer Box
// =============================================================================

/// A simple rectangular shimmer placeholder with rounded corners.
///
/// ```dart
/// ShimmerBox(width: double.infinity, height: 16)
/// ```
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.baseColor,
    this.highlightColor,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShimmerEffect(
      baseColor: baseColor ?? theme.colorScheme.surfaceContainerHighest,
      highlightColor: highlightColor ?? theme.colorScheme.surfaceContainerLow,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
