import 'package:flutter/material.dart';

/// 标签选择器
///
/// 展示一组预定义标签，支持多选。
/// 使用 Wrap 布局，标签以 FilterChip 形式展示。
class TagSelector extends StatelessWidget {
  /// 当前选中的标签列表
  final List<String> selectedTags;

  /// 标签变更回调
  final ValueChanged<List<String>> onTagsChanged;

  /// 可选的标签列表（默认为预定义标签）
  final List<String>? availableTags;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.availableTags,
  });

  /// 预定义标签
  static const _defaultTags = [
    '学习',
    '健身',
    '情绪',
    '反思',
    '工作',
    '生活',
    '健康',
    '成长',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = availableTags ?? _defaultTags;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            final newTags = List<String>.from(selectedTags);
            if (selected) {
              newTags.add(tag);
            } else {
              newTags.remove(tag);
            }
            onTagsChanged(newTags);
          },
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.onPrimaryContainer,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.textTheme.bodyMedium?.color,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
