import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

/// Detail item displayed in a grid inside [RecordDetailSheet].
class DetailItem {
  const DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

/// A reusable bottom sheet for showing a record's details.
///
/// Displays a title (date), a primary metric card, a 2×N grid of detail items,
/// and optional extra cards (e.g. quality, notes).
class RecordDetailSheet extends StatelessWidget {
  const RecordDetailSheet({
    super.key,
    required this.title,
    required this.primaryMetricLabel,
    required this.primaryMetricValue,
    required this.detailItems,
    this.accentColor = AppColors.study,
    this.accentColorLight,
    this.primaryMetricIcon,
    this.extraCards,
    this.extraCard,
  });

  /// Convenience method to show this sheet via [showModalBottomSheet].
  static void show({
    required BuildContext context,
    required String title,
    required String primaryMetricLabel,
    required String primaryMetricValue,
    required List<DetailItem> detailItems,
    Color accentColor = AppColors.study,
    Color? accentColorLight,
    IconData? primaryMetricIcon,
    Widget? extraCards,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RecordDetailSheet(
        title: title,
        primaryMetricLabel: primaryMetricLabel,
        primaryMetricValue: primaryMetricValue,
        detailItems: detailItems,
        accentColor: accentColor,
        accentColorLight: accentColorLight,
        primaryMetricIcon: primaryMetricIcon,
        extraCards: extraCards,
      ),
    );
  }

  /// Title shown at the top (e.g. "2026年6月6日 周五").
  final String title;

  /// Label for the primary metric (e.g. "学习时长").
  final String primaryMetricLabel;

  /// Value for the primary metric (e.g. "45 分钟").
  final String primaryMetricValue;

  /// Grid detail items (pairs shown in a 2-column layout).
  final List<DetailItem> detailItems;

  /// Accent color used for the primary metric card and borders.
  final Color accentColor;

  /// Light variant of [accentColor], used for item backgrounds.
  final Color? accentColorLight;

  /// Optional icon displayed in the primary metric card.
  final IconData? primaryMetricIcon;

  /// Optional extra cards shown below the detail grid (e.g. quality, notes).
  final Widget? extraCards;

  /// Deprecated: use [extraCards] instead.
  @Deprecated('Use extraCards instead')
  final Widget? extraCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 拖拽条 ──
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),

          // ── 标题栏 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2329),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF86909C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 详情内容 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // 主指标卡片
                  _buildPrimaryMetricCard(),
                  const SizedBox(height: 16),

                  // 详情网格
                  _buildDetailGrid(),
                  const SizedBox(height: 16),

                  // 额外卡片
                  if (extraCards != null) ...[
                    extraCards!,
                    const SizedBox(height: 16),
                  ] else if (extraCard != null) ...[
                    extraCard!,
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // ── 关闭按钮 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('关闭'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetricCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (primaryMetricIcon != null) ...[
            Icon(primaryMetricIcon!, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
          ],
          Text(
            primaryMetricLabel,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            primaryMetricValue,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid() {
    final pairs = <List<DetailItem>>[];
    for (var i = 0; i < detailItems.length; i += 2) {
      final row = <DetailItem>[detailItems[i]];
      if (i + 1 < detailItems.length) {
        row.add(detailItems[i + 1]);
      }
      pairs.add(row);
    }

    return Column(
      children: pairs.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: _buildDetailItemWidget(row[0])),
              if (row.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(child: _buildDetailItemWidget(row[1])),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailItemWidget(DetailItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColorLight ?? accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(item.icon, color: accentColor, size: 20),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF86909C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
