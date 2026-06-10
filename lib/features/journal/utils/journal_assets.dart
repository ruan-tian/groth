class JournalAssets {
  JournalAssets._();

  static const _root = 'assets/images/journal';

  static const todayBackground = '$_root/backgrounds/journal_today_bg.webp';
  static const writingBanner = '$_root/backgrounds/journal_banner_writing.webp';

  static const catWriting = '$_root/cats/journal_cat_writing.webp';
  static const catThinking = '$_root/cats/journal_cat_thinking.webp';
  static const catBook = '$_root/cats/journal_cat_book.webp';

  static const pencil = '$_root/decor/journal_pencil.png';
  static const notebook = '$_root/decor/journal_notebook.png';
  static const openBook = '$_root/decor/journal_open_book.png';

  static const empty = '$_root/status/journal_empty.webp';

  static const all = <String>[
    todayBackground,
    writingBanner,
    catWriting,
    catThinking,
    catBook,
    pencil,
    notebook,
    openBook,
    empty,
  ];
}
