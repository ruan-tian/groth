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
              color: Colors.white,
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

BoxDecoration _moduleCardDecoration(Color color) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.98),
        color.withValues(alpha: 0.045),
      ],
    ),
    borderRadius: BorderRadius.circular(AppRadius.xxxl),
    border: Border.all(color: color.withValues(alpha: 0.14)),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.025),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: _moduleCardDecoration(color),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.mlg),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
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
                            color: Colors.white.withValues(alpha: 0.82),
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
              const SizedBox(height: AppSpacing.md),
              Text(
                primaryValue,
                style: AppTextStyles.numberLarge.copyWith(
                  color: color,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 4),
              Text(primaryLabel, style: AppTextStyles.caption),
              if (progress != null || targetLabel != null) ...[
                const SizedBox(height: AppSpacing.md),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 7,
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
                const SizedBox(height: AppSpacing.lg),
                Container(height: 1, color: color.withValues(alpha: 0.10)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: metrics.map((m) {
                    return Expanded(
                      child: Column(
                        children: [
                          Icon(
                            m.icon,
                            size: 18,
                            color: color.withValues(alpha: 0.72),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
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
      decoration: _moduleCardDecoration(color),
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
                  color: Colors.white.withValues(alpha: 0.84),
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
                    fontWeight: FontWeight.w800,
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
                    color: Colors.white.withValues(alpha: 0.72),
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
