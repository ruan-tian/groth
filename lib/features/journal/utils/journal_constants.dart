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
  MoodOption(key: 'calm', emoji: '☺️', label: '平静'),
  MoodOption(key: 'neutral', emoji: '😐', label: '一般'),
  MoodOption(key: 'sad', emoji: '😢', label: '难过'),
  MoodOption(key: 'great', emoji: '😎', label: '超棒'),
];

String getMoodEmoji(String? key) {
  if (key == null) return '📓';
  return moodOptions
          .where((mood) => mood.key == key)
          .map((mood) => mood.emoji)
          .firstOrNull ??
      '📓';
}

String getMoodLabel(String? key) {
  if (key == null) return '未选择';
  return moodOptions
          .where((mood) => mood.key == key)
          .map((mood) => mood.label)
          .firstOrNull ??
      '未选择';
}

const List<String> presetTags = [
  '学习',
  '健身',
  '情绪',
  '复盘',
  '感恩',
  '目标',
  '阅读',
  '工作',
  '生活',
  '健康',
];

class WritingPrompt {
  const WritingPrompt({required this.text, this.timeOfDay});

  final String text;
  final String? timeOfDay;
}

const List<WritingPrompt> writingPrompts = [
  WritingPrompt(text: '今天最值得记录的小确幸是什么？'),
  WritingPrompt(text: '今天学到了什么新东西？'),
  WritingPrompt(text: '今天让你感到放松的一刻是什么？'),
  WritingPrompt(text: '如果重来一次，今天哪里可以做得更好？'),
  WritingPrompt(text: '用三个词形容今天的自己。'),
  WritingPrompt(text: '今天你想感谢谁，或者感谢什么？'),
  WritingPrompt(text: '今天想专注完成什么？', timeOfDay: 'morning'),
  WritingPrompt(text: '今天想成为一个怎样的人？', timeOfDay: 'morning'),
  WritingPrompt(text: '今天最期待的事情是什么？', timeOfDay: 'morning'),
  WritingPrompt(text: '今天最感恩的三件事是什么？', timeOfDay: 'evening'),
  WritingPrompt(text: '今天身体和情绪分别在告诉你什么？', timeOfDay: 'evening'),
  WritingPrompt(text: '明天醒来后，第一件想做好的事是什么？', timeOfDay: 'evening'),
  WritingPrompt(text: '和上周的自己相比，今天有什么变化？'),
  WritingPrompt(text: '如果成长是一段故事，今天这一章叫什么？'),
  WritingPrompt(text: '写一封短信给一年后的自己。'),
];

WritingPrompt getRandomPrompt() {
  final hour = DateTime.now().hour;
  String? timeOfDay;
  if (hour >= 5 && hour < 12) {
    timeOfDay = 'morning';
  } else if (hour >= 18 && hour < 24) {
    timeOfDay = 'evening';
  }

  final timeMatched = writingPrompts
      .where((prompt) => prompt.timeOfDay == timeOfDay)
      .toList();
  final general = writingPrompts
      .where((prompt) => prompt.timeOfDay == null)
      .toList();
  final pool = [...timeMatched, ...general];
  return pool[DateTime.now().millisecondsSinceEpoch % pool.length];
}
