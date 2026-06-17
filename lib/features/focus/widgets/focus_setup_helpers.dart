part of '../focus_page.dart';

// ---------------------------------------------------------------------------
// Top bar (portrait)
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

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
              fontSize: compact ? 28 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history_rounded),
            color: colors.focus,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape header
// ---------------------------------------------------------------------------

class _LandscapeHeader extends StatelessWidget {
  const _LandscapeHeader();

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
        Image.asset(FocusAssets.particleHeart, width: 34, height: 34),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape side rail
// ---------------------------------------------------------------------------

class _FocusRail extends StatelessWidget {
  const _FocusRail();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final items = [
      (FocusAssets.iconPomodoro, '番茄钟', true),
      (FocusAssets.catReading, '专注', false),
      (FocusAssets.soundWhiteNoise, '白噪音', false),
      (FocusAssets.catIdle, '设置', false),
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
          for (final item in items) ...[
            _RailItem(asset: item.$1, label: item.$2, selected: item.$3),
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
  });

  final String asset;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
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
      height: compact ? 190 : 176,
      padding: EdgeInsets.fromLTRB(
        compact ? 32 : 24,
        22,
        compact ? 28 : 18,
        18,
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
                    Icon(Icons.schedule_rounded, color: colors.focus, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '今日累计专注时长',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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
                const SizedBox(height: 8),
                Text(
                  '继续保持，专注的你真棒！',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!compact)
            Image.asset(FocusAssets.catIdle, width: 118, height: 118),
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
              fontSize: 54,
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
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$mins',
            style: TextStyle(
              color: colors.focus,
              fontSize: 54,
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
                fontSize: 24,
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
