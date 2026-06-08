import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../shared/providers/focus_provider.dart';
import 'utils/focus_assets.dart';
import 'utils/focus_options.dart';
import 'widgets/sound_selector.dart';

const _focusMint = Color(0xFF4CBDAE);
const _focusMintDark = Color(0xFF188C83);
const _focusInk = Color(0xFF2D3333);
const _focusLine = Color(0xFFE8DDD1);

const _presetSubjects = [
  '数学',
  '英语',
  '物理',
  '化学',
  '编程',
  '语文',
  '历史',
  '地理',
  '生物',
  '其他',
];

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  final _customController = TextEditingController(text: '30');
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(focusSetupProvider);
    final todayMinutes = ref.watch(todayFocusMinutesProvider);
    final recentSessions = ref.watch(recentFocusSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF6),
      body: SafeArea(
        child: RefreshIndicator(
          color: _focusMint,
          onRefresh: () async {
            ref.invalidate(todayFocusMinutesProvider);
            ref.invalidate(recentFocusSessionsProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape =
                  constraints.maxWidth >= constraints.maxHeight &&
                  constraints.maxWidth >= 900;
              if (isLandscape) {
                return _LandscapeFocusSetup(
                  setup: setup,
                  todayMinutes: todayMinutes,
                  recentSessions: recentSessions,
                  titleController: _titleController,
                  subjectController: _subjectController,
                  customController: _customController,
                  onStart: () => _startFocus(setup),
                );
              }
              return _PortraitFocusSetup(
                setup: setup,
                todayMinutes: todayMinutes,
                recentSessions: recentSessions,
                titleController: _titleController,
                subjectController: _subjectController,
                customController: _customController,
                onStart: () => _startFocus(setup),
              );
            },
          ),
        ),
      ),
    );
  }

  void _startFocus(FocusSetupState setup) {
    final duration = setup.type == 'custom'
        ? (int.tryParse(_customController.text) ?? 30)
        : setup.durationMinutes;
    final title = _titleController.text.trim();
    final subject = setup.subject ?? _subjectController.text.trim();

    if (duration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的专注时长')));
      return;
    }

    context.push(
      '/focus/session'
      '?duration=$duration'
      '&type=${setup.type}'
      '&rounds=${setup.totalRounds}'
      '&title=${Uri.encodeComponent(title)}'
      '&subject=${Uri.encodeComponent(subject)}'
      '${setup.soundType != null ? "&sound=${setup.soundType}" : ""}',
    );
  }
}

class _PortraitFocusSetup extends ConsumerWidget {
  const _PortraitFocusSetup({
    required this.setup,
    required this.todayMinutes,
    required this.recentSessions,
    required this.titleController,
    required this.subjectController,
    required this.customController,
    required this.onStart,
  });

  final FocusSetupState setup;
  final AsyncValue<int> todayMinutes;
  final AsyncValue<List<FocusSession>> recentSessions;
  final TextEditingController titleController;
  final TextEditingController subjectController;
  final TextEditingController customController;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        _TopBar(compact: false),
        const SizedBox(height: 14),
        _TodayFocusCard(todayMinutes: todayMinutes, compact: false),
        const SizedBox(height: 22),
        _SetupForm(
          setup: setup,
          titleController: titleController,
          subjectController: subjectController,
          customController: customController,
          compact: false,
        ),
        const SizedBox(height: 20),
        _StartButton(onTap: onStart),
        const SizedBox(height: 24),
        _RecentFocusList(recentSessions: recentSessions, compact: false),
      ],
    );
  }
}

class _LandscapeFocusSetup extends ConsumerWidget {
  const _LandscapeFocusSetup({
    required this.setup,
    required this.todayMinutes,
    required this.recentSessions,
    required this.titleController,
    required this.subjectController,
    required this.customController,
    required this.onStart,
  });

  final FocusSetupState setup;
  final AsyncValue<int> todayMinutes;
  final AsyncValue<List<FocusSession>> recentSessions;
  final TextEditingController titleController;
  final TextEditingController subjectController;
  final TextEditingController customController;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const _FocusRail(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 22, 18, 28),
            children: [
              const _LandscapeHeader(),
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

class _BigMinutes extends StatelessWidget {
  const _BigMinutes({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return Row(
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
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.menu_book_rounded, title: '学习科目'),
        const SizedBox(height: 10),
        Wrap(
          spacing: compact ? 10 : 12,
          runSpacing: compact ? 10 : 12,
          children: _presetSubjects
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
    final tint = Color(preset.tint);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.11) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? tint : _focusLine,
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
                      color: selected ? _focusInk : const Color(0xFF5F6665),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    preset.minutes > 0 ? '${preset.minutes}min' : '自定义时间',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8F9693),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: _focusMint,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _focusMint : Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _focusMintDark : const Color(0xFFD3E8E3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : _focusMintDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: maxLength == null ? null : '',
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8B6B2)),
        prefixIcon: Icon(icon, color: const Color(0xFFA3B6B2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.76),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD4ECE7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD4ECE7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _focusMint, width: 1.6),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFF58C9B8), Color(0xFF24A99B)],
          ),
          boxShadow: [
            BoxShadow(
              color: _focusMint.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(FocusAssets.iconPomodoro, width: 34, height: 34),
            const SizedBox(width: 12),
            const Text(
              '开始专注',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentFocusList extends StatelessWidget {
  const _RecentFocusList({required this.recentSessions, required this.compact});

  final AsyncValue<List<FocusSession>> recentSessions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return recentSessions.when(
      data: (sessions) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              icon: Icons.receipt_long_rounded,
              title: compact ? '最近专注记录' : '最近专注记录',
            ),
            const SizedBox(height: 14),
            if (sessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _focusLine),
                ),
                child: Column(
                  children: [
                    Image.asset(FocusAssets.catIdle, width: 76, height: 76),
                    const SizedBox(height: 8),
                    const Text(
                      '还没有专注记录',
                      style: TextStyle(
                        color: Color(0xFF8E9693),
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.session, required this.compact});

  final FocusSession session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final interrupted = !session.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: interrupted ? const Color(0xFFFFF7F3) : const Color(0xFFFAFFF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: interrupted
              ? const Color(0xFFFFD1C8)
              : const Color(0xFFD8EBDC),
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
                  style: const TextStyle(
                    color: _focusInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${focusTypeLabel(session.type)} · ${session.roundIndex}轮',
                  style: const TextStyle(
                    color: Color(0xFF8C948F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.durationMinutes}min',
            style: const TextStyle(
              color: _focusMintDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
