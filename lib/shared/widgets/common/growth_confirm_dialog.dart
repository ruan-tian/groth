import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/design/design.dart';

typedef GrowthConfirmCallback = FutureOr<void> Function();

/// Growth OS 通用确认弹窗
///
/// 精致的居中弹窗，支持图片、标题、描述、隐私提示和双按钮。
/// 设计参考：项目内 _FocusIllustrationDialog + PetAIDataPreviewSheet 风格。
///
/// 使用方式：
/// ```dart
/// GrowthConfirmDialog.show(
///   context: context,
///   image: 'assets/images/dialogs/ai_privacy.webp',
///   title: '开启 AI 自动分析',
///   message: '开启后，每次打开 app 会自动分析你的学习、健身数据。',
///   privacyNotice: '数据将会发送到你配置的 AI 服务商服务器。',
///   primaryText: '确认开启',
///   onPrimary: () { /* 处理确认 */ },
/// );
/// ```
class GrowthConfirmDialog extends StatelessWidget {
  const GrowthConfirmDialog({
    super.key,
    required this.image,
    required this.title,
    required this.message,
    required this.primaryText,
    required this.onPrimary,
    this.secondaryImage,
    this.subtitle,
    this.privacyNotice,
    this.secondaryText,
    this.onSecondary,
    this.mode = GrowthConfirmMode.normal,
    this.imageSize = 100,
  });

  /// 主图片路径（assets 或网络）
  final String image;

  /// 次要图片路径（可选，叠加在主图片右下角）
  final String? secondaryImage;

  /// 标题
  final String title;

  /// 副标题（可选，显示在标题下方，字号更小）
  final String? subtitle;

  /// 描述内容
  final String message;

  /// 隐私提示（可选，显示为黄色警告卡片）
  final String? privacyNotice;

  /// 主按钮文字
  final String primaryText;

  /// 主按钮回调
  final GrowthConfirmCallback onPrimary;

  /// 次按钮文字（可选）
  final String? secondaryText;

  /// 次按钮回调（可选）
  final GrowthConfirmCallback? onSecondary;

  /// 弹窗模式
  final GrowthConfirmMode mode;

  /// 图片大小
  final double imageSize;

  /// 便捷方法：显示弹窗
  static Future<void> show({
    required BuildContext context,
    required String image,
    required String title,
    required String message,
    required String primaryText,
    required GrowthConfirmCallback onPrimary,
    String? secondaryImage,
    String? subtitle,
    String? privacyNotice,
    String? secondaryText,
    GrowthConfirmCallback? onSecondary,
    GrowthConfirmMode mode = GrowthConfirmMode.normal,
    double imageSize = 100,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => GrowthConfirmDialog(
        image: image,
        title: title,
        subtitle: subtitle,
        message: message,
        privacyNotice: privacyNotice,
        primaryText: primaryText,
        onPrimary: onPrimary,
        secondaryImage: secondaryImage,
        secondaryText: secondaryText,
        onSecondary: onSecondary,
        mode: mode,
        imageSize: imageSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final effectiveColor = _resolveAccentColor(colors);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(MediaQuery.sizeOf(context).width - 48, 380),
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
              _buildImage(context, colors),
              const SizedBox(height: 20),
              _buildTitle(colors),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                _buildSubtitle(colors),
              ],
              const SizedBox(height: 14),
              _buildMessage(colors),
              if (privacyNotice != null) ...[
                const SizedBox(height: 16),
                _buildPrivacyNotice(colors),
              ],
              const SizedBox(height: 24),
              _buildButtons(context, colors, effectiveColor),
            ],
          ),
        ),
      ),
    );
  }

  /// 解析主题色
  Color _resolveAccentColor(AppThemeColors colors) {
    switch (mode) {
      case GrowthConfirmMode.normal:
        return colors.primary;
      case GrowthConfirmMode.danger:
        return colors.danger;
      case GrowthConfirmMode.info:
        return colors.primary;
    }
  }

  /// 构建图片区域
  Widget _buildImage(BuildContext context, AppThemeColors colors) {
    return SizedBox(
      height: imageSize + (secondaryImage != null ? 20 : 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 主图片 - 带柔和背景光晕
          Container(
            width: imageSize + 24,
            height: imageSize + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _resolveAccentColor(colors).withValues(alpha: 0.06),
            ),
          ),
          Image.asset(
            image,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                Icons.image_outlined,
                size: imageSize * 0.4,
                color: colors.textHint,
              ),
            ),
          ),
          // 次要图片 - 使用 LayoutBuilder 获取实际宽度
          if (secondaryImage != null)
            Positioned(
              right: 10,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.card, width: 2),
                  boxShadow: AppShadows.sm,
                ),
                child: Image.asset(
                  secondaryImage!,
                  width: imageSize * 0.45,
                  height: imageSize * 0.45,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建标题
  Widget _buildTitle(AppThemeColors colors) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
      ),
    );
  }

  /// 构建副标题
  Widget _buildSubtitle(AppThemeColors colors) {
    return Text(
      subtitle!,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colors.textTertiary,
      ),
    );
  }

  /// 构建描述内容
  Widget _buildMessage(AppThemeColors colors) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: colors.textSecondary,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// 构建隐私提示卡片
  Widget _buildPrivacyNotice(AppThemeColors colors) {
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
              privacyNotice!,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建按钮区域
  Widget _buildButtons(
    BuildContext context,
    AppThemeColors colors,
    Color accentColor,
  ) {
    final hasSecondary = secondaryText != null;

    return Row(
      children: [
        // 次按钮（可选）
        if (hasSecondary) ...[
          Expanded(child: _buildSecondaryButton(context, colors)),
          const SizedBox(width: 12),
        ],
        // 主按钮
        Expanded(
          flex: hasSecondary ? 2 : 1,
          child: _buildPrimaryButton(context, colors, accentColor),
        ),
      ],
    );
  }

  /// 构建次按钮
  Widget _buildSecondaryButton(BuildContext context, AppThemeColors colors) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).pop();
        final callback = onSecondary;
        if (callback != null) {
          callback();
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: colors.textSecondary,
        side: BorderSide(color: colors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: Text(
        secondaryText!,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 构建主按钮
  Widget _buildPrimaryButton(
    BuildContext context,
    AppThemeColors colors,
    Color accentColor,
  ) {
    return FilledButton(
      onPressed: () {
        Navigator.of(context).pop();
        onPrimary();
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: accentColor,
        foregroundColor: colors.textOnAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: Text(
        primaryText,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 弹窗模式
enum GrowthConfirmMode {
  /// 普通确认（蓝色主按钮）
  normal,

  /// 危险操作（红色主按钮）
  danger,

  /// 信息展示（蓝色主按钮，单按钮时使用）
  info,
}
