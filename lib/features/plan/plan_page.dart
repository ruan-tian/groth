import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/design.dart';
import '../../core/domain/pet/pet_event.dart';
import '../../core/services/pet_event_bus.dart';
import '../study/study_page.dart';
import '../fitness/fitness_page.dart';
import '../journal/journal_page.dart';
import '../health/diet_page.dart';
import '../health/sleep_page.dart';

/// 计划模块主页面
///
/// 包含5个子页面：学习、健身、日记、饮食、睡眠
/// 胶囊导航为独立层级
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  int _currentIndex = 0;
  late final PageController _pageController;

  List<_PlanTab> _getTabs(BuildContext context) {
    final colors = context.growthColors;
    return [
      _PlanTab(label: '学习', color: colors.study),
      _PlanTab(label: '健身', color: colors.fitness),
      _PlanTab(label: '日记', color: colors.journal),
      _PlanTab(label: '饮食', color: colors.diet),
      _PlanTab(label: '睡眠', color: colors.sleep),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    final modules = ['study', 'fitness', 'journal', 'diet', 'sleep'];
    if (index >= 0 && index < modules.length) {
      PetEventBus.instance.emit(PetEvent.pageEntered(module: modules[index]));
    }
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          _buildCapsuleNav(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                StudyPage(isEmbedded: true),
                FitnessPage(isEmbedded: true),
                JournalPage(isEmbedded: true),
                DietPage(isEmbedded: true),
                SleepPage(isEmbedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建胶囊导航栏
  Widget _buildCapsuleNav() {
    final colors = context.growthColors;
    final tabs = _getTabs(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      color: colors.paper,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.card, colors.surfaceTint],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: tabs[_currentIndex].color.withValues(alpha: 0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = (constraints.maxWidth - 6) / tabs.length;

              return Stack(
                children: [
                  // ── 滑动指示器 ──
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: tabWidth * _currentIndex + 3 * _currentIndex,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colors.card.withValues(alpha: 0.9),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: tabs[_currentIndex].color.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Tab 项 ──
                  Row(
                    children: tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = index == _currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabTapped(index),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? tab.color
                                    : colors.textTertiary,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tab 配置数据
class _PlanTab {
  const _PlanTab({required this.label, required this.color});
  final String label;
  final Color color;
}
