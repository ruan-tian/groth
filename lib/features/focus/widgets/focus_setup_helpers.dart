part of '../focus_page.dart';

// ---------------------------------------------------------------------------
// Top bar (portrait)
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 44 : 54,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _focusInk,
          ),
          const Spacer(),
          Text(
            '番茄钟',
            style: TextStyle(
              color: _focusInk,
              fontSize: compact ? 28 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history_rounded),
            color: _focusMintDark,
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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '番茄钟',
              style: TextStyle(
                color: _focusInk,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '自律一点点，进步看得见',
              style: TextStyle(
                color: Color(0xFF9A948D),
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
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _focusLine),
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
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8FAF5) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: _focusMint) : null,
      ),
      child: Column(
        children: [
          Image.asset(asset, width: 38, height: 38),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: selected ? _focusMintDark : const Color(0xFF646B6A),
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
        border: Border.all(color: const Color(0xFFD8EEE8)),
        image: const DecorationImage(
          image: AssetImage(FocusAssets.bgOverview),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3BAE9D).withValues(alpha: 0.08),
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
                  children: const [
                    Icon(
                      Icons.schedule_rounded,
                      color: _focusMintDark,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '今日累计专注时长',
                      style: TextStyle(
                        color: Color(0xFF797A76),
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
                const Text(
                  '继续保持，专注的你真棒！',
                  style: TextStyle(
                    color: Color(0xFF9B948D),
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
            style: const TextStyle(
              color: _focusMintDark,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 6, left: 4, right: 10),
            child: Text(
              '小时',
              style: TextStyle(
                color: _focusMintDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$mins',
            style: const TextStyle(
              color: _focusMintDark,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              '分',
              style: TextStyle(
                color: _focusMintDark,
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _focusLine),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E5A3E).withValues(alpha: 0.07),
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
    return Row(
      children: [
        Icon(icon, color: _focusMintDark, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _focusInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
