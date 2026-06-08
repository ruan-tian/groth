import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/pet_diary_provider.dart';
import '../../../shared/providers/service_providers.dart';
import 'pet_diary_data_preview_sheet.dart';

class PetJournalSection extends ConsumerStatefulWidget {
  const PetJournalSection({super.key});

  @override
  ConsumerState<PetJournalSection> createState() => _PetJournalSectionState();
}

class _PetJournalSectionState extends ConsumerState<PetJournalSection> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final diaryAsync = ref.watch(todayPetDiaryProvider);

    return diaryAsync.when(
      loading: () => const _DiaryNotebookCard.loading(),
      error: (_, _) => _DiaryNotebookCard(
        title: '甜甜的小日记',
        subtitle: '日记本暂时打不开',
        status: 'failed',
        onOpen: () => context.push('/pet-diary'),
        onGenerate: _isGenerating ? null : _showGeneratePreview,
        isGenerating: _isGenerating,
      ),
      data: (diary) {
        final status = diary?.generationStatus ?? 'pending';
        final ready = status == 'ready';
        final readyDiary = ready ? diary! : null;
        return _DiaryNotebookCard(
          title: ready ? readyDiary!.title : '甜甜的小日记',
          subtitle: ready
              ? _previewText(readyDiary!.contentMarkdown)
              : '甜甜还在想今天写什么，确认后只用摘要来写。',
          status: status,
          onOpen: () => context.push('/pet-diary'),
          onGenerate: _isGenerating ? null : _showGeneratePreview,
          isGenerating: _isGenerating,
        );
      },
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
          : '还没有可用的 AI 配置，先放进待书写日记本';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.push('/pet-diary');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _previewText(String markdown) {
    return markdown
        .replaceAll(RegExp(r'[#>*_`\-\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _DiaryNotebookCard extends StatelessWidget {
  const _DiaryNotebookCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onOpen,
    required this.onGenerate,
    required this.isGenerating,
  });

  const _DiaryNotebookCard.loading()
    : title = '甜甜的小日记',
      subtitle = '正在翻开今天的日记本',
      status = 'loading',
      onOpen = null,
      onGenerate = null,
      isGenerating = true;

  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onOpen;
  final VoidCallback? onGenerate;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final ready = status == 'ready';
    final failed = status == 'failed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '甜甜的小日记',
            style: AppTextStyles.sectionTitle.copyWith(
              color: const Color(0xFF6E4A58),
            ),
          ),
        ),
        GestureDetector(
          onTap: onOpen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF5FA),
                  Color(0xFFFFE2EF),
                  Color(0xFFFFF9F1),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1C2D8)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE889B5).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NotebookCover(ready: ready, failed: failed),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6E4A58),
                              ),
                            ),
                          ),
                          _StatusPill(status: status),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF8E6D78),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onOpen,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD8709B),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 17),
                            label: const Text('打开日记本'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: onGenerate,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE889B5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: isGenerating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(ready ? '重新生成' : '让甜甜写'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotebookCover extends StatelessWidget {
  const _NotebookCover({required this.ready, required this.failed});

  final bool ready;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFFFBCD8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8709B).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Container(
              width: 7,
              color: const Color(0xFFDD7BA5).withValues(alpha: 0.45),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Icon(
              failed
                  ? Icons.cloud_off_rounded
                  : ready
                  ? Icons.favorite_rounded
                  : Icons.edit_note_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE889B5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'ready' => '已写好',
      'failed' => '待重试',
      'loading' => '翻页中',
      _ => '待书写',
    };
    final color = switch (status) {
      'ready' => const Color(0xFF42A576),
      'failed' => const Color(0xFFE07A63),
      'loading' => const Color(0xFF8E7EDC),
      _ => const Color(0xFFD8709B),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
