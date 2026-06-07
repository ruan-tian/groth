import 'package:flutter/material.dart';

/// 心情选择器
///
/// 展示一组心情 emoji，点击选中后返回对应的心情字符串。
/// 支持的心情值: happy, neutral, sad, angry, thinking
class MoodSelector extends StatelessWidget {
  /// 当前选中的心情
  final String? selectedMood;

  /// 心情变更回调
  final ValueChanged<String> onMoodChanged;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodChanged,
  });

  static const _moods = [
    _MoodOption(value: 'happy', emoji: '😊', label: '开心'),
    _MoodOption(value: 'neutral', emoji: '😐', label: '平静'),
    _MoodOption(value: 'sad', emoji: '😢', label: '难过'),
    _MoodOption(value: 'angry', emoji: '😡', label: '生气'),
    _MoodOption(value: 'thinking', emoji: '🤔', label: '思考'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _moods.map((mood) {
        final isSelected = selectedMood == mood.value;
        return GestureDetector(
          onTap: () => onMoodChanged(mood.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 32 : 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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

/// 心情选项数据
class _MoodOption {
  final String value;
  final String emoji;
  final String label;

  const _MoodOption({
    required this.value,
    required this.emoji,
    required this.label,
  });
}
