import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../utils/knowledge_card_assets.dart';

/// 知识卡模块引导页：4 步介绍 + 目标选择。
///
/// 首次进入知识卡模块时展示，完成后存储 `knowledge_onboarding_done`。
class KnowledgeOnboardingPage extends ConsumerStatefulWidget {
  const KnowledgeOnboardingPage({super.key});

  @override
  ConsumerState<KnowledgeOnboardingPage> createState() =>
      _KnowledgeOnboardingPageState();
}

class _KnowledgeOnboardingPageState
    extends ConsumerState<KnowledgeOnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  /// 用户勾选的目标 key 集合。
  final Set<String> _selectedGoals = {};


  /// 是否已完成过引导（从设置页/管理目标进入时跳过教程）。
  bool _alreadyDone = false;
  static const _introPages = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.library_books_rounded,
      title: '导入资料',
      subtitle: '把你的学习资料导入本地知识库',
      detail: '支持 PDF、Word、网页摘录等多种格式，\n资料全部存在本地，安全不泄露。',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'AI 生成卡片',
      subtitle: 'AI 自动从资料中提取知识点',
      detail: '智能切片 + 语义分析，\n一键生成高质量复习卡片。',
    ),
    _OnboardingSlide(
      icon: Icons.psychology_rounded,
      title: '间隔复习',
      subtitle: '系统按遗忘曲线安排复习',
      detail: '科学间隔，越练越牢，\n薄弱点自动加强。',
    ),
    _OnboardingSlide(
      icon: Icons.trending_up_rounded,
      title: '知识沉淀',
      subtitle: '资料越积越多，知识越用越扎实',
      detail: '每一次复习都在积累，\n形成你自己的知识体系。',
    ),
  ];

  int get _totalPages => _introPages.length + 1; // +1 for goal selection

  bool get _isGoalSelectionPage => _currentPage == _introPages.length;

  @override
  void initState() {
    super.initState();
    _checkAlreadyDone();
  }

  Future<void> _checkAlreadyDone() async {
    final repo = ref.read(settingRepositoryProvider);
    final done = await repo.getSetting('knowledge_onboarding_done');
    if (done == 'true' && mounted) {
      setState(() {
        _alreadyDone = true;
        _currentPage = _introPages.length;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_introPages.length);
        }
      });
      final selectedKeys = await ref.read(selectedGoalKeysProvider.future);
      if (mounted) {
        setState(() {
          _selectedGoals.addAll(selectedKeys);
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    final repo = ref.read(settingRepositoryProvider);

    // 存储选中的目标
    final keys = _selectedGoals.toList();
    if (keys.isNotEmpty) {
      await repo.setSetting('knowledge_selected_goals', jsonEncode(keys));
    }

    // 标记引导完成
    await repo.setSetting('knowledge_onboarding_done', 'true');

    // 刷新相关 provider
    ref.invalidate(selectedGoalKeysProvider);
    ref.invalidate(knowledgeOnboardingDoneProvider);

    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部进度指示器 + 跳过按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  // 返回按钮（非第一页时显示）
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _prevPage,
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? colors.study
                                : colors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  // 跳过按钮
                  TextButton(
                    onPressed: _complete,
                    child: Text(
                      '跳过',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 页面内容
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  if (index < _introPages.length) {
                    return _IntroSlidePage(slide: _introPages[index]);
                  }
                  return _GoalSelectionPage(
                    selectedKeys: _selectedGoals,
                    onToggle: (key) {
                      setState(() {
                        if (_selectedGoals.contains(key)) {
                          _selectedGoals.remove(key);
                        } else {
                          _selectedGoals.add(key);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isGoalSelectionPage ? _complete : _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.study,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    _alreadyDone
                        ? '保存'
                        : _isGoalSelectionPage
                            ? '开始使用'
                            : '下一步',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 内部组件
// =============================================================================

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
}

/// 单步介绍页
class _IntroSlidePage extends StatelessWidget {
  const _IntroSlidePage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colors.study.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 48, color: colors.study),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            slide.title,
            style: AppTextStyles.pageTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.study,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            slide.detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// 目标选择页
class _GoalSelectionPage extends StatelessWidget {
  const _GoalSelectionPage({
    required this.selectedKeys,
    required this.onToggle,
  });

  final Set<String> selectedKeys;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final goals = KnowledgeCardAssets.goalTemplates
        .where((g) => g.key != 'custom')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            '选择你的学习目标',
            style: AppTextStyles.pageTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '勾选你感兴趣的目标，不选则全部显示',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 3 : 2;
                return GridView.builder(
                  itemCount: goals.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.4,
                  ),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final selected = selectedKeys.contains(goal.key);
                    return _GoalPickTile(
                      goal: goal,
                      selected: selected,
                      onTap: () => onToggle(goal.key),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个目标选择卡片
class _GoalPickTile extends StatelessWidget {
  const _GoalPickTile({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final KnowledgeGoalVisual goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colors.study.withValues(alpha: 0.10)
                : colors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? colors.study : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(
                  goal.asset,
                  width: 44,
                  height: 28,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      goal.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? colors.study : colors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
