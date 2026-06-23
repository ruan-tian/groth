import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/design/design.dart';
import '../models/settings_data.dart';
import '../../../shared/providers/service_providers.dart';
import '../../../shared/providers/settings_provider.dart'
    show lastBackupTimeProvider;

// =============================================================================
// Backup Page（褐色渐变风格）
// =============================================================================

/// 备份页面
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _isBackingUp = false;

  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);
    final colors = context.growthColors;

    try {
      final backupService = ref.read(backupServiceProvider);
      final filePath = await backupService.saveBackupToFile();

      ref.invalidate(backupRecordsProvider);
      ref.invalidate(backupOverviewProvider);
      ref.invalidate(lastBackupTimeProvider);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份成功: ${_fileName(filePath)}'),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('备份失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _deleteBackup(BackupRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除备份'),
        content: Text('确定要删除备份文件 ${_fileName(record.backupPath)} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: ctx.growthColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 删除本地文件
        await ref.read(backupServiceProvider).deleteBackup(record);

        ref.invalidate(backupRecordsProvider);
        ref.invalidate(backupOverviewProvider);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败，请重试')));
        }
      }
    }
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 获取目录路径
  String _dirPath(String filePath) {
    final parts = filePath.split(Platform.pathSeparator);
    if (parts.length <= 1) return filePath;
    return parts.sublist(0, parts.length - 1).join(Platform.pathSeparator);
  }

  // 复制路径到剪贴板
  void _copyPath(String path) {
    Clipboard.setData(ClipboardData(text: path));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('路径已复制'),
        backgroundColor: context.growthColors.success,
      ),
    );
  }

  // 分享备份文件
  Future<void> _shareBackup(BackupRecord record) async {
    try {
      await Share.shareXFiles([
        XFile(record.backupPath),
      ], text: 'Growth OS 备份文件');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分享失败，请重试')));
      }
    }
  }

  // 构建文字按钮
  Widget _buildTextButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(backupRecordsProvider);
    final overview = ref.watch(backupOverviewProvider);
    final colors = context.growthColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          '数据备份',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colors.textPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 备份概览 ──
            _buildOverviewCard(
              totalSizeInBytes: overview.maybeWhen(
                data: (value) => value.totalSizeInBytes,
                orElse: () => 0,
              ),
              lastBackupTime: overview.maybeWhen(
                data: (value) => value.lastBackupTime,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: 20),

            // ── 立即备份按钮 ──
            _buildBackupButton(),
            const SizedBox(height: 24),

            // ── 备份说明 ──
            _buildInfoCard(),
            const SizedBox(height: 24),

            // ── 备份记录 ──
            _buildSectionTitle('备份记录'),
            const SizedBox(height: 12),
            records.when(
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: list.map((r) => _buildBackupTile(r)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colors = context.growthColors;

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 概览卡片
  // ---------------------------------------------------------------------------

  Widget _buildOverviewCard({
    required int totalSizeInBytes,
    required DateTime? lastBackupTime,
  }) {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryDark, colors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '备份文件大小',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textOnAccent.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(totalSizeInBytes),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.textOnAccent,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colors.textOnAccent.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最后备份',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textOnAccent.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastBackupTime != null
                        ? _formatDateTime(lastBackupTime)
                        : '未备份',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textOnAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 备份按钮
  // ---------------------------------------------------------------------------

  Widget _buildBackupButton() {
    final colors = context.growthColors;

    return GestureDetector(
      onTap: _isBackingUp ? null : _backupData,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isBackingUp
              ? null
              : LinearGradient(
                  colors: [colors.primary, colors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isBackingUp ? colors.primaryLight : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isBackingUp
              ? null
              : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: _isBackingUp
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.textOnAccent,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.backup_rounded,
                      color: colors.textOnAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '立即备份',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textOnAccent,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 说明卡片
  // ---------------------------------------------------------------------------

  Widget _buildInfoCard() {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.softGold,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '备份文件仅保存在本地设备，不会上传到云端，请妥善保管你的备份文件。',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.backup_outlined,
            size: 48,
            color: colors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无备份记录',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '点击上方按钮创建第一个备份',
            style: TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 备份记录项
  // ---------------------------------------------------------------------------

  Widget _buildBackupTile(BackupRecord record) {
    final colors = context.growthColors;
    final fileName = _fileName(record.backupPath);
    final fileSize = _formatFileSize(record.fileSize ?? 0);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 文件信息
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.success,
                        colors.success.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.success.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: colors.textOnAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$fileSize · ${_formatDateTime(dateTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 目录路径
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 14,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _dirPath(record.backupPath),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildTextButton(
                  '复制路径',
                  colors.primary,
                  () => _copyPath(record.backupPath),
                ),
                const SizedBox(width: 8),
                _buildTextButton(
                  '分享',
                  colors.success,
                  () => _shareBackup(record),
                ),
                const Spacer(),
                _buildTextButton(
                  '删除',
                  colors.danger,
                  () => _deleteBackup(record),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
