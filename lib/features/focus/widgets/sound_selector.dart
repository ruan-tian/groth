import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../utils/focus_options.dart';

class SoundSelector extends StatelessWidget {
  const SoundSelector({
    super.key,
    this.selectedSound,
    required this.onSoundChanged,
    this.compact = false,
  });

  final String? selectedSound;
  final ValueChanged<String> onSoundChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = selectedSound ?? 'none';
    return Wrap(
      spacing: compact ? 8 : 12,
      runSpacing: compact ? 8 : 12,
      children: focusSoundOptions
          .map((sound) {
            final isSelected = selected == sound.value;
            return _SoundChip(
              label: sound.label,
              asset: sound.asset,
              selected: isSelected,
              compact: compact,
              onTap: () => onSoundChanged(sound.value),
            );
          })
          .toList(growable: false),
    );
  }
}

class _SoundChip extends StatelessWidget {
  const _SoundChip({
    required this.label,
    required this.asset,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final primary = colors.focus;
    final border = selected ? primary : colors.border;
    final background = selected
        ? primary.withValues(alpha: 0.10)
        : colors.card.withValues(alpha: 0.72);
    final imageSize = compact ? 24.0 : 30.0;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(compact ? 16 : 22),
            border: Border.all(color: border, width: selected ? 1.8 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(asset, width: imageSize, height: imageSize),
              SizedBox(width: compact ? 5 : 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? colors.focus : colors.textSecondary,
                  fontSize: compact ? 12 : 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
