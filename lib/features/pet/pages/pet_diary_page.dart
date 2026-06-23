import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../models/pet_data.dart';
import '../providers/pet_diary_provider.dart';
import '../../../shared/providers/service_providers.dart';
import '../../../core/domain/pet/pet_diary_draft.dart';
import '../widgets/pet_diary_data_preview_sheet.dart';

class PetDiaryPage extends ConsumerStatefulWidget {
  const PetDiaryPage({super.key});

  @override
  ConsumerState<PetDiaryPage> createState() => _PetDiaryPageState();
}

class _PetDiaryPageState extends ConsumerState<PetDiaryPage> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final diaryAsync = ref.watch(todayPetDiaryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        title: const Text(
          '甜甜的小日记',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: diaryAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.journal)),
        error: (_, _) => _EmptyNotebook(
          title: '日记本暂时打不开',
          message: '可以稍后再回来，甜甜会把纸页铺平。',
          onGenerate: _showGeneratePreview,
          isGenerating: _isGenerating,
        ),
        data: (diary) {
          if (diary == null) {
            return _EmptyNotebook(
              title: '甜甜还在想今天写什么',
              message: '早上六点后会自动检查，也可以手动让甜甜写一篇。',
              onGenerate: _showGeneratePreview,
              isGenerating: _isGenerating,
            );
          }
          return _DiaryNotebookView(
            diary: diary,
            panels: _readPanels(diary),
            isGenerating: _isGenerating,
            onGenerate: _showGeneratePreview,
          );
        },
      ),
    );
  }

  Future<void> _showGeneratePreview() async {
    final service = ref.read(petDiaryServiceProvider);
    final summary = await service.buildTodaySummary();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return PetDiaryDataPreviewSheet(
          summary: summary,
          isLoading: _isGenerating,
          onConfirm: () async {
            Navigator.pop(sheetContext);
            await _generateDiary();
          },
        );
      },
    );
  }

  Future<void> _generateDiary() async {
    setState(() => _isGenerating = true);
    try {
      final service = ref.read(petDiaryServiceProvider);
      await service.markPrivacyConfirmed();
      final diary = await service.ensureTodayDiary(manual: true, force: true);
      ref.invalidate(todayPetDiaryProvider);
      ref.invalidate(recentPetDiariesProvider);
      if (!mounted) return;
      final message = diary?.generationStatus == 'ready'
          ? '甜甜写好今天的小日记了'
          : '还没有可用的 AI 配置，先保留为待书写';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  List<PetDiaryPanel> _readPanels(PetDiary diary) {
    try {
      final raw = jsonDecode(diary.comicPanelsJson);
      if (raw is List) {
        final panels = raw
            .whereType<Map>()
            .map((e) => PetDiaryPanel.fromJson(Map<String, dynamic>.from(e)))
            .take(3)
            .toList();
        if (panels.length == 3) return panels;
      }
    } catch (_) {
      // Fall through to defaults.
    }
    return const [
      PetDiaryPanel(caption: '翻开日记本', bubble: '甜甜准备记录啦'),
      PetDiaryPanel(caption: '昨日小观察', bubble: '努力都被看见了'),
      PetDiaryPanel(caption: '今天的小爪印', bubble: '慢慢来就很好'),
    ];
  }
}

class _DiaryNotebookView extends StatelessWidget {
  const _DiaryNotebookView({
    required this.diary,
    required this.panels,
    required this.isGenerating,
    required this.onGenerate,
  });

  final PetDiary diary;
  final List<PetDiaryPanel> panels;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final status = diary.generationStatus;
    final ready = status == 'ready';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.softPink,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.journal.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: CustomPaint(
                painter: _GridPaperPainter(colors.journal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DiaryHeader(diary: diary),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 620;
                        return Flex(
                          direction: wide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: panels
                              .asMap()
                              .entries
                              .map(
                                (entry) => _ComicPanelCard(
                                  index: entry.key,
                                  panel: entry.value,
                                  wide: wide,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _DiaryPaper(
                      markdown: ready
                          ? diary.contentMarkdown
                          : _pendingCopy(status),
                    ),
                    const SizedBox(height: 18),
                    _ClosingBar(
                      status: status,
                      isGenerating: isGenerating,
                      onGenerate: onGenerate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pendingCopy(String status) {
    if (status == 'failed') {
      return '甜甜刚才没能写成功，可能是 AI 配置或网络暂时不可用。\n\n> 摘要仍然只保存在本地，可以稍后再试一次。';
    }
    return '甜甜还在想今天写什么。\n\n> 手动确认后，我只会使用昨天的统计摘要来写。';
  }
}

class _DiaryHeader extends StatelessWidget {
  const _DiaryHeader({required this.diary});

  final PetDiary diary;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final mood = _moodLabel(diary.mood);
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colors.softPink,
            shape: BoxShape.circle,
            border: Border.all(color: colors.card, width: 3),
          ),
          child: Icon(Icons.pets_rounded, color: colors.journal, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                diary.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                diary.diaryDate,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _Sticker(label: mood),
      ],
    );
  }

  String _moodLabel(String mood) {
    return switch (mood) {
      'happy' => '开心',
      'sleepy' => '困困',
      'proud' => '骄傲',
      'worried' => '担心',
      _ => '暖暖',
    };
  }
}

class _ComicPanelCard extends StatelessWidget {
  const _ComicPanelCard({
    required this.index,
    required this.panel,
    required this.wide,
  });

  final int index;
  final PetDiaryPanel panel;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final card = Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              [
                Icons.wb_sunny_rounded,
                Icons.favorite_rounded,
                Icons.star_rounded,
              ][index],
              size: 38,
              color: colors.journal.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '第 ${index + 1} 格',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.journal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                panel.caption,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.softPink.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  panel.bubble,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (wide) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
          child: card,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
      child: card,
    );
  }
}

class _DiaryPaper extends StatelessWidget {
  const _DiaryPaper({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LinePaperPainter(colors.journal)),
          ),
          MarkdownBody(
            data: markdown,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                height: 1.9,
                color: colors.textPrimary,
              ),
              blockquote: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.journal,
              ),
              blockquoteDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  left: BorderSide(color: colors.journal, width: 3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingBar extends StatelessWidget {
  const _ClosingBar({
    required this.status,
    required this.isGenerating,
    required this.onGenerate,
  });

  final String status;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final ready = status == 'ready';
    return Row(
      children: [
        Expanded(
          child: Text(
            ready ? '今日小鼓励已经夹在纸页里了。' : '甜甜需要你的确认，才会带着摘要去写。',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: isGenerating ? null : onGenerate,
          style: FilledButton.styleFrom(
            backgroundColor: colors.journal,
            foregroundColor: colors.textOnAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: isGenerating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.textOnAccent,
                  ),
                )
              : const Icon(Icons.auto_awesome_rounded, size: 17),
          label: Text(ready ? '重新生成' : '让甜甜写'),
        ),
      ],
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.softGold,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.warning,
          ),
        ),
      ),
    );
  }
}

class _EmptyNotebook extends StatelessWidget {
  const _EmptyNotebook({
    required this.title,
    required this.message,
    required this.onGenerate,
    required this.isGenerating,
  });

  final String title;
  final String message;
  final VoidCallback onGenerate;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 160,
              decoration: BoxDecoration(
                color: colors.softPink,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.journal.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 54,
                color: colors.journal,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isGenerating ? null : onGenerate,
              style: FilledButton.styleFrom(
                backgroundColor: colors.journal,
                foregroundColor: colors.textOnAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(isGenerating ? '书写中' : '让甜甜写今天的日记'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter(this.lineColor);

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinePaperPainter extends CustomPainter {
  const _LinePaperPainter(this.lineColor);

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.24)
      ..strokeWidth = 1;
    for (double y = 28; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
