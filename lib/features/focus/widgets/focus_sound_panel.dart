import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/focus_audio_provider.dart';
import '../utils/focus_options.dart';

class FocusSoundPanel extends ConsumerWidget {
  const FocusSoundPanel({
    super.key,
    required this.initialSoundType,
    this.compact = false,
    this.dark = false,
  });

  final String initialSoundType;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(focusAudioStateProvider);
    final current = audioState.currentSoundType ?? initialSoundType;
    final titleColor = dark ? const Color(0xFFF9E8C8) : const Color(0xFF2D3636);
    final bodyColor = dark ? const Color(0xFFC6EDE7) : const Color(0xFF64716F);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xCC092A35)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? const Color(0x66F5D9AC) : const Color(0xFFE8DDD1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: titleColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '白噪音',
                style: TextStyle(
                  color: titleColor,
                  fontSize: compact ? 15 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                audioState.isPlaying && current != 'none'
                    ? '专注中，享受宁静时刻'
                    : '安静模式',
                style: TextStyle(
                  color: bodyColor,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: compact ? 8 : 10,
            runSpacing: compact ? 8 : 10,
            children: focusSoundOptions
                .map((sound) {
                  final selected =
                      current == sound.value ||
                      (sound.value == 'none' &&
                          audioState.currentSoundType == null);
                  return _SessionSoundTile(
                    label: sound.label,
                    asset: sound.asset,
                    selected: selected,
                    compact: compact,
                    dark: dark,
                    onTap: () {
                      if (sound.value == 'none') {
                        ref.read(focusAudioStateProvider.notifier).stopNoise();
                      } else {
                        ref
                            .read(focusAudioStateProvider.notifier)
                            .changeSound(sound.value);
                      }
                    },
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '音量',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.volume_down_rounded, size: 18, color: bodyColor),
              Expanded(
                child: Slider(
                  value: audioState.volume,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  activeColor: const Color(0xFF9DEBD8),
                  inactiveColor: dark
                      ? const Color(0x335BE0C8)
                      : const Color(0xFFE1ECE9),
                  onChanged: (value) {
                    ref.read(focusAudioStateProvider.notifier).setVolume(value);
                  },
                ),
              ),
              Text(
                '${(audioState.volume * 100).round()}%',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionSoundTile extends StatelessWidget {
  const _SessionSoundTile({
    required this.label,
    required this.asset,
    required this.selected,
    required this.compact,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final bool compact;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = dark
        ? const Color(0xFFBDF5E5)
        : const Color(0xFF3EB3A7);
    final textColor = selected
        ? selectedColor
        : dark
        ? const Color(0xFFEBDCC2)
        : const Color(0xFF5D6765);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: compact ? 74 : 84,
        padding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 10,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: dark ? 0.16 : 0.12)
              : (dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? selectedColor
                : (dark ? const Color(0x337F9FA4) : const Color(0xFFE5DDD5)),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: compact ? 32 : 38,
              height: compact ? 32 : 38,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: compact ? 11 : 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
