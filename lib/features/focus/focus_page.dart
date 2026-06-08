import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../shared/providers/focus_provider.dart';
import '../../shared/widgets/common/common_widgets.dart';
import 'widgets/sound_selector.dart';

// ─── 数据类 ──────────────────────────────────────────────────────────────

class _TimerPreset {
  const _TimerPreset({
    required this.type,
    required this.label,
    required this.minutes,
    required this.icon,
  });

  final String type;
  final String label;
  final int minutes;
  final IconData icon;
}

const _presets = [
  _TimerPreset(type: 'pomodoro', label: '番茄', minutes: 25, icon: Icons.timer),
  _TimerPreset(type: 'deep', label: '深度', minutes: 45, icon: Icons.psychology),
  _TimerPreset(type: 'ultra', label: '超深度', minutes: 90, icon: Icons.rocket_launch),
  _TimerPreset(type: 'custom', label: '自定义', minutes: 0, icon: Icons.tune),
];

const _presetSubjects = [
  '数学', '英语', '物理', '化学', '编程', '语文', '历史', '地理', '生物', '其他',
];

// ─── Focus Page ─────────────────────────────────────────────────────────────

/// 专注模块首页
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('专注', style: AppTextStyles.pageTitle),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayFocusMinutesProvider);
          ref.invalidate(recentFocusSessionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── 今日专注概览 ──
            _buildTodayCard(todayMinutes),
            const SizedBox(height: AppSpacing.xl),

            // ── 学习科目 ──
            Text('学习科目', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            _buildSubjectSelector(setup),
            const SizedBox(height: AppSpacing.xl),

            // ── 专注时长预设 ──
            Text('专注时长', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            _buildPresetChips(setup),
            if (setup.type == 'custom') ...[
              const SizedBox(height: AppSpacing.md),
              _buildCustomInput(),
            ],
            const SizedBox(height: AppSpacing.xl),

            // ── 专注轮次 ──
            Text('专注轮次', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            _buildRoundSelector(setup),
            const SizedBox(height: AppSpacing.xl),

            // ── 专注标题 ──
            Text('专注标题', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '输入专注标题（可选）',
                prefixIcon: Icon(Icons.edit_outlined, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── 白噪音选择 ──
            Text('白噪音', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            SoundSelector(
              selectedSound: setup.soundType ?? 'none',
              onSoundChanged: (value) {
                ref.read(focusSetupProvider.notifier).state = setup.copyWith(
                  soundType: value == 'none' ? null : value,
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── 开始按钮 ──
            _buildStartButton(setup),
            const SizedBox(height: AppSpacing.xl),

            // ── 最近专注记录 ──
            Text('最近专注', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            _buildRecentList(recentSessions),
          ],
        ),
      ),
    );
  }

  // ── 今日专注卡片 ──
  Widget _buildTodayCard(AsyncValue<int> todayMinutes) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.timer, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日专注', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 4),
                todayMinutes.when(
                  data: (m) => Text(
                    _formatMinutes(m),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  loading: () => const SizedBox(
                    height: 28,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  error: (_, _) => Text(
                    '--',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 学习科目选择器 ──
  Widget _buildSubjectSelector(FocusSetupState setup) {
    return Column(
      children: [
        // 预设科目
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetSubjects.map((subject) {
            final isSelected = setup.subject == subject;
            return GestureDetector(
              onTap: () {
                ref.read(focusSetupProvider.notifier).state = setup.copyWith(
                  subject: subject,
                );
                _subjectController.text = subject;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.study.withValues(alpha: 0.12) : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.study : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.study : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // 自定义输入
        TextField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: '或输入自定义科目/内容',
            prefixIcon: Icon(Icons.menu_book, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
          onChanged: (value) {
            ref.read(focusSetupProvider.notifier).state = setup.copyWith(
              subject: value.trim().isEmpty ? null : value.trim(),
            );
          },
        ),
      ],
    );
  }

  // ── 预设选择 ──
  Widget _buildPresetChips(FocusSetupState setup) {
    return Row(
      children: _presets.map((preset) {
        final isSelected = setup.type == preset.type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                ref.read(focusSetupProvider.notifier).state = setup.copyWith(
                  type: preset.type,
                  durationMinutes: preset.type == 'custom'
                      ? (int.tryParse(_customController.text) ?? 30)
                      : preset.minutes,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      preset.icon,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    if (preset.minutes > 0)
                      Text(
                        '${preset.minutes}min',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 自定义时长输入 ──
  Widget _buildCustomInput() {
    return TextField(
      controller: _customController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: '输入时长（分钟）',
        prefixIcon: Icon(Icons.timer_outlined, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // ── 轮次选择器 ──
  Widget _buildRoundSelector(FocusSetupState setup) {
    return Row(
      children: [1, 2, 3, 4].map((rounds) {
        final isSelected = setup.totalRounds == rounds;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                ref.read(focusSetupProvider.notifier).state =
                    setup.copyWith(totalRounds: rounds);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$rounds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '轮',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 开始按钮 ──
  Widget _buildStartButton(FocusSetupState setup) {
    return PrimaryButton(
      text: '开始专注',
      icon: Icons.play_arrow_rounded,
      onTap: () => _startFocus(setup),
      height: 56,
    );
  }

  // ── 最近记录列表 ──
  Widget _buildRecentList(AsyncValue<List<dynamic>> recentSessions) {
    return recentSessions.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.timer_outlined, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text('还没有专注记录', style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        }
        return Column(
          children: sessions.take(5).map((session) {
            final isInterrupted = !session.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.title ?? '专注',
                                style: AppTextStyles.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isInterrupted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '中断',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(_formatMinutes(session.durationMinutes), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _startFocus(FocusSetupState setup) {
    final duration = setup.type == 'custom'
        ? (int.tryParse(_customController.text) ?? 30)
        : setup.durationMinutes;
    final title = _titleController.text.trim();
    final subject = setup.subject ?? _subjectController.text.trim();

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的专注时长')),
      );
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

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h 小时 $m 分' : '$h 小时';
  }
}
