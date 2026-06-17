import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

class KnowledgeSourceRechunkDraft {
  const KnowledgeSourceRechunkDraft({required this.content});

  final String content;
}

class KnowledgeSourceRechunkSheet extends StatefulWidget {
  const KnowledgeSourceRechunkSheet({
    super.key,
    required this.sourceTitle,
    required this.initialContent,
  });

  final String sourceTitle;
  final String initialContent;

  static Future<KnowledgeSourceRechunkDraft?> show({
    required BuildContext context,
    required String sourceTitle,
    required String initialContent,
  }) {
    return showModalBottomSheet<KnowledgeSourceRechunkDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KnowledgeSourceRechunkSheet(
        sourceTitle: sourceTitle,
        initialContent: initialContent,
      ),
    );
  }

  @override
  State<KnowledgeSourceRechunkSheet> createState() =>
      _KnowledgeSourceRechunkSheetState();
}

class _KnowledgeSourceRechunkSheetState
    extends State<KnowledgeSourceRechunkSheet> {
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '编辑原文并重切片',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.sourceTitle,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '保存后会重新生成这份资料的本地切片，方便后续检索和 AI 继续沉淀。',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('knowledge-source-rechunk-content-field'),
              controller: _contentController,
              minLines: 14,
              maxLines: 22,
              decoration: const InputDecoration(
                labelText: '资料原文',
                alignLabelWithHint: true,
                hintText: '粘贴修订后的资料内容，系统会重新本地切片。',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('knowledge-source-rechunk-save-button'),
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.study,
                foregroundColor: colors.textOnAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('保存并重切片'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('资料原文不能为空')));
      return;
    }
    Navigator.of(context).pop(KnowledgeSourceRechunkDraft(content: content));
  }
}
