import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';

/// Unified statistics summary card for daily/weekly/monthly/yearly stats pages.
///
/// Displays a metric with icon, label, formatted value, optional trend arrow,
/// and optional progress bar. Apple Health inspired layout.
class StatsSummaryCard extends ConsumerWidget {
  const StatsSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.unit,
    this.trend,
    this.progress,
    this.onTap,
  });

  /// Leading icon displayed in a tinted container.
  final IconData icon;

  /// Short label beneath the icon (e.g. "学习时长").
  final String label;

  /// Pre-formatted value string (e.g. "4.2").
  final String value;

  /// Accent color for the value text, icon tint, and progress bar.
  final Color color;

  /// Optional unit displayed inline after [value] with lighter opacity.
  final String? unit;

  /// Trend percentage. 0.12 = +12%, -0.05 = -5%. Null hides the arrow.
  final double? trend;

  /// Progress 0.0–1.0 for the bar. Null hides the bar entirely.
  final double? progress;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.growthColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.growthColors.border, width: 0.6),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon + label + trend ──
            _buildHeader(context),
            const SizedBox(height: AppSpacing.md),
            // ── Value ──
            _buildValue(),
            const SizedBox(height: AppSpacing.md),
            // ── Progress bar (optional) ──
            if (progress != null) _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header row
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Icon container
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Label
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.growthColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Trend badge
        if (trend != null) _buildTrendBadge(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Trend arrow + percentage
  // ---------------------------------------------------------------------------
  Widget _buildTrendBadge(BuildContext context) {
    final pct = trend!;
    final isZero = pct.abs() < 0.001;
    final isPositive = pct > 0;

    final Color trendColor;
    if (isZero) {
      trendColor = context.growthColors.textTertiary;
    } else if (isPositive) {
      trendColor = context.growthColors.success;
    } else {
      trendColor = context.growthColors.danger;
    }

    final IconData arrow;
    if (isZero) {
      arrow = Icons.remove;
    } else if (isPositive) {
      arrow = Icons.arrow_upward;
    } else {
      arrow = Icons.arrow_downward;
    }

    final String sign = isPositive ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(arrow, size: 12, color: trendColor),
        const SizedBox(width: 2),
        Text(
          '$sign${(pct * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: trendColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Large value + optional unit
  // ---------------------------------------------------------------------------
  Widget _buildValue() {
    return Padding(
      padding: const EdgeInsets.only(left: 2), // align with icon
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _buildAnimatedValue(
                value,
                TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
              ),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                unit!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Animated value with count-up effect
  // ---------------------------------------------------------------------------
  Widget _buildAnimatedValue(String value, TextStyle style) {
    final match = RegExp(r'^([\d,\.]+)').firstMatch(value);
    if (match == null) return Text(value, style: style);

    final numericStr = match.group(1)!;
    final suffix = value.substring(match.end);
    final cleanNum = numericStr.replaceAll(',', '');
    final targetValue = double.tryParse(cleanNum);
    if (targetValue == null || targetValue == 0) {
      return Text(value, style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetValue),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, animatedValue, child) {
        String animatedStr;
        if (numericStr.contains('.')) {
          animatedStr = animatedValue.toStringAsFixed(1);
        } else if (numericStr.contains(',')) {
          animatedStr = _formatWithComma(animatedValue.toInt());
        } else {
          animatedStr = animatedValue.toInt().toString();
        }
        return Text(animatedStr + suffix, style: style);
      },
    );
  }

  String _formatWithComma(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Progress bar
  // ---------------------------------------------------------------------------
  Widget _buildProgressBar(BuildContext context) {
    final clamped = progress!.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: clamped,
          backgroundColor: context.growthColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ),
    );
  }
}
