import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/services/calendar_service.dart';
import '../../../core/services/statistics_service.dart';
import 'add_task_dialog.dart';
import '../../dashboard/providers/calendar_provider.dart';
import '../../plan/providers/task_provider.dart';

Future<void> showGrowthCalendarSheet(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        GrowthCalendarSheet(initialDate: initialDate ?? DateTime.now()),
  );
}

class GrowthCalendarSheet extends ConsumerStatefulWidget {
  const GrowthCalendarSheet({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<GrowthCalendarSheet> createState() =>
      _GrowthCalendarSheetState();
}

class _GrowthCalendarSheetState extends ConsumerState<GrowthCalendarSheet> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;
  late final PageController _monthPageController;

  static const _monthBaseYear = 1900;
  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  static const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _monthPageController = PageController(
      initialPage: _pageForMonth(_displayMonth),
    );
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final calendarService = ref.watch(calendarServiceProvider);
    final selectedRequest = _requestForMonth(_displayMonth);
    final selectedStatsAsync = ref.watch(
      calendarStatsProvider(selectedRequest),
    );

    final height = math.min(MediaQuery.sizeOf(context).height * 0.88, 720.0);
    final gridHeight = height < 640 ? 292.0 : 330.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: 16),
              _SheetHeader(
                displayMonth: _displayMonth,
                onPrevious: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              const SizedBox(height: 14),
              _WeekdayHeader(weekdays: _weekdays),
              const SizedBox(height: 8),
              SizedBox(
                height: gridHeight,
                child: PageView.builder(
                  controller: _monthPageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _handleMonthPageChanged,
                  itemBuilder: (context, page) {
                    final pageMonth = _monthForPage(page);
                    final request = _requestForMonth(pageMonth);
                    final statsAsync = ref.watch(
                      calendarStatsProvider(request),
                    );
                    final dayInfos = calendarService.getRange(
                      request.normalizedStart,
                      request.normalizedEnd,
                    );

                    return statsAsync.when(
                      loading: () => _CalendarGrid(
                        dayInfos: dayInfos,
                        displayMonth: pageMonth,
                        selectedDate: _selectedDate,
                        statsByDate: const {},
                        onSelect: _selectDate,
                      ),
                      error: (_, _) => _CalendarGrid(
                        dayInfos: dayInfos,
                        displayMonth: pageMonth,
                        selectedDate: _selectedDate,
                        statsByDate: const {},
                        onSelect: _selectDate,
                      ),
                      data: (stats) => _CalendarGrid(
                        dayInfos: dayInfos,
                        displayMonth: pageMonth,
                        selectedDate: _selectedDate,
                        statsByDate: _statsByDate(stats),
                        onSelect: _selectDate,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: selectedStatsAsync.when(
                  loading: () => _SelectedDayPanel(
                    dayInfo: calendarService.getDayInfo(_selectedDate),
                    weekday: _weekdayNames[_selectedDate.weekday - 1],
                    stats: DailyStats.empty(_selectedDate),
                    isLoading: true,
                    onCreateTask: _createTaskForSelectedDate,
                  ),
                  error: (error, _) => _CalendarErrorPanel(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(calendarStatsProvider(selectedRequest)),
                  ),
                  data: (stats) {
                    final byDate = _statsByDate(stats);
                    return _SelectedDayPanel(
                      dayInfo: calendarService.getDayInfo(_selectedDate),
                      weekday: _weekdayNames[_selectedDate.weekday - 1],
                      stats:
                          byDate[_dateKey(_selectedDate)] ??
                          DailyStats.empty(_selectedDate),
                      onCreateTask: _createTaskForSelectedDate,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    final targetPage = _pageForMonth(_displayMonth) + delta;
    _monthPageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectDate(DateTime date) {
    HapticFeedback.lightImpact();
    final nextDate = _dateOnly(date);
    final nextMonth = DateTime(nextDate.year, nextDate.month);
    setState(() {
      _selectedDate = nextDate;
      _displayMonth = nextMonth;
    });

    final targetPage = _pageForMonth(nextMonth);
    final currentPage = _monthPageController.page?.round();
    if (currentPage != null && currentPage != targetPage) {
      _monthPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleMonthPageChanged(int page) {
    final nextMonth = _monthForPage(page);
    HapticFeedback.selectionClick();
    setState(() {
      _displayMonth = nextMonth;
      if (_selectedDate.year != nextMonth.year ||
          _selectedDate.month != nextMonth.month) {
        _selectedDate = DateTime(nextMonth.year, nextMonth.month);
      }
    });
  }

  Future<void> _createTaskForSelectedDate() async {
    final taskDate = _selectedDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskDialog(initialDate: taskDate),
    );
    if (!mounted) return;

    final request = _requestForMonth(_displayMonth);
    ref
      ..invalidate(calendarStatsProvider(request))
      ..invalidate(tasksByDateProvider(_dateKey(taskDate)))
      ..invalidate(todayTasksProvider)
      ..invalidate(todayIncompleteTaskCountProvider);
  }

  static CalendarStatsRequest _requestForMonth(DateTime month) {
    final start = _monthGridStart(month);
    return CalendarStatsRequest(
      start: start,
      end: start.add(const Duration(days: 41)),
    );
  }

  static DateTime _monthGridStart(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    return firstDay.subtract(Duration(days: firstDay.weekday - 1));
  }

  static Map<String, DailyStats> _statsByDate(List<DailyStats> stats) {
    return {for (final stat in stats) _dateKey(stat.date): stat};
  }

  static int _pageForMonth(DateTime month) {
    return (month.year - _monthBaseYear) * 12 + month.month - 1;
  }

  static DateTime _monthForPage(int page) {
    return DateTime(_monthBaseYear, page + 1);
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.displayMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime displayMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Row(
      children: [
        _IconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        Expanded(
          child: Column(
            children: [
              Text(
                '${displayMonth.year}年${displayMonth.month}月',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '农历 / 节日 / 成长记录',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        _IconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: colors.primary, size: 22),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekdays});

  final List<String> weekdays;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.dayInfos,
    required this.displayMonth,
    required this.selectedDate,
    required this.statsByDate,
    required this.onSelect,
  });

  final List<CalendarDayInfo> dayInfos;
  final DateTime displayMonth;
  final DateTime selectedDate;
  final Map<String, DailyStats> statsByDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.86,
      ),
      itemCount: dayInfos.length,
      itemBuilder: (context, index) {
        final info = dayInfos[index];
        return _CalendarDayCell(
          info: info,
          stats: statsByDate[_dateKey(info.date)],
          isCurrentMonth: info.date.month == displayMonth.month,
          isSelected: _isSameDay(info.date, selectedDate),
          onTap: () => onSelect(info.date),
        );
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.info,
    required this.stats,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.onTap,
  });

  final CalendarDayInfo info;
  final DailyStats? stats;
  final bool isCurrentMonth;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final hasFestival = info.festivals.isNotEmpty;

    final Color background = isSelected
        ? colors.primary
        : info.isToday
        ? colors.primary.withValues(alpha: 0.10)
        : colors.card.withValues(alpha: isCurrentMonth ? 0.72 : 0.35);
    final Color borderColor = isSelected
        ? colors.primary
        : hasFestival
        ? colors.accent.withValues(alpha: 0.35)
        : colors.border.withValues(alpha: isCurrentMonth ? 0.70 : 0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${info.date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? colors.textOnAccent
                        : isCurrentMonth
                        ? colors.textPrimary
                        : colors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.primarySubLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1,
                    fontWeight: hasFestival ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected
                        ? colors.textOnAccent.withValues(alpha: 0.90)
                        : hasFestival
                        ? colors.accent
                        : colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 5),
                _ActivityDots(stats: stats, selected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityDots extends StatelessWidget {
  const _ActivityDots({required this.stats, required this.selected});

  final DailyStats? stats;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final stat = stats;
    final activeColors = <Color>[
      if ((stat?.studyMinutes ?? 0) > 0) colors.study,
      if ((stat?.fitnessMinutes ?? 0) > 0) colors.fitness,
      if ((stat?.journalCount ?? 0) > 0) colors.journal,
      if ((stat?.focusMinutes ?? 0) > 0) colors.focus,
      if ((stat?.expGained ?? 0) > 0) colors.accent,
      if ((stat?.taskCompleted ?? 0) > 0) colors.success,
    ].take(4).toList();

    if (activeColors.isEmpty) {
      return SizedBox(
        height: 5,
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? colors.textOnAccent.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: activeColors
            .map(
              (color) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colors.textOnAccent.withValues(alpha: 0.90)
                      : color,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.dayInfo,
    required this.weekday,
    required this.stats,
    this.isLoading = false,
    this.onCreateTask,
  });

  final CalendarDayInfo dayInfo;
  final String weekday;
  final DailyStats stats;
  final bool isLoading;
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final festivals = dayInfo.festivals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dayInfo.date.month}月${dayInfo.date.day}日 $weekday',
                              style: AppTextStyles.cardTitle.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '农历${dayInfo.lunar.fullLabel}',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                    ],
                  ),
                  if (festivals.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: festivals
                          .map((festival) => _FestivalPill(festival: festival))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _MetricGrid(stats: stats),
                  if (onCreateTask != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onCreateTask,
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('为这天新建任务'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _MetricTile(
              width: itemWidth,
              label: '学习',
              value: '${stats.studyMinutes}m',
              color: colors.study,
            ),
            _MetricTile(
              width: itemWidth,
              label: '健身',
              value: '${stats.fitnessMinutes}m',
              color: colors.fitness,
            ),
            _MetricTile(
              width: itemWidth,
              label: '专注',
              value: '${stats.focusMinutes}m',
              color: colors.focus,
            ),
            _MetricTile(
              width: itemWidth,
              label: '日记',
              value: '${stats.journalCount}篇',
              color: colors.journal,
            ),
            _MetricTile(
              width: itemWidth,
              label: '经验',
              value: '+${stats.expGained}',
              color: colors.accent,
            ),
            _MetricTile(
              width: itemWidth,
              label: '任务',
              value: '${stats.taskCompleted}/${stats.taskTotal}',
              color: colors.success,
            ),
          ],
        );
      },
    );
  }
}

class _FestivalPill extends StatelessWidget {
  const _FestivalPill({required this.festival});

  final CalendarFestival festival;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final isLunar = festival.type == CalendarFestivalType.lunar;
    final color = isLunar ? colors.accent : colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        festival.name,
        style: AppTextStyles.label.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarErrorPanel extends StatelessWidget {
  const _CalendarErrorPanel({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, color: colors.textTertiary),
          const SizedBox(height: 8),
          Text(
            '日历统计加载失败',
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
