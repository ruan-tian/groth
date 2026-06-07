import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';

// =============================================================================
// Encouragement message pools
// =============================================================================

const _generalMessages = <String>[
  '今天也要加油哦！',
  '你已经很棒了～',
  '一步一步来，不着急',
  '甜甜一直在这里陪着你',
  '休息也很重要哦',
  '你比你想象的更厉害',
  '每天进步一点点就够了',
  '累了就休息一下吧',
];

const _studyMessages = <String>[
  '学习辛苦啦，喝口水休息一下',
  '专注的你最帅了！',
  '知识是一点一点积累的',
  '今天学了新东西吧？好厉害',
];

const _fitnessMessages = <String>[
  '运动完记得拉伸哦',
  '你流的每一滴汗都有意义',
  '坚持运动的你超酷的',
  '今天也要元气满满',
];

const _journalMessages = <String>[
  '写日记是和自己对话的好方式',
  '记录下来就不会忘记了',
  '你的文字很有温度',
];

const _sleepMessages = <String>[
  '早点睡觉，明天会更好',
  '晚安，甜甜会守护你的梦',
  '好好休息，明天继续加油',
];

/// All messages combined into one pool.
const _allMessages = <String>[
  ..._generalMessages,
  ..._studyMessages,
  ..._fitnessMessages,
  ..._journalMessages,
  ..._sleepMessages,
];

// =============================================================================
// PetJournalSection
// =============================================================================

/// A section that displays random encouraging messages from 甜甜.
///
/// Shown below the today's growth card on the pet center page.
/// Each build randomly selects 3 messages from the full encouragement pool.
class PetJournalSection extends ConsumerStatefulWidget {
  const PetJournalSection({super.key});

  @override
  ConsumerState<PetJournalSection> createState() => _PetJournalSectionState();
}

class _PetJournalSectionState extends ConsumerState<PetJournalSection> {
  late List<String> _selectedMessages;

  @override
  void initState() {
    super.initState();
    _selectedMessages = _pickRandomMessages(count: 3);
  }

  /// Randomly shuffles the pool and picks [count] messages.
  List<String> _pickRandomMessages({required int count}) {
    final rng = Random();
    final shuffled = List<String>.from(_allMessages)..shuffle(rng);
    return shuffled.take(count).toList();
  }

  /// Refreshes the displayed messages with a new random selection.
  void _refreshMessages() {
    setState(() {
      _selectedMessages = _pickRandomMessages(count: 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '💬 甜甜的悄悄话',
            style: AppTextStyles.sectionTitle.copyWith(
              color: const Color(0xFF5D4E37),
            ),
          ),
        ),

        // ── Message cards ──
        ..._selectedMessages.map(
          (msg) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MessageCard(message: msg),
          ),
        ),

        // ── "查看更多" link ──
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _refreshMessages,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '查看更多',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF5D4E37).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _MessageCard
// =============================================================================

/// A single warm-toned message card with a cat emoji prefix.
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🐱 ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5D4E37),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
