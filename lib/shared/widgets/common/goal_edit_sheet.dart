import 'package:flutter/material.dart';

import '../../../app/design/app_colors.dart';
import '../../../app/design/app_text_styles.dart';

/// Growth OS 统一目标编辑弹窗
///
/// 可复用的目标设置组件，支持：
/// - 数值增减（带步长）
/// - 单位显示
/// - 建议范围提示
/// - 保存回调
class GoalEditSheet extends StatefulWidget {
  const GoalEditSheet({
    super.key,
    required this.title,
    required this.currentValue,
    required this.unit,
    this.min = 1,
    this.max = 999,
    this.step = 1,
    this.suggestion,
    required this.color,
    required this.onSave,
  });

  final String title;
  final int currentValue;
  final String unit;
  final int min;
  final int max;
  final int step;
  final String? suggestion;
  final Color color;
  final ValueChanged<int> onSave;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required int currentValue,
    required String unit,
    int min = 1,
    int max = 999,
    int step = 1,
    String? suggestion,
    required Color color,
    required ValueChanged<int> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalEditSheet(
        title: title,
        currentValue: currentValue,
        unit: unit,
        min: min,
        max: max,
        step: step,
        suggestion: suggestion,
        color: color,
        onSave: onSave,
      ),
    );
  }

  @override
  State<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<GoalEditSheet> {
  late int _tempValue;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 标题
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2329),
            ),
          ),
          const SizedBox(height: 24),

          // 数值调节器
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _tempValue > widget.min
                    ? () => setState(() => _tempValue -= widget.step)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 32),
                color: widget.color,
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    '$_tempValue',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _tempValue < widget.max
                    ? () => setState(() => _tempValue += widget.step)
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 32),
                color: widget.color,
              ),
            ],
          ),

          // 建议
          if (widget.suggestion != null) ...[
            const SizedBox(height: 8),
            Text(widget.suggestion!, style: AppTextStyles.caption),
          ],

          const SizedBox(height: 24),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_tempValue);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
