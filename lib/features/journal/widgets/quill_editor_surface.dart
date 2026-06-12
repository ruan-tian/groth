part of '../pages/quill_editor_page.dart';

class _PaperEditorSurface extends StatelessWidget {
  const _PaperEditorSurface({
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.compactMode,
    required this.keyboardBottom,
    required this.onTap,
  });

  final QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final bool compactMode;
  final double keyboardBottom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = MediaQuery.sizeOf(context).width < 390
        ? 16.0
        : 24.0;
    final bottomInset = keyboardBottom > 0 ? keyboardBottom + 104 : 120.0;

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: JournalColors.pinkBorder),
        boxShadow: [
          BoxShadow(
            color: JournalColors.pinkMain.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _EditorLinesPainter())),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, bottomInset),
                  child: QuillEditor(
                    controller: controller,
                    scrollController: scrollController,
                    focusNode: focusNode,
                    config: const QuillEditorConfig(
                      placeholder: '开始书写吧...',
                      padding: EdgeInsets.zero,
                      scrollPhysics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      embedBuilders: [JournalQuillImageEmbedBuilder()],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 104,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: compactMode ? 0 : 1,
                  duration: AppMotion.duration(context, AppMotion.normal),
                  curve: AppMotion.standard,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: JournalColors.pinkBorder),
                        ),
                        child: const Text(
                          '甜甜陪你\n记录每一天',
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
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JournalColors.pinkBorder.withValues(alpha: 0.46)
      ..strokeWidth = 1;
    for (var y = 52.0; y < size.height - 20; y += 48) {
      canvas.drawLine(Offset(22, y), Offset(size.width - 22, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
