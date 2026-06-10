import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../music/widgets/dashboard_music_float.dart';
import 'widgets/dashboard_pet_widget.dart';
import 'widgets/dashboard_weather_badge.dart';
import 'widgets/quick_action_sheet.dart';
import 'widgets/today_overview.dart';
import 'widgets/today_tasks.dart';

// =============================================================================
// Dashboard Page
// =============================================================================

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFBF5),
                  Color(0xFFFFF7FA),
                  Color(0xFFF8FAF0),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.34, 0.72, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: dashboardAsync.when(
                      loading: () => const _LoadingBody(),
                      error: (error, _) => _ErrorBody(
                        error: error,
                        onRetry: () => ref.invalidate(dashboardProvider),
                      ),
                      data: (data) => RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(dashboardProvider),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardPetWidget(data: data),
                              const SizedBox(height: 22),
                              _buildTodayOverview(ref, data),
                              const SizedBox(height: 24),
                              const TodayTasks(),
                              const SizedBox(height: 80), // 为FAB留空间
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DashboardMusicFloat(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: _DashboardColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 顶部：标题、问候、日期和天气入口
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth OS',
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _DashboardColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeaderChip(
                      icon: Icons.waving_hand_rounded,
                      label: _greeting(now.hour),
                    ),
                    _HeaderChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const DashboardWeatherBadge(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 今日概览（使用新的 TodayOverview 组件）
  // ---------------------------------------------------------------------------

  Widget _buildTodayOverview(WidgetRef ref, DashboardData data) {
    return const TodayOverview();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _greeting(int hour) {
    if (hour < 12) return '早上好，开始生长';
    if (hour < 18) return '下午好，稳稳推进';
    return '晚上好，认真复盘';
  }

  void _showQuickActions(BuildContext context) {
    QuickActionSheet.show(
      context,
      onStudy: () => context.push('/study/add'),
      onFitness: () => context.push('/fitness/add'),
      onJournal: () => context.push('/journal/write'),
    );
  }
}

class _DashboardColors {
  static const ink = Color(0xFF37314E);
  static const muted = Color(0xFF8D869A);
  static const primary = Color(0xFF8B75F6);
  static const chip = Color(0xFFFFFFFF);
  static const chipBorder = Color(0xFFF0E7DB);
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _DashboardColors.chip.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DashboardColors.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _DashboardColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _DashboardColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Loading & Error 状态
// =============================================================================

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppSpacing.lg),
          Text('加载中...', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.6),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('加载失败', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
