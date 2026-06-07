import 'package:flutter/material.dart';

/// 白噪音/环境音选择器
///
/// 展示可选的环境音列表（雨声、海浪、森林、咖啡馆、白噪声、无），
/// 点击选中后通过 [onSoundChanged] 回调返回对应的音效类型字符串。
/// 选中项以高亮卡片样式展示。
class SoundSelector extends StatelessWidget {
  /// 当前选中的音效类型
  final String? selectedSound;

  /// 音效变更回调，返回音效类型字符串（如 'rain'、'none'）
  final ValueChanged<String> onSoundChanged;

  const SoundSelector({
    super.key,
    this.selectedSound,
    required this.onSoundChanged,
  });

  static const _sounds = [
    _SoundOption(value: 'rain', icon: Icons.water_drop, label: '雨声'),
    _SoundOption(value: 'ocean', icon: Icons.waves, label: '海浪'),
    _SoundOption(value: 'forest', icon: Icons.forest, label: '森林'),
    _SoundOption(value: 'cafe', icon: Icons.coffee, label: '咖啡馆'),
    _SoundOption(value: 'white_noise', icon: Icons.surround_sound, label: '白噪声'),
    _SoundOption(value: 'none', icon: Icons.volume_off, label: '无'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _sounds.map((sound) {
        final isSelected = selectedSound == sound.value;
        return GestureDetector(
          onTap: () => onSoundChanged(sound.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sound.icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  sound.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 音效选项数据
class _SoundOption {
  final String value;
  final IconData icon;
  final String label;

  const _SoundOption({
    required this.value,
    required this.icon,
    required this.label,
  });
}
