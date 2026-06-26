part of '../settings_page.dart';

class _GoalItem {
  _GoalItem({
    required this.category,
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
  });

  final String category;
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  int value;
  final String unit;

  _GoalItem copy() => _GoalItem(
    category: category,
    key: key,
    label: label,
    icon: icon,
    color: color,
    value: value,
    unit: unit,
  );
}

class _DailyGoalsSheet extends StatefulWidget {
  const _DailyGoalsSheet({required this.goals});

  final List<_GoalItem> goals;

  @override
  State<_DailyGoalsSheet> createState() => _DailyGoalsSheetState();
}

class _DailyGoalsSheetState extends State<_DailyGoalsSheet> {
  late final List<_GoalItem> _goals;

  @override
  void initState() {
    super.initState();
    _goals = widget.goals.map((g) => g.copy()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final shortTerm = _goals.where((g) => g.category == '短期目标').toList();
    final longTerm = _goals.where((g) => g.category == '长期目标').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '今日目标',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (shortTerm.isNotEmpty) ...[
                      _SectionHeader(title: '短期目标'),
                      const SizedBox(height: 8),
                      for (final goal in shortTerm) _buildGoalTile(goal),
                    ],
                    if (longTerm.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(title: '长期目标'),
                      const SizedBox(height: 8),
                      for (final goal in longTerm) _buildGoalTile(goal),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _goals),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '保存目标',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalTile(_GoalItem goal) {
    final colors = context.growthColors;
    // 图标背景色：使用目标模块色 12% 透明度（参考 iOS 设置页风格）
    final iconBgColor = goal.color.withValues(alpha: 0.12);
    // 图标颜色：使用目标模块色（不透明，清晰可辨）
    final iconColor = goal.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showGoalEditSheet(goal),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 图标容器：iOS 风格圆角方形背景 + 模块色图标
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(goal.icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    goal.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${goal.value} ${goal.unit}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGoalEditSheet(_GoalItem goal) async {
    await GoalEditSheet.show(
      context: context,
      title: goal.label,
      currentValue: goal.value,
      unit: goal.unit,
      onSave: (newValue) {
        setState(() => goal.value = newValue);
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LevelDetailSheet extends StatelessWidget {
  const _LevelDetailSheet({
    required this.currentLevel,
    required this.totalExp,
    required this.expProgress,
    required this.avatarPath,
  });

  final int currentLevel;
  final int totalExp;
  final int expProgress;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final nextLevelExp = ExpService.getExpForNextLevel(currentLevel);
    final progress = nextLevelExp > 0
        ? (expProgress / nextLevelExp).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: colors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),
          _buildCurrentLevel(context, progress, nextLevelExp, colors),
          const SizedBox(height: 24),
          Expanded(child: _buildLevelTiers(context, colors)),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel(
    BuildContext context,
    double progress,
    int nextLevelExp,
    AppThemeColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 头像（与设置页面共享）
          _LevelAvatar(avatarPath: avatarPath),
          const SizedBox(height: 16),
          // 等级名称
          Text(
            'Lv.$currentLevel · ${_getLevelName(currentLevel)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // EXP 进度
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'EXP $totalExp',
                style: TextStyle(fontSize: 13, color: colors.textTertiary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 13, color: colors.textHint),
                ),
              ),
              Text(
                '$nextLevelExp',
                style: TextStyle(fontSize: 13, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.study.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colors.study),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '距离下一级还需 ${nextLevelExp - expProgress} EXP',
            style: TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTiers(BuildContext context, AppThemeColors colors) {
    final tiers = [
      _LevelTier(level: 1, name: '萌新', minExp: 0),
      _LevelTier(level: 5, name: '探索者', minExp: 1600),
      _LevelTier(level: 10, name: '实践者', minExp: 8100),
      _LevelTier(level: 15, name: '进阶者', minExp: 20000),
      _LevelTier(level: 20, name: '精英', minExp: 38000),
      _LevelTier(level: 30, name: '大师', minExp: 85000),
      _LevelTier(level: 50, name: '传奇', minExp: 250000),
      _LevelTier(level: 80, name: '神话', minExp: 640000),
      _LevelTier(level: 100, name: '永恒', minExp: 1000000),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '等级旅程',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: tiers.length,
            itemBuilder: (context, index) {
              final tier = tiers[index];
              final isUnlocked = currentLevel >= tier.level;
              final isCurrent =
                  currentLevel >= tier.level &&
                  (index == tiers.length - 1 ||
                      currentLevel < tiers[index + 1].level);

              return _buildTierItem(context, tier, isUnlocked, isCurrent, colors);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTierItem(
    BuildContext context,
    _LevelTier tier,
    bool isUnlocked,
    bool isCurrent,
    AppThemeColors colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.study.withValues(alpha: 0.06)
            : colors.card,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(color: colors.study.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // 等级标识
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? colors.study.withValues(alpha: 0.1)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Lv.${tier.level}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? colors.study : colors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 等级名称 + EXP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? colors.textPrimary : colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tier.minExp} EXP',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? colors.textSecondary : colors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // 状态标识
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.study,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '当前',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textOnAccent,
                ),
              ),
            )
          else if (isUnlocked)
            Icon(Icons.check_circle_rounded, size: 20, color: colors.study)
          else
            Icon(Icons.lock_outline_rounded, size: 18, color: colors.textHint),
        ],
      ),
    );
  }

  String _getLevelName(int level) {
    if (level < 5) return '萌新';
    if (level < 10) return '探索者';
    if (level < 15) return '实践者';
    if (level < 20) return '进阶者';
    if (level < 30) return '精英';
    if (level < 50) return '大师';
    if (level < 80) return '传奇';
    if (level < 100) return '神话';
    return '永恒';
  }
}

/// 等级详情页头像（与设置页面共享）
class _LevelAvatar extends StatelessWidget {
  const _LevelAvatar({required this.avatarPath});

  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final path = normalizeUserAvatarPath(avatarPath);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border, width: 2),
      ),
      child: path != null && File(path).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    FitnessTimerAssets.catAvatarDefault,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                FitnessTimerAssets.catAvatarDefault,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _LevelTier {
  const _LevelTier({
    required this.level,
    required this.name,
    required this.minExp,
  });

  final int level;
  final String name;
  final int minExp;
}
