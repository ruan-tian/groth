import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/knowledge_card_provider.dart';
import '../../../shared/widgets/common/common_widgets.dart';
import '../utils/knowledge_card_exporter.dart';

enum _ExportFormat { markdown, csv }

class KnowledgeExportPage extends ConsumerStatefulWidget {
  const KnowledgeExportPage({super.key});

  @override
  ConsumerState<KnowledgeExportPage> createState() =>
      _KnowledgeExportPageState();
}

class _KnowledgeExportPageState extends ConsumerState<KnowledgeExportPage> {
  var _format = _ExportFormat.markdown;
  var _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final activeCards = ref.watch(knowledgeCardsProvider);
    final archivedCards = ref.watch(archivedKnowledgeCardsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: Text(
          '导出知识卡',
          style: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        ),
        centerTitle: false,
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: ModulePageSurface(
        color: colors.study,
        child: activeCards.when(
          data: (active) {
            final archived =
                archivedCards.valueOrNull ?? const <KnowledgeCard>[];
            final cards = [...active, if (_includeArchived) ...archived];
            final content = _format == _ExportFormat.markdown
                ? KnowledgeCardExporter.toMarkdown(cards)
                : KnowledgeCardExporter.toCsv(cards);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ExportOptionsCard(
                  format: _format,
                  includeArchived: _includeArchived,
                  activeCount: active.length,
                  archivedCount: archived.length,
                  exportCount: cards.length,
                  onFormatChanged: (format) => setState(() => _format = format),
                  onIncludeArchivedChanged: (value) =>
                      setState(() => _includeArchived = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _ExportPreviewCard(content: content, onCopy: _copyExport),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CardSkeleton(height: 320),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ErrorRetryWidget(),
          ),
        ),
      ),
    );
  }

  Future<void> _copyExport(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _format == _ExportFormat.markdown ? 'Markdown 已复制' : 'CSV 已复制',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ExportOptionsCard extends StatelessWidget {
  const _ExportOptionsCard({
    required this.format,
    required this.includeArchived,
    required this.activeCount,
    required this.archivedCount,
    required this.exportCount,
    required this.onFormatChanged,
    required this.onIncludeArchivedChanged,
  });

  final _ExportFormat format;
  final bool includeArchived;
  final int activeCount;
  final int archivedCount;
  final int exportCount;
  final ValueChanged<_ExportFormat> onFormatChanged;
  final ValueChanged<bool> onIncludeArchivedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download_outlined, color: colors.study),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '本地导出',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$exportCount 张',
                style: TextStyle(
                  color: colors.study,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '导出内容只在本机生成，可以复制为 Markdown 笔记或 CSV 表格。',
            style: TextStyle(color: colors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<_ExportFormat>(
            segments: const [
              ButtonSegment(
                value: _ExportFormat.markdown,
                icon: Icon(Icons.notes_rounded),
                label: Text('Markdown'),
              ),
              ButtonSegment(
                value: _ExportFormat.csv,
                icon: Icon(Icons.table_chart_outlined),
                label: Text('CSV'),
              ),
            ],
            selected: {format},
            onSelectionChanged: (selected) => onFormatChanged(selected.single),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            value: includeArchived,
            onChanged: onIncludeArchivedChanged,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '包含归档卡',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '当前可复习 $activeCount 张，归档箱 $archivedCount 张',
              style: TextStyle(color: colors.textSecondary),
            ),
            activeThumbColor: colors.study,
          ),
        ],
      ),
    );
  }
}

class _ExportPreviewCard extends StatelessWidget {
  const _ExportPreviewCard({required this.content, required this.onCopy});

  final String content;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '导出预览',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => onCopy(content),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.study,
                  foregroundColor: colors.textOnAccent,
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('复制'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            constraints: const BoxConstraints(maxHeight: 520),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.mlg),
              border: Border.all(color: colors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: TextStyle(
                  color: colors.textPrimary,
                  height: 1.45,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
