import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/design/design.dart';

/// Growth OS 删除确认弹窗
///
/// 专门用于删除操作的确认弹窗，使用甜甜图片作为温馨提醒。
/// 设计风格：高级感 + 危险感 + 甜甜的温馨提醒
///
/// 使用方式：
/// ```dart
/// final confirmed = await DeleteConfirmDialog.show(
///   context: context,
///   title: '删除记录',
///   message: '删除后数据无法恢复',
///   tiantianMessage: '甜甜会帮你记住这段成长～',
/// );
/// ```
class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '删除',
    this.tiantianMessage,
  });

  /// 标题
  final String title;

  /// 描述内容
  final String message;

  /// 确认按钮文字
  final String confirmText;

  /// 甜甜的温馨提醒（可选）
  final String? tiantianMessage;

  /// 便捷方法：显示删除确认弹窗
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '删除',
    String? tiantianMessage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => DeleteConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        tiantianMessage: tiantianMessage,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 48,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(color: colors.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 甜甜图片
              _buildTiantianImage(colors),
              const SizedBox(height: 20),
              // 标题
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              // 描述
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              // 甜甜温馨提醒
              if (tiantianMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  tiantianMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textTertiary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // 警告卡片
              _buildWarningCard(colors),
              const SizedBox(height: 24),
              // 按钮
              _buildButtons(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建甜甜图片
  Widget _buildTiantianImage(AppThemeColors colors) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 柔和光晕背景
          Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.danger.withValues(alpha: 0.06),
            ),
          ),
          // 甜甜图片
          Image.asset(
            'assets/images/dialogs/common_warning.webp',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建警告卡片
  Widget _buildWarningCard(AppThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.warning.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '此操作不可撤销',
              style: TextStyle(
                fontSize: 12,
                color: colors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建按钮
  Widget _buildButtons(BuildContext context, AppThemeColors colors) {
    return Row(
      children: [
        // 取消按钮
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.border, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 删除按钮
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: colors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
