import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/settings_provider.dart';

/// 基本信息区块（性别、生日、身高）
class ProfileBasicInfoGroup extends StatelessWidget {
  final String gender;
  final DateTime birthday;
  final String heightText;
  final VoidCallback onGenderTap;
  final VoidCallback onBirthdayTap;
  final VoidCallback onHeightTap;

  const ProfileBasicInfoGroup({
    super.key,
    required this.gender,
    required this.birthday,
    required this.heightText,
    required this.onGenderTap,
    required this.onBirthdayTap,
    required this.onHeightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ProfileInfoTile(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF5D68F2),
            label: '性别',
            value: gender == 'male' ? '男' : '女',
            onTap: onGenderTap,
          ),
          _divider(),
          ProfileInfoTile(
            icon: Icons.cake_outlined,
            iconColor: const Color(0xFFFF8A3D),
            label: '生日',
            value: '${birthday.year}年${birthday.month}月${birthday.day}日',
            onTap: onBirthdayTap,
          ),
          _divider(),
          ProfileInfoTile(
            icon: Icons.height,
            iconColor: const Color(0xFF35C976),
            label: '身高',
            value: heightText.isNotEmpty ? '$heightText cm' : '未设置',
            onTap: onHeightTap,
          ),
        ],
      ),
    );
  }
}

/// 身体数据区块（体重、体脂率、BMI — 支持手动编辑 + 自动同步）
class ProfileBodyDataGroup extends StatelessWidget {
  final AsyncValue<BodyMetric?> latestWeight;
  final String heightText;
  final VoidCallback? onWeightTap;
  final VoidCallback? onBodyFatTap;

  const ProfileBodyDataGroup({
    super.key,
    required this.latestWeight,
    required this.heightText,
    this.onWeightTap,
    this.onBodyFatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: latestWeight.when(
        data: (metric) => Column(
          children: [
            ProfileInfoTile(
              icon: Icons.monitor_weight_outlined,
              iconColor: const Color(0xFF5D68F2),
              label: '体重',
              value: metric?.weight != null
                  ? '${metric!.weight!.toStringAsFixed(1)} kg'
                  : '点击设置',
              subtitle: '点击编辑',
              onTap: onWeightTap,
            ),
            _divider(),
            ProfileInfoTile(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFFFF8A3D),
              label: '体脂率',
              value: metric?.bodyFat != null
                  ? '${metric!.bodyFat!.toStringAsFixed(1)}%'
                  : '点击设置',
              subtitle: '点击编辑',
              onTap: onBodyFatTap,
            ),
            _divider(),
            ProfileInfoTile(
              icon: Icons.analytics_outlined,
              iconColor: const Color(0xFF7058F5),
              label: 'BMI',
              value: _calculateBMI(metric),
              subtitle: '根据身高体重计算',
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) =>
            const Padding(padding: EdgeInsets.all(20), child: Text('加载失败')),
      ),
    );
  }

  String _calculateBMI(BodyMetric? metric) {
    final weight = metric?.weight;
    if (weight == null || heightText.isEmpty) {
      return '需要身高体重';
    }
    final height = double.tryParse(heightText);
    if (height == null || height <= 0) return '身高数据异常';

    final bmi = calculateBMI(weight, height);
    if (bmi == null) return '计算失败';

    final category = getBMICategory(bmi);
    return '${bmi.toStringAsFixed(1)} ($category)';
  }
}

// =============================================================================
// 通用信息行组件
// =============================================================================

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: onTap != null ? '$label：$value' : null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5C3D2E),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB0A09A),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B6F5E),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFB0A09A),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _divider() {
  return Divider(
    height: 1,
    indent: 64,
    color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
  );
}
