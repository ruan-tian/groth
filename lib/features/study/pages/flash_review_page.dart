import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../widgets/flash_review_tab.dart';
import '../widgets/flash_knowledge_tab.dart';
import '../widgets/flash_import_tab.dart';

/// 知识抽卡统一页面
///
/// 将原来的 11 个独立页面收敛为 3-Tab 结构：
/// - 🧠 复习：核心闪卡复习流
/// - 📦 知识：卡片/资料管理
/// - ➕ AI 导入：AI 工厂入口
class FlashReviewPage extends ConsumerStatefulWidget {
  const FlashReviewPage({super.key});

  @override
  ConsumerState<FlashReviewPage> createState() => _FlashReviewPageState();
}

class _FlashReviewPageState extends ConsumerState<FlashReviewPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_onboardingChecked) {
        _onboardingChecked = true;
        _checkOnboarding();
      }
    });
  }

  Future<void> _checkOnboarding() async {
    final done = await ref.read(knowledgeOnboardingDoneProvider.future);
    if (!done && mounted) {
      await context.push('/plan/study/knowledge/onboarding');
      ref.invalidate(filteredKnowledgeGoalSummariesProvider);
      ref.invalidate(knowledgeGoalSummariesProvider);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '知识抽卡',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '自定义模板',
            onPressed: () => context.push('/plan/study/knowledge/templates'),
            icon: Icon(Icons.dashboard_customize_rounded, color: colors.study),
          ),
          PopupMenuButton<_MoreAction>(
            tooltip: '更多',
            color: colors.card,
            surfaceTintColor: colors.card,
            icon: Icon(Icons.more_horiz_rounded, color: colors.study),
            onSelected: (action) {
              switch (action) {
                case _MoreAction.export:
                  context.push('/plan/study/knowledge/export');
                  break;
                case _MoreAction.archive:
                  context.push('/plan/study/knowledge/archive');
                  break;
                case _MoreAction.onboarding:
                  context.push('/plan/study/knowledge/onboarding');
                  break;
                case _MoreAction.reviewAll:
                  // Navigate to review with all cards
                  context.push('/plan/study/knowledge/review');
                  break;
                case _MoreAction.sources:
                  context.push('/plan/study/knowledge/sources');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MoreAction.export,
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('导出知识卡'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.archive,
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('归档箱'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.onboarding,
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('使用引导'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.reviewAll,
                child: Row(
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('全部复习'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MoreAction.sources,
                child: Row(
                  children: [
                    Icon(Icons.library_books_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('本地资料库'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.study,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: colors.study,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.psychology_rounded, size: 20), text: '复习'),
            Tab(icon: Icon(Icons.library_books_rounded, size: 20), text: '知识'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 20), text: 'AI 导入'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FlashReviewTab(),
          FlashKnowledgeTab(),
          FlashImportTab(),
        ],
      ),
    );
  }
}

enum _MoreAction { export, archive, onboarding, reviewAll, sources }
