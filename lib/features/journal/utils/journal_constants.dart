import 'package:flutter/material.dart';

/// 日记模块常量
///
/// 心情、标签、引导提示等统一定义，避免重复硬编码。

// =============================================================================
// 心情定义
// =============================================================================

class MoodOption {
  const MoodOption({
    required this.key,
    required this.emoji,
    required this.label,
  });

  final String key;
  final String emoji;
  final String label;
}

const List<MoodOption> moodOptions = [
  MoodOption(key: 'happy', emoji: '😊', label: '开心'),
  MoodOption(key: 'neutral', emoji: '😐', label: '平静'),
  MoodOption(key: 'sad', emoji: '😢', label: '难过'),
  MoodOption(key: 'angry', emoji: '😤', label: '生气'),
  MoodOption(key: 'thinking', emoji: '🤔', label: '思考'),
];

/// 根据 key 获取心情 emoji
String getMoodEmoji(String? key) {
  if (key == null) return '📝';
  return moodOptions
      .where((m) => m.key == key)
      .map((m) => m.emoji)
      .firstOrNull ?? '📝';
}

/// 根据 key 获取心情标签
String getMoodLabel(String? key) {
  if (key == null) return '未选择';
  return moodOptions
      .where((m) => m.key == key)
      .map((m) => m.label)
      .firstOrNull ?? '未选择';
}

// =============================================================================
// 预设标签
// =============================================================================

const List<String> presetTags = [
  '学习',
  '健身',
  '情绪',
  '反思',
  '感恩',
  '目标',
  '阅读',
  '工作',
  '生活',
  '健康',
];

// =============================================================================
// 写作引导提示
// =============================================================================

class WritingPrompt {
  const WritingPrompt({
    required this.text,
    this.timeOfDay,
  });

  final String text;

  /// null = 全天可用, 'morning' = 早上, 'evening' = 晚上
  final String? timeOfDay;
}

const List<WritingPrompt> writingPrompts = [
  // ── 通用反思 ──
  WritingPrompt(text: '今天学到什么新东西了？'),
  WritingPrompt(text: '今天最让你自豪的一件事是什么？'),
  WritingPrompt(text: '如果重来一次，今天有什么可以做得更好的？'),
  WritingPrompt(text: '今天有没有什么让你意外的事？'),
  WritingPrompt(text: '用三个词形容今天的自己。'),
  WritingPrompt(text: '今天你帮助了谁？谁帮助了你？'),

  // ── 早间意图 ──
  WritingPrompt(text: '今天想专注完成什么？', timeOfDay: 'morning'),
  WritingPrompt(text: '今天想成为什么样的人？', timeOfDay: 'morning'),
  WritingPrompt(text: '今天最期待的是什么？', timeOfDay: 'morning'),
  WritingPrompt(text: '今天想对谁说声谢谢？', timeOfDay: 'morning'),

  // ── 晚间反思 ──
  WritingPrompt(text: '今天最感恩的三件事是什么？', timeOfDay: 'evening'),
  WritingPrompt(text: '今天身体感觉怎么样？', timeOfDay: 'evening'),
  WritingPrompt(text: '明天醒来，你希望第一件事是什么？', timeOfDay: 'evening'),
  WritingPrompt(text: '今天有没有什么想放下？', timeOfDay: 'evening'),

  // ── 成长相关 ──
  WritingPrompt(text: '看看你的学习数据，有什么新发现？'),
  WritingPrompt(text: '和上周的自己比，有什么变化？'),
  WritingPrompt(text: '你的身体在告诉你什么？'),
  WritingPrompt(text: '如果成长是一个故事，今天的章节叫什么？'),
  WritingPrompt(text: '写一封信给一年后的自己。'),
  WritingPrompt(text: '今天的一个小习惯，一年后会带来什么？'),
];

/// 获取当前时段的写作引导
WritingPrompt getRandomPrompt() {
  final hour = DateTime.now().hour;
  String? timeOfDay;
  if (hour >= 5 && hour < 12) {
    timeOfDay = 'morning';
  } else if (hour >= 18 && hour < 24) {
    timeOfDay = 'evening';
  }

  // 优先选择匹配时段的提示
  final timeMatched =
      writingPrompts.where((p) => p.timeOfDay == timeOfDay).toList();
  final general = writingPrompts.where((p) => p.timeOfDay == null).toList();

  final pool = [...timeMatched, ...general];
  return pool[DateTime.now().millisecondsSinceEpoch % pool.length];
}
