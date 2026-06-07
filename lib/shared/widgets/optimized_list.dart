import 'package:flutter/material.dart';

import 'lazy_load_widget.dart';

/// A high-performance paginated list with shimmer loading, empty state,
/// and automatic "load more" triggering.
///
/// Built on [ListView.builder] with lazy rendering — only visible items
/// are built, keeping memory usage low even with thousands of entries.
///
/// ```dart
/// OptimizedList<String>(
///   items: items,
///   itemBuilder: (context, item, index) => ListTile(title: Text(item)),
///   onLoadMore: () => fetchNextPage(),
///   isLoadingMore: hasMorePages,
///   emptyWidget: const Center(child: Text('No items')),
/// )
/// ```
class OptimizedList<T> extends StatefulWidget {
  const OptimizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.shimmerBuilder,
    this.shimmerCount = 5,
    this.emptyWidget,
    this.separator,
    this.itemExtent,
    this.padding,
    this.scrollController,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.loadMoreThreshold = 200,
    this.cacheExtent,
    this.addAutomaticKeepAlives = false,
    this.addRepaintBoundaries = true,
  });

  /// The data items to render.
  final List<T> items;

  /// Builder for each item widget.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Called when the user scrolls near the bottom and more data should load.
  final VoidCallback? onLoadMore;

  /// Whether a "load more" request is currently in flight.
  final bool isLoadingMore;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Builder for a single shimmer placeholder row. When `null` a default
  /// shimmer is used.
  final Widget Function(BuildContext context, int index)? shimmerBuilder;

  /// Number of shimmer rows to show while the initial load is in progress.
  final int shimmerCount;

  /// Widget to display when [items] is empty and no loading is happening.
  final Widget? emptyWidget;

  /// Optional separator between items.
  final Widget Function(BuildContext context, int index)? separator;

  /// Fixed item extent (height for vertical lists). Improves scroll performance
  /// by skipping per-item layout measurement.
  final double? itemExtent;

  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool reverse;
  final bool? primary;
  final Axis scrollDirection;

  /// Distance from the bottom (in pixels) at which [onLoadMore] fires.
  final double loadMoreThreshold;

  /// Cache extent for the underlying [ListView.builder].
  final double? cacheExtent;

  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;

  @override
  State<OptimizedList<T>> createState() => _OptimizedListState<T>();
}

class _OptimizedListState<T> extends State<OptimizedList<T>> {
  late final ScrollController _scrollController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore == null || !widget.hasMore || widget.isLoadingMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - widget.loadMoreThreshold) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Empty state — no items, not loading.
    if (widget.items.isEmpty && !widget.isLoadingMore) {
      return widget.emptyWidget ?? const _DefaultEmptyState();
    }

    final itemCount = widget.items.length + (widget.hasMore || widget.isLoadingMore ? 1 : 0);

    // With separator: use a two-pass approach (item + separator interleaved).
    if (widget.separator != null) {
      return ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        reverse: widget.reverse,
        primary: widget.primary,
        scrollDirection: widget.scrollDirection,
        cacheExtent: widget.cacheExtent,
        itemCount: itemCount,
        itemBuilder: _buildItem,
        separatorBuilder: widget.separator!,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      reverse: widget.reverse,
      primary: widget.primary,
      scrollDirection: widget.scrollDirection,
      itemExtent: widget.itemExtent,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      itemCount: itemCount,
      itemBuilder: _buildItem,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    // Footer: shimmer or load-more indicator.
    if (index >= widget.items.length) {
      if (widget.isLoadingMore) {
        return widget.shimmerBuilder?.call(context, index) ??
            const _ShimmerRow();
      }
      return const SizedBox.shrink();
    }

    return widget.itemBuilder(context, widget.items[index], index);
  }
}

// =============================================================================
// Default Empty State
// =============================================================================

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无数据',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加一些记录后这里会显示出来',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shimmer Row
// =============================================================================

/// A single shimmer placeholder row used during loading.
class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surfaceContainerLow;

    return ShimmerEffect(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 160,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
