part of '../pages/quill_editor_page.dart';

// ---------------------------------------------------------------------------
// Link insertion dialog
// ---------------------------------------------------------------------------

class _QuillLinkDialog extends StatelessWidget {
  const _QuillLinkDialog({required this.onConfirm});

  final void Function(String text, String url) onConfirm;

  @override
  Widget build(BuildContext context) {
    final textCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    return AlertDialog(
      title: const Text('插入链接'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: textCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: '链接文字'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: urlCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final text = textCtrl.text.trim();
            final url = urlCtrl.text.trim();
            if (text.isNotEmpty && url.isNotEmpty) {
              onConfirm(text, url);
            }
            Navigator.pop(context);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// Convenience method to show the dialog.
  static void show(
    BuildContext context, {
    required void Function(String text, String url) onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _QuillLinkDialog(onConfirm: onConfirm),
    );
  }
}
