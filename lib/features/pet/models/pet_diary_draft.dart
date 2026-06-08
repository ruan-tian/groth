class PetDiaryPanel {
  const PetDiaryPanel({required this.caption, required this.bubble});

  final String caption;
  final String bubble;

  factory PetDiaryPanel.fromJson(Map<String, dynamic> json) {
    return PetDiaryPanel(
      caption: (json['caption'] as String?)?.trim().isNotEmpty == true
          ? (json['caption'] as String).trim()
          : '甜甜观察中',
      bubble: (json['bubble'] as String?)?.trim().isNotEmpty == true
          ? (json['bubble'] as String).trim()
          : '今天也要慢慢来呀',
    );
  }

  Map<String, dynamic> toJson() => {'caption': caption, 'bubble': bubble};
}

class PetDiaryDraft {
  const PetDiaryDraft({
    required this.title,
    required this.mood,
    required this.panels,
    required this.diary,
    required this.closing,
  });

  final String title;
  final String mood;
  final List<PetDiaryPanel> panels;
  final String diary;
  final String closing;

  factory PetDiaryDraft.fromJson(Map<String, dynamic> json) {
    final rawPanels = json['panels'];
    final panels = rawPanels is List
        ? rawPanels
              .whereType<Map>()
              .map((e) => PetDiaryPanel.fromJson(Map<String, dynamic>.from(e)))
              .take(3)
              .toList()
        : <PetDiaryPanel>[];

    return PetDiaryDraft(
      title: _trimText(json['title'], fallback: '甜甜的小日记', maxLength: 16),
      mood: _normalizeMood(json['mood']),
      panels: _completePanels(panels),
      diary: _trimText(
        json['diary'],
        fallback: '甜甜还在整理今天的小心情。',
        maxLength: 240,
      ),
      closing: _trimText(json['closing'], fallback: '今天也被甜甜看好。', maxLength: 28),
    );
  }

  String toMarkdown() {
    return '$diary\n\n> $closing';
  }

  static List<PetDiaryPanel> _completePanels(List<PetDiaryPanel> panels) {
    const defaults = [
      PetDiaryPanel(caption: '早安检查', bubble: '甜甜翻开了小本本'),
      PetDiaryPanel(caption: '昨日回想', bubble: '把努力都收进爪印里'),
      PetDiaryPanel(caption: '今日鼓励', bubble: '今天也一起轻轻前进'),
    ];

    final merged = <PetDiaryPanel>[...panels];
    for (var i = merged.length; i < 3; i++) {
      merged.add(defaults[i]);
    }
    return merged.take(3).toList();
  }

  static String _normalizeMood(Object? value) {
    const allowed = {'happy', 'sleepy', 'proud', 'worried', 'cozy'};
    final mood = value is String ? value.trim() : '';
    return allowed.contains(mood) ? mood : 'cozy';
  }

  static String _trimText(
    Object? value, {
    required String fallback,
    required int maxLength,
  }) {
    final text = value is String ? value.trim() : '';
    if (text.isEmpty) return fallback;
    return text.length <= maxLength ? text : text.substring(0, maxLength);
  }
}
