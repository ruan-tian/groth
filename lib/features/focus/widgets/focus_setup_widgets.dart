part of '../focus_page.dart';

/// 获取当前学习模式的科目列表
List<String> _presetSubjects(StudyMode mode) => mode.subjects;

// ---------------------------------------------------------------------------
// Portrait layout
// ---------------------------------------------------------------------------

class _PortraitFocusSetup extends ConsumerWidget {
  const _PortraitFocusSetup({
    required this.setup,
    required this.todayMinutes,
    required this.recentSessions,
    required this.titleController,
    required this.subjectController,
    required this.customController,
    required this.onStart,
    required this.onHistory,
  });

  final FocusSetupState setup;
  final AsyncValue<int> todayMinutes;
  final AsyncValue<List<FocusSession>> recentSessions;
  final TextEditingController titleController;
  final TextEditingController subjectController;
  final TextEditingController customController;
  final VoidCallback onStart;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        _TopBar(compact: false, onHistory: onHistory),
        const SizedBox(height: 12),
        _TodayFocusCard(todayMinutes: todayMinutes, compact: false),
        const SizedBox(height: 18),
        _SetupForm(
          setup: setup,
          titleController: titleController,
          subjectController: subjectController,
          customController: customController,
          compact: false,
        ),
        const SizedBox(height: 18),
        _StartButton(onTap: onStart),
        const SizedBox(height: 22),
        _RecentFocusList(recentSessions: recentSessions, compact: false),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape layout
// ---------------------------------------------------------------------------

class _LandscapeFocusSetup extends ConsumerWidget {
  const _LandscapeFocusSetup({
    required this.setup,
    required this.todayMinutes,
    required this.recentSessions,
    required this.titleController,
    required this.subjectController,
    required this.customController,
    required this.onStart,
    required this.onHistory,
  });

  final FocusSetupState setup;
  final AsyncValue<int> todayMinutes;
  final AsyncValue<List<FocusSession>> recentSessions;
  final TextEditingController titleController;
  final TextEditingController subjectController;
  final TextEditingController customController;
  final VoidCallback onStart;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _FocusRail(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 22, 18, 28),
            children: [
              _LandscapeHeader(onHistory: onHistory),
              const SizedBox(height: 18),
              _TodayFocusCard(todayMinutes: todayMinutes, compact: true),
              const SizedBox(height: 16),
              _PaperPanel(
                child: Column(
                  children: [
                    _SetupForm(
                      setup: setup,
                      titleController: titleController,
                      subjectController: subjectController,
                      customController: customController,
                      compact: true,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(width: 520, child: _StartButton(onTap: onStart)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 390,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 34, 28, 34),
            child: _PaperPanel(
              child: _RecentFocusList(
                recentSessions: recentSessions,
                compact: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Setup form (subject, duration, rounds, title, sound)
// ---------------------------------------------------------------------------

class _SetupForm extends ConsumerWidget {
  const _SetupForm({
    required this.setup,
    required this.titleController,
    required this.subjectController,
    required this.customController,
    required this.compact,
  });

  final FocusSetupState setup;
  final TextEditingController titleController;
  final TextEditingController subjectController;
  final TextEditingController customController;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final currentMode = ref.watch(focusStudyModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle(icon: Icons.menu_book_rounded, title: '学习科目'),
            const Spacer(),
            GestureDetector(
              onTap: () => showStudyModeSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.focus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentMode.icon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentMode.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.focus,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 14,
                      color: colors.focus,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: compact ? 10 : 12,
          runSpacing: compact ? 10 : 12,
          children: _presetSubjects(currentMode)
              .map((subject) {
                return _PillButton(
                  label: subject,
                  selected: setup.subject == subject,
                  minWidth: compact ? 72 : 86,
                  onTap: () {
                    ref.read(focusSetupProvider.notifier).state = setup
                        .copyWith(subject: subject);
                    subjectController.text = subject;
                  },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        _SoftInput(
          controller: subjectController,
          hint: '或输入自定义科目 / 内容',
          icon: Icons.edit_outlined,
          maxLength: null,
          onChanged: (value) {
            ref.read(focusSetupProvider.notifier).state = setup.copyWith(
              subject: value.trim().isEmpty ? null : value.trim(),
            );
          },
        ),
        const SizedBox(height: 22),
        _SectionTitle(icon: Icons.timer_outlined, title: '专注时长'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth < 520;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: focusPresetOptions
                  .map((preset) {
                    return SizedBox(
                      width: twoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : (constraints.maxWidth - 36) / 4,
                      child: _PresetCard(
                        preset: preset,
                        selected: setup.type == preset.type,
                        onTap: () {
                          ref
                              .read(focusSetupProvider.notifier)
                              .state = setup.copyWith(
                            type: preset.type,
                            durationMinutes: preset.type == 'custom'
                                ? (int.tryParse(customController.text) ?? 30)
                                : preset.minutes,
                          );
                        },
                      ),
                    );
                  })
                  .toList(growable: false),
            );
          },
        ),
        if (setup.type == 'custom') ...[
          const SizedBox(height: 12),
          _SoftInput(
            controller: customController,
            hint: '输入时长（分钟）',
            icon: Icons.tune_rounded,
            keyboardType: TextInputType.number,
            maxLength: null,
            onChanged: (value) {
              ref.read(focusSetupProvider.notifier).state = setup.copyWith(
                durationMinutes: int.tryParse(value) ?? setup.durationMinutes,
              );
            },
          ),
        ],
        const SizedBox(height: 22),
        _SectionTitle(icon: Icons.refresh_rounded, title: '专注轮次'),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3, 4]
              .map((rounds) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PillButton(
                      label: '$rounds轮',
                      selected: setup.totalRounds == rounds,
                      onTap: () {
                        ref.read(focusSetupProvider.notifier).state = setup
                            .copyWith(totalRounds: rounds);
                      },
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 22),
        _SectionTitle(icon: Icons.draw_rounded, title: '专注标题'),
        const SizedBox(height: 10),
        _SoftInput(
          controller: titleController,
          hint: '给这次专注取个标题吧～（可选）',
          icon: Icons.edit_rounded,
          maxLength: 30,
        ),
        const SizedBox(height: 22),
        _SectionTitle(icon: Icons.music_note_rounded, title: '白噪音'),
        const SizedBox(height: 12),
        SoundSelector(
          selectedSound: setup.soundType ?? 'none',
          compact: compact,
          onSoundChanged: (value) {
            ref.read(focusSetupProvider.notifier).state = setup.copyWith(
              soundType: value == 'none' ? null : value,
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preset duration card
// ---------------------------------------------------------------------------

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final FocusPresetOption preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final tint = Color(preset.tint);
    return Semantics(
      button: true,
      label:
          '${preset.label}${preset.minutes > 0 ? ' ${preset.minutes}分钟' : ' 自定义'}',
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? tint.withValues(alpha: 0.11) : colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? tint : colors.border,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Image.asset(preset.asset, width: 34, height: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        preset.minutes > 0 ? '${preset.minutes}min' : '自定义时间',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.focus,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill button (subject / round selector)
// ---------------------------------------------------------------------------

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.minWidth,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          constraints: BoxConstraints(minWidth: minWidth ?? 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.focus
                : colors.card.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? colors.focus : colors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? colors.textOnAccent : colors.focus,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Soft-styled text input
// ---------------------------------------------------------------------------

class _SoftInput extends StatelessWidget {
  const _SoftInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: maxLength == null ? null : '',
        hintText: hint,
        hintStyle: TextStyle(color: colors.textHint),
        prefixIcon: Icon(icon, color: colors.textTertiary),
        filled: true,
        fillColor: colors.card.withValues(alpha: 0.76),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.focus, width: 1.6),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Start focus button
// ---------------------------------------------------------------------------

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: '开始专注',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            height: 58,
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.focus.withValues(alpha: 0.24)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.card.withValues(alpha: 0.96),
                  colors.focus.withValues(alpha: 0.13),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.focus.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.focus.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Image.asset(
                      FocusAssets.iconPomodoro,
                      width: 25,
                      height: 25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '开始专注',
                  style: TextStyle(
                    color: colors.focus,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.focus.withValues(alpha: 0.78),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent focus sessions list
// ---------------------------------------------------------------------------

class _RecentFocusList extends StatelessWidget {
  const _RecentFocusList({
    required this.recentSessions,
    required this.compact,
    this.showTitle = true,
  });

  final AsyncValue<List<FocusSession>> recentSessions;
  final bool compact;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return recentSessions.when(
      data: (sessions) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              const _SectionTitle(
                icon: Icons.receipt_long_rounded,
                title: '最近专注记录',
              ),
              const SizedBox(height: 14),
            ],
            if (sessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Image.asset(FocusAssets.catIdle, width: 76, height: 76),
                    const SizedBox(height: 8),
                    Text(
                      '还没有专注记录',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...sessions
                  .take(compact ? 5 : 3)
                  .map(
                    (session) =>
                        _RecentTile(session: session, compact: compact),
                  ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }
}

class _FocusHistorySheet extends ConsumerWidget {
  const _FocusHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.growthColors;
    final recentSessions = ref.watch(recentFocusSessionsProvider);
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: height * 0.76),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.focus.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: colors.focus,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '过往专注记录',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '最近 10 次专注会显示在这里',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: _RecentFocusList(
                  recentSessions: recentSessions,
                  compact: false,
                  showTitle: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single recent session tile
// ---------------------------------------------------------------------------

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.session, required this.compact});

  final FocusSession session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final interrupted = !session.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: interrupted
            ? colors.danger.withValues(alpha: 0.08)
            : colors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: interrupted
              ? colors.danger.withValues(alpha: 0.18)
              : colors.success.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            interrupted
                ? FocusAssets.interruptWarning
                : FocusAssets.successBadge,
            width: compact ? 42 : 38,
            height: compact ? 42 : 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${focusTypeLabel(session.type)} · ${session.roundIndex}轮',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.durationMinutes}min',
            style: TextStyle(
              color: colors.focus,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
