import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/constants/pet_assets.dart';
import '../providers/pet_diary_provider.dart';
import '../widgets/pet_floating_asset.dart';

class PetSettingsPage extends ConsumerStatefulWidget {
  const PetSettingsPage({super.key});

  @override
  ConsumerState<PetSettingsPage> createState() => _PetSettingsPageState();
}

class _PetSettingsPageState extends ConsumerState<PetSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    ref.watch(petDiaryAutoEnabledInitProvider);
    final autoDiary = ref.watch(petDiaryAutoEnabledProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('小窝设置'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _HeroCard(),
          const SizedBox(height: 16),
          _PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(
                  asset: PetCenterAssets.decoPencil,
                  title: '宠物名称',
                  subtitle: '甜甜是你的专属成长伙伴，固定名称不可修改',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '甜甜',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PaperCard(
            child: Column(
              children: [
                _SettingRow(
                  asset: PetCenterAssets.decoBook,
                  title: '自动小日记',
                  subtitle: '开启后，甜甜会在满足条件时整理昨日摘要',
                  trailing: Switch(
                    value: autoDiary,
                    activeThumbColor: colors.accent,
                    onChanged: (value) => _setAutoDiary(value),
                  ),
                ),
                const _Divider(),
                _SettingRow(
                  asset: PetAssets.aiPrivacy,
                  title: 'AI 配置',
                  subtitle: '配置本地保存的 API Key 和模型',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/ai-config'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _PaperCard(
            child: Column(
              children: [
                _SettingRow(
                  asset: PetAssets.aiPrivacy,
                  title: '隐私说明',
                  subtitle: 'AI 分析和小日记都会先做数据预览；确认后才会发送给你配置的模型。',
                ),
                _Divider(),
                _SettingRow(
                  asset: PetCenterAssets.decoStar,
                  title: '减少动态效果',
                  subtitle: '自动跟随系统"减少动画"设置，无需手动调整。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setAutoDiary(bool value) async {
    HapticFeedback.selectionClick();
    await savePetDiaryAutoEnabled(ref, value);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _PaperCard(
      child: Row(
        children: [
          const PetFloatingAsset(
            asset: PetCenterAssets.petIdle,
            size: 82,
            padding: 1,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '甜甜的偏好',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '这里专管小窝体验，通用主题、备份和账号资料仍然在"我的"设置里。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.asset,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String asset;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _ImageBadge(asset: asset),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  final String asset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        _ImageBadge(asset: asset),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return PetFloatingAsset(asset: asset, size: 42, padding: 1);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Divider(height: 20, color: colors.divider);
  }
}
