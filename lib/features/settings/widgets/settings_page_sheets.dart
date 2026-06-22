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
    final categories = <String, List<_GoalItem>>{};
    for (final goal in _goals) {
      categories.putIfAbsent(goal.category, () => []).add(goal);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
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
              const SizedBox(height: 16),
              Text(
                '今日目标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击目标项可修改数值',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textTertiary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final categoryName = categories.keys.elementAt(index);
                    final items = categories[categoryName]!;
                    return _buildCategory(categoryName, items);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
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
                        fontSize: 15,
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

  Widget _buildCategory(String name, List<_GoalItem> items) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...items.map(_buildGoalTile),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGoalTile(_GoalItem goal) {
    final colors = context.growthColors;
    return GestureDetector(
      onTap: () => _showGoalEditDialog(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(goal.icon, color: goal.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.value} ${goal.unit}',
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${goal.value}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: goal.color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: colors.textTertiary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoalEditDialog(_GoalItem goal) async {
    final colors = context.growthColors;
    final controller = TextEditingController(text: goal.value.toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(goal.icon, color: goal.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '目标值',
                    suffixText: goal.unit,
                    suffixStyle: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goal.color, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入目标值';
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) return '请输入正整数';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '当前设定: ${goal.value} ${goal.unit}',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: colors.textTertiary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, int.parse(controller.text));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: goal.color,
                foregroundColor: colors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        goal.value = result;
      });
    }
  }
}

class _LevelDetailSheet extends StatelessWidget {
  const _LevelDetailSheet({
    required this.currentLevel,
    required this.totalExp,
    required this.expProgress,
  });

  final int currentLevel;
  final int totalExp;
  final int expProgress;

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
              color: colors.border,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),
          _buildCurrentLevel(context, progress, nextLevelExp),
          const SizedBox(height: 24),
          Expanded(child: _buildLevelTiers(context)),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel(
    BuildContext context,
    double progress,
    int nextLevelExp,
  ) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Lv.$currentLevel',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textOnAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getLevelName(currentLevel),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'EXP $totalExp / $nextLevelExp',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
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

  Widget _buildLevelTiers(BuildContext context) {
    final colors = context.growthColors;
    final tiers = [
      _LevelTier(level: 1, name: '萌新', minExp: 0, color: colors.textTertiary),
      _LevelTier(level: 5, name: '探索者', minExp: 1600, color: colors.success),
      _LevelTier(level: 10, name: '实践者', minExp: 8100, color: colors.study),
      _LevelTier(level: 15, name: '进阶者', minExp: 20000, color: colors.primary),
      _LevelTier(level: 20, name: '精英', minExp: 38000, color: colors.warning),
      _LevelTier(level: 30, name: '大师', minExp: 85000, color: colors.journal),
      _LevelTier(level: 50, name: '传奇', minExp: 250000, color: colors.fitness),
      _LevelTier(level: 80, name: '神话', minExp: 640000, color: colors.sleep),
      _LevelTier(level: 100, name: '永恒', minExp: 1000000, color: colors.accent),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        final isUnlocked = currentLevel >= tier.level;
        final isCurrent =
            currentLevel >= tier.level &&
            (index == tiers.length - 1 ||
                currentLevel < tiers[index + 1].level);

        return _buildTierItem(context, tier, isUnlocked, isCurrent);
      },
    );
  }

  Widget _buildTierItem(
    BuildContext context,
    _LevelTier tier,
    bool isUnlocked,
    bool isCurrent,
  ) {
    final colors = context.growthColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? tier.color.withValues(alpha: 0.1) : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: tier.color, width: 2)
            : Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? tier.color.withValues(alpha: 0.15)
                  : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Lv.${tier.level}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? tier.color : colors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked
                        ? colors.textPrimary
                        : colors.textTertiary,
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
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tier.color,
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
            Icon(Icons.check_circle_rounded, size: 20, color: tier.color)
          else
            Icon(Icons.lock_outline_rounded, size: 20, color: colors.textHint),
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

class _LevelTier {
  const _LevelTier({
    required this.level,
    required this.name,
    required this.minExp,
    required this.color,
  });

  final int level;
  final String name;
  final int minExp;
  final Color color;
}
