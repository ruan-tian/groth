part of '../focus_page.dart';

// ---------------------------------------------------------------------------
// Top bar (portrait)
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact, required this.onHistory});

  final bool compact;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return SizedBox(
      height: compact ? 44 : 54,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: colors.textPrimary,
          ),
          const Spacer(),
          Text(
            '番茄钟',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: compact ? 20 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _FocusHistoryButton(compact: true, onTap: onHistory),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape header
// ---------------------------------------------------------------------------

class _LandscapeHeader extends StatelessWidget {
  const _LandscapeHeader({required this.onHistory});

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '番茄钟',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '自律一点点，进步看得见',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        _FocusHistoryButton(compact: false, onTap: onHistory),
        const SizedBox(width: 12),
        Image.asset(FocusAssets.particleHeart, width: 34, height: 34),
      ],
    );
  }
}

class _FocusHistoryButton extends StatelessWidget {
  const _FocusHistoryButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.focus.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 17, color: colors.focus),
              const SizedBox(width: 6),
              Text(
                compact ? '记录' : '专注记录',
                style: TextStyle(
                  color: colors.focus,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape side rail
// ---------------------------------------------------------------------------

class _FocusRail extends StatelessWidget {
  const _FocusRail({required this.selectedIndex, this.onSelect});

  final int selectedIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final items = [
      (FocusAssets.iconPomodoro, '番茄钟'),
      (FocusAssets.catReading, '专注'),
      (FocusAssets.soundWhiteNoise, '白噪音'),
      (FocusAssets.catIdle, '设置'),
    ];

    return Container(
      width: 110,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          for (int i = 0; i < items.length; i++) ...[
            _RailItem(
              asset: items[i].$1,
              label: items[i].$2,
              selected: i == selectedIndex,
              onTap: onSelect != null ? () => onSelect!(i) : null,
            ),
            const SizedBox(height: 14),
          ],
          const Spacer(),
          Image.asset(FocusAssets.catIdle, width: 92, height: 92),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.asset,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.focus.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: selected ? Border.all(color: colors.focus) : null,
        ),
        child: Column(
          children: [
            Image.asset(asset, width: 38, height: 38),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.focus : colors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today focus stats card
// ---------------------------------------------------------------------------

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({required this.todayMinutes, required this.compact});

  final AsyncValue<int> todayMinutes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      height: compact ? 168 : 154,
      padding: EdgeInsets.fromLTRB(
        compact ? 28 : 22,
        compact ? 18 : 16,
        compact ? 24 : 18,
        compact ? 16 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        image: const DecorationImage(
          image: AssetImage(FocusAssets.bgOverview),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: colors.focus, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '今日累计专注时长',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: compact ? 15 : 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                todayMinutes.when(
                  data: (minutes) => _BigMinutes(minutes: minutes),
                  loading: () => const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  error: (_, _) => const Text('--'),
                ),
                const SizedBox(height: 6),
                Text(
                  '继续保持，专注的你真棒！',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!compact)
            Image.asset(FocusAssets.catIdle, width: 106, height: 106),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Big minutes display (hours + minutes)
// ---------------------------------------------------------------------------

class _BigMinutes extends StatelessWidget {
  const _BigMinutes({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$hours',
            style: TextStyle(
              color: colors.focus,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 10),
            child: Text(
              '小时',
              style: TextStyle(
                color: colors.focus,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$mins',
            style: TextStyle(
              color: colors.focus,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              '分',
              style: TextStyle(
                color: colors.focus,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paper panel container
// ---------------------------------------------------------------------------

class _PaperPanel extends StatelessWidget {
  const _PaperPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Section title (icon + label)
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Icon(icon, color: colors.focus, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
