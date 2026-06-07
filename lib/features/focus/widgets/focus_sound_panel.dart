import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/focus_audio_provider.dart';

class FocusSoundPanel extends ConsumerWidget {
  final String initialSoundType;

  const FocusSoundPanel({super.key, required this.initialSoundType});

  static const _sounds = [
    _SoundOption(value: 'rain', icon: Icons.water_drop, label: '雨声'),
    _SoundOption(value: 'ocean', icon: Icons.waves, label: '海浪'),
    _SoundOption(value: 'forest', icon: Icons.forest, label: '森林'),
    _SoundOption(value: 'cafe', icon: Icons.coffee, label: '咖啡馆'),
    _SoundOption(value: 'white_noise', icon: Icons.surround_sound, label: '白噪声'),
    _SoundOption(value: 'none', icon: Icons.volume_off, label: '无'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(focusAudioStateProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('白噪音', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sounds.map((sound) {
              final isSelected = sound.value == 'none'
                  ? audioState.currentSoundType == null
                  : audioState.currentSoundType == sound.value;

              return GestureDetector(
                onTap: () {
                  if (sound.value == 'none') {
                    ref.read(focusAudioStateProvider.notifier).stopNoise();
                  } else {
                    ref.read(focusAudioStateProvider.notifier).changeSound(sound.value);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sound.icon,
                        size: 16,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sound.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.volume_down, size: 18, color: AppColors.textTertiary),
              Expanded(
                child: Slider(
                  value: audioState.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (v) {
                    ref.read(focusAudioStateProvider.notifier).setVolume(v);
                  },
                ),
              ),
              Icon(Icons.volume_up, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

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
