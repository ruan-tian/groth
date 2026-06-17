import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design/design.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/dashboard/pages/task_history_page.dart';
import '../features/music/pages/music_playlist_page.dart';
import '../features/music/pages/music_favorites_page.dart';
import '../features/plan/plan_page.dart';
import '../features/fitness/pages/add_fitness_record_page.dart';
import '../features/fitness/pages/add_body_metric_page.dart';
import '../features/fitness/pages/body_metric_detail_page.dart';
import '../features/fitness/pages/fitness_training_timer_page.dart';
import '../features/fitness/pages/fitness_record_detail_page.dart';
import '../features/fitness/pages/weekly_fitness_page.dart';
import '../features/fitness/pages/all_fitness_records_page.dart';
import '../features/focus/focus_page.dart';
import '../features/focus/pages/focus_session_page.dart';
import '../features/health/pages/add_diet_record_page.dart';
import '../features/health/pages/drink_recommendation_page.dart';
import '../features/health/pages/add_sleep_record_page.dart';
import '../features/health/pages/sleep_reminder_timer_page.dart';
import '../features/health/pages/water_reminder_timer_page.dart';
import '../features/journal/pages/journal_detail_page.dart';
import '../features/journal/pages/write_journal_page.dart';
import '../features/journal/pages/edit_journal_page.dart';
import '../features/journal/pages/inspiration_bookmark_page.dart';
import '../features/pet/pages/pet_ai_analysis_page.dart';
import '../features/pet/pages/pet_center_page.dart';
import '../features/pet/pages/pet_diary_page.dart';
import '../features/pet/pages/pet_history_page.dart';
import '../features/pet/pages/pet_settings_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/pages/profile_page.dart';
import '../features/settings/pages/backup_page.dart';
import '../features/settings/pages/restore_page.dart';
import '../features/settings/pages/weather_settings_page.dart';
import '../features/ai/pages/ai_analysis_page.dart';
import '../features/settings/pages/ai_config_page.dart';
import '../features/study/pages/add_study_record_page.dart';
import '../features/study/pages/add_knowledge_card_page.dart';
import '../features/study/pages/bulk_import_knowledge_cards_page.dart';
import '../features/study/pages/knowledge_archive_page.dart';
import '../features/study/pages/knowledge_cards_page.dart';
import '../features/study/pages/knowledge_custom_templates_page.dart';
import '../features/study/pages/knowledge_export_page.dart';
import '../features/study/pages/knowledge_goal_detail_page.dart';
import '../features/study/pages/knowledge_review_page.dart';
import '../features/study/pages/knowledge_onboarding_page.dart';
import '../features/study/pages/flash_review_page.dart';
import '../features/study/pages/knowledge_source_detail_page.dart';
import '../features/study/pages/knowledge_sources_page.dart';
import '../features/study/pages/study_record_detail_page.dart';
import '../features/study/pages/subject_distribution_page.dart';
import '../features/study/pages/recent_records_page.dart';
import '../features/health/pages/all_diet_records_page.dart';
import '../features/health/pages/sleep_history_page.dart';
import '../shared/widgets/common/advanced_bottom_nav.dart';

// ─── Route paths ────────────────────────────────────────────────────────────

class RoutePaths {
  RoutePaths._();
  static const String dashboard = '/dashboard';
  static const String plan = '/plan';
  static const String settings = '/settings';
  static const String focus = '/focus';
}

// ─── Shell route names (used with context.goNamed) ──────────────────────────

class RouteNames {
  RouteNames._();
  static const String dashboard = 'dashboard';
  static const String plan = 'plan';
  static const String settings = 'settings';
  static const String focus = 'focus';
}

// ─── Page transition helpers ─────────────────────────────────────────────────

/// 滑入滑出页面过渡动画
///
/// [useSecondaryShift] 为 true 时，前一页会向左让 15%（适合 root 级页面）。
/// Shell branch 内部子路由必须传 false，避免 secondaryAnimation 残留偏移。
CustomTransitionPage<void> buildSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child, {
  bool useSecondaryShift = true,
}) {
  final reduceMotion = AppMotion.reduceMotion(context);

  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: reduceMotion ? Duration.zero : AppMotion.page,
    reverseTransitionDuration: reduceMotion ? Duration.zero : AppMotion.normal,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotion) return child;

      final primaryOffset = Tween<Offset>(
        begin: const Offset(0.0, 0.035),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppMotion.pageEnter));

      final primaryOpacity = CurvedAnimation(
        parent: animation,
        curve: AppMotion.pageEnter,
        reverseCurve: AppMotion.pageExit,
      );

      Widget result = FadeTransition(
        opacity: primaryOpacity,
        child: SlideTransition(position: primaryOffset, child: child),
      );

      if (useSecondaryShift) {
        final secondaryOpacity = Tween<double>(begin: 1, end: 0.96).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: AppMotion.pageExit,
          ),
        );

        result = FadeTransition(opacity: secondaryOpacity, child: result);
      }

      return result;
    },
  );
}

/// Shell branch 内部子路由专用过渡动画（禁用 secondaryAnimation 左移）
CustomTransitionPage<void> buildShellSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return buildSlideTransition(context, state, child, useSecondaryShift: false);
}

// ─── Shell wrapper with AdvancedBottomNav ───────────────────────────────────

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(child: navigationShell),
      bottomNavigationBar: RepaintBoundary(
        child: AdvancedBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

// ─── GoRouter configuration ─────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RoutePaths.dashboard,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // ── 首页 ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.dashboard,
              name: RouteNames.dashboard,
              builder: (_, _) => const DashboardPage(),
              routes: [
                // 音乐相关
                GoRoute(
                  path: 'music/playlist',
                  pageBuilder: (context, state) => buildSlideTransition(
                    context,
                    state,
                    const MusicPlaylistPage(),
                  ),
                ),
                GoRoute(
                  path: 'music/favorites',
                  pageBuilder: (context, state) => buildSlideTransition(
                    context,
                    state,
                    const MusicFavoritesPage(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── 计划（学习/健身/日记/饮食/睡眠）──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.plan,
              name: RouteNames.plan,
              builder: (_, _) => const PlanPage(),
              routes: [
                // 学习相关
                GoRoute(
                  path: 'study/add',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AddStudyRecordPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/detail/:id',
                  pageBuilder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return buildShellSlideTransition(
                      context,
                      state,
                      StudyRecordDetailPage(recordId: id),
                    );
                  },
                ),
                GoRoute(
                  path: 'study/recent',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const RecentRecordsPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/subjects',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const SubjectDistributionPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const KnowledgeCardsPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/add',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    AddKnowledgeCardPage(
                      initialGoalKey: state.uri.queryParameters['goalKey'],
                      initialGoalName: state.uri.queryParameters['goalName'],
                      initialModuleKey: state.uri.queryParameters['moduleKey'],
                      initialModuleName:
                          state.uri.queryParameters['moduleName'],
                      initialDeckKey: state.uri.queryParameters['deckKey'],
                      editCardId: int.tryParse(
                        state.uri.queryParameters['editCardId'] ?? '',
                      ),
                      initialCustomTemplateId: int.tryParse(
                        state.uri.queryParameters['customTemplateId'] ?? '',
                      ),
                      initialCustomModuleId: int.tryParse(
                        state.uri.queryParameters['customModuleId'] ?? '',
                      ),
                      sourceStudyId: int.tryParse(
                        state.uri.queryParameters['sourceStudyId'] ?? '',
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/import',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    BulkImportKnowledgeCardsPage(
                      initialGoalKey: state.uri.queryParameters['goalKey'],
                      initialGoalName: state.uri.queryParameters['goalName'],
                      initialModuleKey: state.uri.queryParameters['moduleKey'],
                      initialModuleName:
                          state.uri.queryParameters['moduleName'],
                      initialDeckKey: state.uri.queryParameters['deckKey'],
                      initialSubject: state.uri.queryParameters['subject'],
                    ),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/sources',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const KnowledgeSourcesPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/sources/:id',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    KnowledgeSourceDetailPage(
                      sourceId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/archive',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const KnowledgeArchivePage(),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/export',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const KnowledgeExportPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/templates',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const KnowledgeCustomTemplatesPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/goal',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    KnowledgeGoalDetailPage(
                      goalKey: state.uri.queryParameters['goalKey'] ?? 'custom',
                      goalName: state.uri.queryParameters['goalName'],
                    ),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/edit/:id',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    AddKnowledgeCardPage(
                      editCardId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/review',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    KnowledgeReviewPage(
                      deckKey: state.uri.queryParameters['deckKey'],
                      goalKey: state.uri.queryParameters['goalKey'],
                      goalName: state.uri.queryParameters['goalName'],
                      moduleKey: state.uri.queryParameters['moduleKey'],
                      moduleName: state.uri.queryParameters['moduleName'],
                      includeAll: state.uri.queryParameters['all'] == '1',
                      weakOnly: state.uri.queryParameters['weak'] == '1',
                    ),
                  ),
                ),
                GoRoute(
                  path: 'study/knowledge/onboarding',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const KnowledgeOnboardingPage(),
                  ),
                ),
                GoRoute(
                  path: 'study/flash-review',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const FlashReviewPage(),
                  ),
                ),
                // 健身相关
                GoRoute(
                  path: 'fitness/add',
                  pageBuilder: (context, state) {
                    final mode = state.uri.queryParameters['mode'] ?? 'simple';
                    final duration = int.tryParse(
                      state.uri.queryParameters['duration'] ?? '',
                    );
                    return buildShellSlideTransition(
                      context,
                      state,
                      AddFitnessRecordPage(
                        initialMode: mode,
                        initialDurationMinutes: duration,
                      ),
                    );
                  },
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'fitness/timer',
                  pageBuilder: (context, state) => buildSlideTransition(
                    context,
                    state,
                    const FitnessTrainingTimerPage(),
                  ),
                ),
                GoRoute(
                  path: 'fitness/detail/:id',
                  pageBuilder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return buildShellSlideTransition(
                      context,
                      state,
                      FitnessRecordDetailPage(recordId: id),
                    );
                  },
                ),
                GoRoute(
                  path: 'fitness/body-metric/add',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AddBodyMetricPage(),
                  ),
                ),
                GoRoute(
                  path: 'fitness/body-metric/detail',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const BodyMetricDetailPage(),
                  ),
                ),
                GoRoute(
                  path: 'fitness/weekly',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const WeeklyFitnessPage(),
                  ),
                ),
                GoRoute(
                  path: 'fitness/records',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AllFitnessRecordsPage(),
                  ),
                ),
                // 日记相关
                GoRoute(
                  path: 'journal/write',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const WriteJournalPage(),
                  ),
                ),
                GoRoute(
                  path: 'journal/inspiration',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const InspirationBookmarkPage(),
                  ),
                ),
                GoRoute(
                  path: 'journal/detail/:id',
                  pageBuilder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return buildShellSlideTransition(
                      context,
                      state,
                      JournalDetailPage(journalId: id),
                    );
                  },
                ),
                GoRoute(
                  path: 'journal/edit/:id',
                  pageBuilder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return buildShellSlideTransition(
                      context,
                      state,
                      EditJournalPage(journalId: id),
                    );
                  },
                ),
                // 饮食相关
                GoRoute(
                  path: 'diet/add',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AddDietRecordPage(),
                  ),
                ),
                GoRoute(
                  path: 'diet/drink-recommendation',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const DrinkRecommendationPage(),
                  ),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'diet/water-reminder',
                  pageBuilder: (context, state) => buildSlideTransition(
                    context,
                    state,
                    const WaterReminderTimerPage(),
                  ),
                ),
                GoRoute(
                  path: 'diet/records',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AllDietRecordsPage(),
                  ),
                ),
                // 睡眠相关
                GoRoute(
                  path: 'sleep/add',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AddSleepRecordPage(),
                  ),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'sleep/reminder',
                  pageBuilder: (context, state) => buildSlideTransition(
                    context,
                    state,
                    const SleepReminderTimerPage(),
                  ),
                ),
                GoRoute(
                  path: 'sleep/history',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const SleepHistoryPage(),
                  ),
                ),
                // AI 分析
                GoRoute(
                  path: 'ai-analysis',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AiAnalysisPage(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── 我的 ──
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              name: RouteNames.settings,
              builder: (_, _) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'profile',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const ProfilePage(),
                  ),
                ),
                GoRoute(
                  path: 'ai-config',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AiConfigPage(),
                  ),
                ),
                GoRoute(
                  path: 'ai-analysis',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const AiAnalysisPage(),
                  ),
                ),
                GoRoute(
                  path: 'pet-ai-analysis',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const PetAIAnalysisPage(),
                  ),
                ),
                GoRoute(
                  path: 'backup',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const BackupPage(),
                  ),
                ),
                GoRoute(
                  path: 'restore',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const RestorePage(),
                  ),
                ),
                GoRoute(
                  path: 'weather',
                  pageBuilder: (context, state) => buildShellSlideTransition(
                    context,
                    state,
                    const WeatherSettingsPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // ── Focus routes (full-screen, outside shell) ──────────────────────────
    GoRoute(
      path: RoutePaths.focus,
      name: RouteNames.focus,
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const FocusPage()),
      routes: [
        GoRoute(
          path: 'session',
          pageBuilder: (context, state) {
            final params = state.uri.queryParameters;
            return buildSlideTransition(
              context,
              state,
              FocusSessionPage(
                durationMinutes: int.parse(params['duration'] ?? '25'),
                type: params['type'] ?? 'pomodoro',
                title: params['title'] ?? '',
                subject: params['subject'] ?? '',
                soundType: params['sound'],
                totalRounds: int.parse(params['rounds'] ?? '4'),
              ),
            );
          },
        ),
      ],
    ),
    // ── Task history (full-screen, outside shell) ──────────────────────────
    GoRoute(
      path: '/task-history',
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const TaskHistoryPage()),
    ),
    // ── Pet center (full-screen, outside shell) ────────────────────────────
    GoRoute(
      path: '/pet-center',
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const PetCenterPage()),
    ),
    GoRoute(
      path: '/pet-diary',
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const PetDiaryPage()),
    ),
    GoRoute(
      path: '/pet-history',
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const PetHistoryPage()),
    ),
    GoRoute(
      path: '/pet-ai-analysis',
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const PetAIAnalysisPage()),
    ),
    GoRoute(
      path: '/pet-settings',
      pageBuilder: (context, state) =>
          buildSlideTransition(context, state, const PetSettingsPage()),
    ),
    GoRoute(
      path: '/ai-config',
      pageBuilder: (context, state) =>
          MaterialPage<void>(key: state.pageKey, child: const AiConfigPage()),
    ),
  ],
);
