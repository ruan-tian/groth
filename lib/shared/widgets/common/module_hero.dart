import 'package:flutter/material.dart';

import '../../../core/constants/pet_assets.dart';

import '../../../app/design/design.dart';
import 'growth_card.dart';

class ModuleHero extends StatelessWidget {
  const ModuleHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.asset = PetAssets.commonFallback,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String asset;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GrowthCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
      backgroundColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: context.growthColors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Image.asset(
                asset,
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.auto_awesome_rounded, color: color, size: 34),
              ),
        ],
      ),
    );
  }
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GrowthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleMetricChip {
  const ModuleMetricChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}

BoxDecoration _moduleCardDecoration(Color color, BuildContext context) {
  return BoxDecoration(
    color: context.growthColors.card,
    borderRadius: BorderRadius.circular(AppRadius.xxxl),
    border: Border.all(color: color.withValues(alpha: 0.12)),
    boxShadow: AppShadows.hero(color),
  );
}

class ModuleHeroCard extends StatelessWidget {
  const ModuleHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.primaryValue,
    required this.primaryLabel,
    required this.color,
    this.progress,
    this.targetLabel,
    this.metrics = const [],
    this.onTargetTap,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String primaryValue;
  final String primaryLabel;
  final Color color;
  final double? progress;
  final String? targetLabel;
  final List<ModuleMetricChip> metrics;
  final VoidCallback? onTargetTap;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardPadding = compact
        ? const EdgeInsets.fromLTRB(14, 14, 14, 12)
        : const EdgeInsets.fromLTRB(18, 18, 18, 16);
    final iconBoxSize = compact ? 38.0 : 44.0;
    final iconSize = compact ? 20.0 : 23.0;
    final titleSize = compact ? 15.0 : 16.0;
    final numberSize = compact ? 26.0 : 30.0;
    final sectionGap = compact ? 10.0 : AppSpacing.md;
    final metricTopGap = compact ? 12.0 : AppSpacing.lg;
    final metricIconSize = compact ? 16.0 : 18.0;
    final metricValueSize = compact ? 13.5 : 15.0;
    final metricLabelSize = compact ? 10.0 : 11.0;
    final progressHeight = compact ? 5.0 : 7.0;

    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: cardPadding,
          decoration: _moduleCardDecoration(color, context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: context.growthColors.card.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.mlg),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  if (onTargetTap != null)
                    Semantics(
                      button: true,
                      label: '设置目标',
                      child: GestureDetector(
                        onTap: onTargetTap,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: context.growthColors.card.withValues(
                              alpha: 0.82,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.smd),
                            border: Border.all(
                              color: color.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: sectionGap),
              Text(
                primaryValue,
                style: AppTextStyles.numberLarge.copyWith(
                  color: color,
                  fontSize: numberSize,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(primaryLabel, style: AppTextStyles.caption),
              if (progress != null || targetLabel != null) ...[
                SizedBox(height: sectionGap),
                if (progress != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 4 : 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: progressHeight,
                        backgroundColor: color.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                if (targetLabel != null)
                  Row(
                    children: [
                      if (progress != null)
                        Text(
                          '${(progress! * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      if (progress != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetLabel!,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
              if (metrics.isNotEmpty) ...[
                SizedBox(height: metricTopGap),
                Container(height: 1, color: color.withValues(alpha: 0.10)),
                SizedBox(height: compact ? 10 : AppSpacing.md),
                Row(
                  children: metrics.map((m) {
                    return Expanded(
                      child: Column(
                        children: [
                          Icon(
                            m.icon,
                            size: metricIconSize,
                            color: color.withValues(alpha: 0.82),
                          ),
                          SizedBox(height: compact ? 3 : 4),
                          Text(
                            m.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: metricValueSize,
                              fontWeight: FontWeight.w800,
                              color: context.growthColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: compact ? 1 : 2),
                          Text(
                            m.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: metricLabelSize,
                              color: context.growthColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleRecordsCard extends StatelessWidget {
  const ModuleRecordsCard({
    super.key,
    required this.title,
    required this.action,
    required this.onActionTap,
    required this.color,
    required this.recordCount,
    this.maxVisible = 5,
    this.isExpanded = false,
    this.onToggleExpand,
    this.children = const [],
  });

  final String title;
  final String action;
  final VoidCallback onActionTap;
  final Color color;
  final int recordCount;
  final int maxVisible;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final List<Widget> children;

  bool get _hasExpand => recordCount > maxVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _moduleCardDecoration(color, context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.growthColors.card.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(AppRadius.smd),
                  border: Border.all(color: color.withValues(alpha: 0.12)),
                ),
                child: Icon(Icons.history_rounded, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onActionTap,
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text(
                  action,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
          if (_hasExpand && onToggleExpand != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              button: true,
              label: isExpanded ? '收起' : '查看更多',
              child: GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.growthColors.card.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(AppRadius.mlg),
                    border: Border.all(color: color.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isExpanded
                            ? '收起'
                            : '查看更多 (${recordCount - maxVisible})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SoftProgressLine extends StatelessWidget {
  const SoftProgressLine({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
