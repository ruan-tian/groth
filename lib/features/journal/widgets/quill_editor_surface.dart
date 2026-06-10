part of '../pages/quill_editor_page.dart';

// ---------------------------------------------------------------------------
// Paper editor surface with line background and mascot overlay
// ---------------------------------------------------------------------------

class _PaperEditorSurface extends StatelessWidget {
  const _PaperEditorSurface({
    required this.controller,
    required this.scrollController,
    required this.focusNode,
  });

  final QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(26, 0, 26, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JournalColors.pinkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _EditorLinesPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              child: QuillEditor(
                controller: controller,
                scrollController: scrollController,
                focusNode: focusNode,
                config: const QuillEditorConfig(
                  placeholder: '开始书写吧...',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: IgnorePointer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: JournalColors.pinkBorder),
                      ),
                      child: const Text(
                        '甜甜陪你\n记录每一天~',
                        style: TextStyle(
                          color: JournalColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset(
                      journal_images.JournalAssets.catWriting,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal line painter for paper effect
// ---------------------------------------------------------------------------

class _EditorLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JournalColors.pinkBorder.withValues(alpha: 0.52)
      ..strokeWidth = 1;
    for (var y = 52.0; y < size.height - 20; y += 48) {
      canvas.drawLine(Offset(22, y), Offset(size.width - 22, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
