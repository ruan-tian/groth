import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class InspirationEntry {
  const InspirationEntry({
    required this.text,
    required this.source,
    required this.theme,
    required this.kind,
  });

  final String text;
  final String source;
  final String theme;
  final InspirationKind kind;
}

class InspirationTheme {
  const InspirationTheme({
    required this.name,
    required this.subtitle,
    required this.posterPath,
    required this.kind,
    required this.entries,
  });

  final String name;
  final String subtitle;
  final String posterPath;
  final InspirationKind kind;
  final List<InspirationEntry> entries;
}

enum InspirationKind { poem, quote }

class InspirationCatalog {
  const InspirationCatalog({required this.themes});

  final List<InspirationTheme> themes;

  static const _posterRoot = 'assets/images/inspiration';
  static InspirationCatalog? _cachedCatalog;
  static Future<InspirationCatalog>? _loading;

  List<InspirationEntry> get entries =>
      themes.expand((theme) => theme.entries).toList(growable: false);

  static Future<InspirationCatalog> load() {
    final cached = _cachedCatalog;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load();
  }

  static Future<InspirationCatalog> _load() async {
    final poems = await _loadUtf8('assets/data/inspiration/poems.txt');
    final quotes = await _loadUtf8('assets/data/inspiration/quotes.txt');
    final themes = [..._parsePoems(poems), ..._parseQuotes(quotes)]
      ..sort((a, b) {
        final order = _themeOrder(a.name).compareTo(_themeOrder(b.name));
        if (order != 0) return order;
        return a.name.compareTo(b.name);
      });

    final catalog = InspirationCatalog(themes: themes);
    _cachedCatalog = catalog;
    _loading = null;
    return catalog;
  }

  static Future<String> _loadUtf8(String path) async {
    final data = await rootBundle.load(path);
    return utf8.decode(data.buffer.asUint8List());
  }

  static List<InspirationTheme> _parsePoems(String text) {
    final header = RegExp(r'^[一二三四五六七八九十]+、([^：:]+)[：:](.+)$');
    return _parseSections(
      text: text,
      kind: InspirationKind.poem,
      isHeader: (line) => header.hasMatch(line),
      parseHeader: (line) {
        final match = header.firstMatch(line)!;
        return (match.group(1)!.trim(), match.group(2)!.trim());
      },
    );
  }

  static List<InspirationTheme> _parseQuotes(String text) {
    final header = RegExp(r'^第\d+类[：:](.+)$');
    return _parseSections(
      text: text,
      kind: InspirationKind.quote,
      isHeader: (line) => header.hasMatch(line),
      parseHeader: (line) {
        final raw = header.firstMatch(line)!.group(1)!.trim();
        final parts = raw.split('——');
        return (
          parts.first.trim(),
          parts.length > 1 ? parts.sublist(1).join('——').trim() : '',
        );
      },
    );
  }

  static List<InspirationTheme> _parseSections({
    required String text,
    required InspirationKind kind,
    required bool Function(String line) isHeader,
    required (String, String) Function(String line) parseHeader,
  }) {
    final themes = <InspirationTheme>[];
    String? currentName;
    String currentSubtitle = '';
    final entries = <InspirationEntry>[];

    void flush() {
      if (currentName == null || entries.isEmpty) return;
      final name = currentName;
      themes.add(
        InspirationTheme(
          name: name,
          subtitle: currentSubtitle,
          posterPath: posterForTheme(name),
          kind: kind,
          entries: List.unmodifiable(entries),
        ),
      );
      entries.clear();
    }

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (isHeader(line)) {
        flush();
        final parsed = parseHeader(line);
        currentName = parsed.$1;
        currentSubtitle = parsed.$2;
        continue;
      }

      if (currentName == null) continue;
      final parsed = _parseEntry(line);
      entries.add(
        InspirationEntry(
          text: parsed.$1,
          source: parsed.$2,
          theme: currentName,
          kind: kind,
        ),
      );
    }
    flush();

    return themes;
  }

  static (String, String) _parseEntry(String line) {
    final parts = line.split(RegExp(r'\s+——\s+'));
    if (parts.length < 2) return (line, '');
    return (parts.first.trim(), parts.sublist(1).join(' —— ').trim());
  }

  static String posterForTheme(String theme) {
    final posterName = switch (theme) {
      '内心力量' => '成长与蜕变',
      _ => theme,
    };
    return '$_posterRoot/$posterName.webp';
  }

  static InspirationEntry pickDailyEntry(List<InspirationEntry> entries) {
    if (entries.isEmpty) {
      throw StateError('Inspiration catalog has no entries.');
    }
    final now = DateTime.now();
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(2026)).inDays.abs();
    return entries[day % entries.length];
  }

  static InspirationEntry randomEntry(
    List<InspirationEntry> entries, {
    InspirationEntry? except,
    Random? random,
  }) {
    if (entries.isEmpty) {
      throw StateError('Inspiration catalog has no entries.');
    }
    if (entries.length == 1) return entries.first;

    final rng = random ?? Random();
    InspirationEntry next;
    do {
      next = entries[rng.nextInt(entries.length)];
    } while (except != null && next.text == except.text);
    return next;
  }

  static int _themeOrder(String theme) {
    const order = [
      '自我接纳',
      '开导豁达',
      '孤独与陪伴',
      '未来与希望',
      '成长与蜕变',
      '行动与坚持',
      '励志向上',
      '人生哲理',
      '幸福瞬间',
      '生活美学',
      '人际关系边界',
      '幽默豁达',
      '书韵飘香',
      '山水之乐',
      '年少轻狂',
      '警世',
    ];
    final index = order.indexOf(theme);
    return index == -1 ? 999 : index;
  }
}
