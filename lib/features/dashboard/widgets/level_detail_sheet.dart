import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// 等级详情底部弹窗
///
/// 白色20px圆角矩形弹窗，展示：
/// - 紫色六边形等级图标 + 等级名称 + 经验值
/// - 等级体系列表（当前等级和相邻等级）
/// - 当前等级权益列表（紫色对勾）
/// - 底部提示文字
class LevelDetailSheet extends StatelessWidget {
  const LevelDetailSheet({
    super.key,
    required this.currentLevel,
    required this.totalExp,
  });

  /// 当前等级
  final int currentLevel;

  /// 总经验值
  final int totalExp;

  /// 显示等级详情底部弹窗
  static Future<void> show(
    BuildContext context, {
    required int currentLevel,
    required int totalExp,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LevelDetailSheet(
        currentLevel: currentLevel,
        totalExp: totalExp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: GrowthColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x146B5CEA),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部拖拽指示器
          _buildDragHandle(),

          // 头部：紫色六边形等级图标 + 等级名称 + 经验值
          _buildHeader(),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // 等级体系列表
          Expanded(
            child: _buildLevelList(),
          ),

          // 当前等级权益列表
          _buildBenefitsList(),

          // 底部提示文字
          _buildFooterHint(),
        ],
      ),
    );
  }

  /// 顶部拖拽指示器
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: GrowthColors.textHint.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 头部：紫色六边形等级图标 + 等级名称 + 经验值
  Widget _buildHeader() {
    final levelData = _getLevelDataForLevel(currentLevel);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 紫色六边形等级图标
          _buildHexagonIcon(currentLevel),
          const SizedBox(width: 16),

          // 等级名称 + 经验值
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.$currentLevel ${levelData?.name ?? '未知'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GrowthColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '总经验值: $totalExp EXP',
                  style: const TextStyle(
                    fontSize: 14,
                    color: GrowthColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 紫色六边形等级图标
  Widget _buildHexagonIcon(int level) {
    return ClipPath(
      clipper: _HexagonClipper(),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [GrowthColors.primaryLight, GrowthColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            '$level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  /// 等级体系列表（显示当前等级和相邻等级）
  Widget _buildLevelList() {
    final allLevels = _getAllLevelData();
    final currentIndex = allLevels.indexWhere((l) => l.level == currentLevel);

    // 显示当前等级前后各2个等级
    final startIndex = (currentIndex - 2).clamp(0, allLevels.length - 1);
    final endIndex = (currentIndex + 3).clamp(0, allLevels.length);
    final displayLevels = allLevels.sublist(startIndex, endIndex);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayLevels.length,
      itemBuilder: (context, index) {
        final levelData = displayLevels[index];
        final isCurrentLevel = levelData.level == currentLevel;
        final isUnlocked = levelData.level <= currentLevel;

        return _LevelTile(
          levelData: levelData,
          isCurrentLevel: isCurrentLevel,
          isUnlocked: isUnlocked,
          totalExp: totalExp,
        );
      },
    );
  }

  /// 当前等级权益列表（紫色对勾）
  Widget _buildBenefitsList() {
    final benefits = _getBenefitsForLevel(currentLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前权益',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: GrowthColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: GrowthColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: GrowthColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// 底部提示文字
  Widget _buildFooterHint() {
    final nextLevelExp = (currentLevel) * (currentLevel) * 100;
    final remainingExp = nextLevelExp - totalExp;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        remainingExp > 0
            ? '距离下一级还需 $remainingExp 经验值，继续加油！'
            : '已达最高等级，继续积累经验值吧！',
        style: const TextStyle(
          fontSize: 12,
          color: GrowthColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 获取指定等级数据
  LevelData? _getLevelDataForLevel(int level) {
    try {
      return _getAllLevelData().firstWhere((l) => l.level == level);
    } catch (_) {
      return null;
    }
  }

  /// 获取指定等级权益
  List<String> _getBenefitsForLevel(int level) {
    if (level >= 100) return ['解锁所有功能', '专属称号', '无限存储'];
    if (level >= 50) return ['高级统计', '自定义主题', '数据导出'];
    if (level >= 20) return ['AI 周报', '详细分析', '历史对比'];
    if (level >= 10) return ['中级统计', '更多图表', '进度追踪'];
    if (level >= 5) return ['基础统计', '成长图表', '每日回顾'];
    return ['基础记录', '经验值获取', '等级提升'];
  }

  /// 获取所有等级数据
  List<LevelData> _getAllLevelData() {
    return [
      const LevelData(level: 1, name: '萌新', icon: Icons.child_care, color: Colors.grey, requiredExp: 0),
      const LevelData(level: 2, name: '探索者', icon: Icons.explore, color: Colors.brown, requiredExp: 100),
      const LevelData(level: 3, name: '新手', icon: Icons.school, color: Colors.orange, requiredExp: 400),
      const LevelData(level: 5, name: '入门者', icon: Icons.auto_stories, color: Colors.blue, requiredExp: 1600),
      const LevelData(level: 8, name: '学习者', icon: Icons.psychology, color: Colors.teal, requiredExp: 4900),
      const LevelData(level: 10, name: '进阶者', icon: Icons.trending_up, color: Colors.green, requiredExp: 8100),
      const LevelData(level: 15, name: '高手', icon: Icons.star, color: Colors.purple, requiredExp: 19600),
      const LevelData(level: 20, name: '精英', icon: Icons.diamond, color: Colors.indigo, requiredExp: 36100),
      const LevelData(level: 30, name: '大师', icon: Icons.workspace_premium, color: Colors.amber, requiredExp: 84100),
      const LevelData(level: 50, name: '传奇', icon: Icons.local_fire_department, color: Colors.red, requiredExp: 240100),
      const LevelData(level: 80, name: '神话', icon: Icons.auto_fix_high, color: Colors.deepOrange, requiredExp: 624100),
      const LevelData(level: 100, name: '永恒', icon: Icons.all_inclusive, color: Colors.black87, requiredExp: 980100),
    ];
  }
}

/// 等级数据模型
class LevelData {
  const LevelData({
    required this.level,
    required this.name,
    required this.icon,
    required this.color,
    required this.requiredExp,
  });

  final int level;
  final String name;
  final IconData icon;
  final Color color;
  final int requiredExp;
}

/// 六边形裁剪器
class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 单个等级磁贴
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.levelData,
    required this.isCurrentLevel,
    required this.isUnlocked,
    required this.totalExp,
  });

  final LevelData levelData;
  final bool isCurrentLevel;
  final bool isUnlocked;
  final int totalExp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isCurrentLevel
            ? GrowthColors.primaryLight.withValues(alpha: 0.3)
            : null,
        border: isCurrentLevel
            ? Border.all(
                color: GrowthColors.primary.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildIcon(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked
            ? levelData.color.withValues(alpha: 0.15)
            : GrowthColors.textHint.withValues(alpha: 0.3),
      ),
      child: Icon(
        levelData.icon,
        color: isUnlocked
            ? levelData.color
            : GrowthColors.textHint.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Text(
          'Lv.${levelData.level}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isUnlocked
                ? GrowthColors.textSecondary
                : GrowthColors.textHint,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          levelData.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.w500,
            color: isUnlocked
                ? GrowthColors.textPrimary
                : GrowthColors.textHint,
          ),
        ),
        if (isCurrentLevel) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: GrowthColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '当前',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '需要 ${_formatExp(levelData.requiredExp)} EXP',
        style: TextStyle(
          fontSize: 12,
          color: isUnlocked
              ? GrowthColors.primary
              : GrowthColors.textHint,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (isUnlocked && !isCurrentLevel) {
      return const Icon(
        Icons.check_circle,
        color: GrowthColors.success,
        size: 24,
      );
    }

    if (!isUnlocked) {
      return Icon(
        Icons.lock_outline,
        color: GrowthColors.textHint.withValues(alpha: 0.5),
        size: 24,
      );
    }

    // 当前等级显示进度
    final currentLevelStart = (levelData.level - 1) * (levelData.level - 1) * 100;
    final nextLevelExp = levelData.level * levelData.level * 100;
    final progressExp = totalExp - currentLevelStart;
    final requiredForNext = nextLevelExp - currentLevelStart;
    final progress = requiredForNext > 0
        ? (progressExp / requiredForNext).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: GrowthColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: GrowthColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                GrowthColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExp(int exp) {
    if (exp >= 10000) {
      return '${(exp / 10000).toStringAsFixed(1)}万';
    }
    if (exp >= 1000) {
      return '${(exp / 1000).toStringAsFixed(1)}k';
    }
    return exp.toString();
  }
}
