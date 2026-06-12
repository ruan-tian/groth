part of '../pages/quill_editor_page.dart';

class _TitleSection extends StatelessWidget {
  const _TitleSection({
    required this.titleController,
    required this.dateStr,
    required this.wordCount,
  });

  final TextEditingController titleController;
  final String dateStr;
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 14, 30, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 4, color: JournalColors.pinkMain),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                    style: const TextStyle(
                      color: JournalColors.pinkMain,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    decoration: const InputDecoration(
                      hintText: '标题',
                      hintStyle: TextStyle(color: JournalColors.pinkSoft),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$dateStr  ·  $wordCount字',
            style: const TextStyle(
              color: JournalColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
