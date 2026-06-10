import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/pet_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/settings_provider.dart';
import '../services/pet_diary_service.dart';
import '../../../core/constants/pet_assets.dart';
import '../widgets/pet_floating_asset.dart';

class PetSettingsPage extends ConsumerStatefulWidget {
  const PetSettingsPage({super.key});

  @override
  ConsumerState<PetSettingsPage> createState() => _PetSettingsPageState();
}

class _PetSettingsPageState extends ConsumerState<PetSettingsPage> {
  final _nameController = TextEditingController();
  bool _nameTouched = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameAsync = ref.watch(petNameProvider);
    final autoDiaryAsync = ref.watch(
      settingProvider(PetDiaryService.autoEnabledKey),
    );
    final autoDiary = autoDiaryAsync.valueOrNull == 'true';

    final loadedName = nameAsync.valueOrNull;
    if (!_nameTouched && loadedName != null && _nameController.text.isEmpty) {
      _nameController.text = loadedName;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EF),
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
          _HeroCard(name: loadedName ?? '甜甜'),
          const SizedBox(height: 16),
          _PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(
                  asset: PetCenterAssets.decoPencil,
                  title: '宠物名称',
                  subtitle: '只影响小窝里的称呼，不影响成长经验',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  maxLength: 12,
                  onChanged: (_) => _nameTouched = true,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '给甜甜取个名字',
                    filled: true,
                    fillColor: const Color(0xFFFFF8F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveName,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('保存名称'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE89B68),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                    activeThumbColor: const Color(0xFFE89B68),
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
                  subtitle: '小窝会跟随系统“减少动画”设置，关闭循环粒子和漂浮动画。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final name = normalizePetName(_nameController.text);
    HapticFeedback.selectionClick();
    await ref.read(petRepositoryProvider).updateName(name);
    ref.invalidate(petProfileProvider);
    ref.invalidate(petNameProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('宠物名称已保存')));
  }

  Future<void> _setAutoDiary(bool value) async {
    HapticFeedback.selectionClick();
    await ref
        .read(settingRepositoryProvider)
        .setSetting(PetDiaryService.autoEnabledKey, value.toString());
    ref.invalidate(settingProvider(PetDiaryService.autoEnabledKey));
    ref.invalidate(settingsProvider);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
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
                  '$name 的偏好',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '这里专管小窝体验，通用主题、备份和账号资料仍然在“我的”设置里。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB97A52).withValues(alpha: 0.10),
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
    return Divider(
      height: 20,
      color: const Color(0xFFE8D3C4).withValues(alpha: 0.55),
    );
  }
}
