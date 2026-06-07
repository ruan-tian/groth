import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/design.dart';
import '../../shared/providers/dashboard_provider.dart';
import 'widgets/dashboard_pet_widget.dart';
import 'widgets/dashboard_weather_badge.dart';
import 'widgets/quick_action_sheet.dart';
import 'widgets/today_overview.dart';
import 'widgets/today_tasks.dart';

// =============================================================================
// Dashboard Page (重构版 - 褐色渐变风格)
// =============================================================================

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5E6D0), // 淡褐色
              Color(0xFFFDF5E1), // 淡黄色
              Color(0xFFFFFDF8), // 接近白色
              Colors.white,      // 白色
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── 顶部：Growth OS + 问候语 + 宠物 ──
              _buildHeader(context),

              // ── 宠物组件（甜甜 + 气泡）──
              const DashboardPetWidget(),

              // ── 主体内容 ──
              Expanded(
                child: dashboardAsync.when(
                  loading: () => const _LoadingBody(),
                  error: (error, _) => _ErrorBody(
                    error: error,
                    onRetry: () => ref.invalidate(dashboardProvider),
                  ),
                  data: (data) => RefreshIndicator(
                    onRefresh: () async => ref.invalidate(dashboardProvider),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 日期显示 ──
                          _buildDateSection(),

                          const SizedBox(height: 20),

                          // ── 4个今日概况（2x2网格） ──
                          _buildTodayOverview(ref, data),

                          const SizedBox(height: 24),

                          // ── 今日任务 ──
                          const TodayTasks(),

                          const SizedBox(height: 80), // 为FAB留空间
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 顶部：Growth OS 标题 + 问候语 + 渐变线 + AI萌宠
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: title + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth OS',
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 24,
                    color: const Color(0xFF5C3D2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _greeting(now.hour),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8B6F5E),
                  ),
                ),
              ],
            ),
          ),

          // Right side: weather badge
          const DashboardWeatherBadge(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 日期显示
  // ---------------------------------------------------------------------------

  Widget _buildDateSection() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1DF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}',
          style: const TextStyle(
            color: Color(0xFF88681A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
