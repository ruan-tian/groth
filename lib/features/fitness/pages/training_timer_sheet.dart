import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';

/// 训练计时器底部弹窗
///
/// 选择训练部位 → 开始计时 → 结束后跳转到记录页面
class TrainingTimerSheet extends ConsumerStatefulWidget {
  const TrainingTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TrainingTimerSheet(),
    );
  }

  @override
  ConsumerState<TrainingTimerSheet> createState() => _TrainingTimerSheetState();
}

class _TrainingTimerSheetState extends ConsumerState<TrainingTimerSheet> {
  String? _selectedBodyPart;
  bool _isRunning = false;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  static const _bodyParts = [
    _BodyPartOption('胸', '💪', Color(0xFFFF6B6B)),
    _BodyPartOption('背', '🏋️', Color(0xFF5D68F2)),
    _BodyPartOption('腿', '🦵', Color(0xFF35C976)),
    _BodyPartOption('肩', '💎', Color(0xFFFFB347)),
    _BodyPartOption('手臂', '💪', Color(0xFFFF6B9D)),
    _BodyPartOption('核心', '🎯', Color(0xFF9B59B6)),
    _BodyPartOption('全身', '⚡', Color(0xFFD4A574)),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectBodyPart(String part) {
    if (_isRunning) return;
    setState(() {
      _selectedBodyPart = part;
    });
  }

  void _startTimer() {
    if (_selectedBodyPart == null) return;
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    // Navigate to add record page with pre-filled data
    final minutes = _elapsed.inMinutes > 0 ? _elapsed.inMinutes : 1;
    Navigator.pop(context);
    context.push(
      '/plan/fitness/add?mode=simple'
      '&bodyPart=${Uri.encodeComponent(_selectedBodyPart!)}'
      '&duration=$minutes',
    );
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsed = Duration.zero;
      _selectedBodyPart = null;
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.growthColors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.growthColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 标题
          Text(
            _isRunning ? '训练中...' : '选择训练部位',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.growthColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // 部位选择器
          if (!_isRunning) _buildBodyPartSelector(),
          if (_isRunning) _buildRunningTimer(),

          const SizedBox(height: 24),

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBodyPartSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _bodyParts.map((part) {
        final isSelected = _selectedBodyPart == part.name;
        return GestureDetector(
          onTap: () => _selectBodyPart(part.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? part.color.withValues(alpha: 0.15)
                  : context.growthColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? part.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(part.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  part.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? part.color
                        : context.growthColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRunningTimer() {
    final part = _bodyParts.firstWhere(
      (p) => p.name == _selectedBodyPart,
      orElse: () => _bodyParts.first,
    );

    return Column(
      children: [
        // 选中的部位标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: part.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(part.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                part.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: part.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 计时器显示
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
          decoration: BoxDecoration(
            color: context.growthColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                _formatDuration(_elapsed),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: part.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '训练进行中',
                style: TextStyle(
                  fontSize: 14,
                  color: part.color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isRunning) {
      return Row(
        children: [
          // 重置按钮
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetTimer,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重置'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.growthColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: context.growthColors.border),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 结束训练按钮
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _stopTimer,
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('结束训练'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.growthColors.fitness,
                foregroundColor: context.growthColors.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // 取消按钮
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.growthColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: context.growthColors.border),
            ),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 16),
        // 开始计时按钮
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _selectedBodyPart != null ? _startTimer : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('开始计时'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.growthColors.fitness,
              foregroundColor: context.growthColors.textOnAccent,
              disabledBackgroundColor: context.growthColors.fitness.withValues(
                alpha: 0.4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyPartOption {
  final String name;
  final String emoji;
  final Color color;

  const _BodyPartOption(this.name, this.emoji, this.color);
}
