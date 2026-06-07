import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/service_providers.dart';

// =============================================================================
// Backup Records Provider
// =============================================================================

final backupRecordsProvider = FutureProvider<List<BackupRecord>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final records = await (db.select(db.backupRecords)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
  return records;
});

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
  int _backupSizeInBytes = 0;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadBackupOverview();
  }

  Future<void> _loadBackupOverview() async {
    final db = ref.read(appDatabaseProvider);
    final records = await (db.select(db.backupRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    if (!mounted) return;

    int totalSize = 0;
    for (final r in records) {
      totalSize += r.fileSize ?? 0;
    }

    setState(() {
      _backupSizeInBytes = totalSize;
      if (records.isNotEmpty) {
        _lastBackupTime = DateTime.fromMillisecondsSinceEpoch(
          records.first.createdAt,
        );
      }
    });
  }

  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final filePath = await backupService.saveBackupToFile();

      ref.invalidate(backupRecordsProvider);
      await _loadBackupOverview();

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份成功: ${_fileName(filePath)}'),
            backgroundColor: const Color(0xFF35C976),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
        );
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 删除本地文件
        final file = File(record.backupPath);
        if (await file.exists()) {
          await file.delete();
        }

        // 删除数据库记录
        final db = ref.read(appDatabaseProvider);
        await (db.delete(db.backupRecords)
              ..where((t) => t.id.equals(record.id)))
            .go();

        ref.invalidate(backupRecordsProvider);
        await _loadBackupOverview();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
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

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(backupRecordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E1),
      appBar: AppBar(
        title: const Text(
          '数据备份',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C3D2E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF5C3D2E),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 备份概览 ──
            _buildOverviewCard(),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5C3D2E),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 概览卡片
  // ---------------------------------------------------------------------------

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C3D2E), Color(0xFF8B6F5E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3D2E).withValues(alpha: 0.3),
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
                const Text(
                  '备份文件大小',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(_backupSizeInBytes),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最后备份',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastBackupTime != null
                        ? _formatDateTime(_lastBackupTime!)
                        : '未备份',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
    return GestureDetector(
      onTap: _isBackingUp ? null : _backupData,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isBackingUp
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4A574), Color(0xFFE8C9A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isBackingUp ? const Color(0xFFE8C9A0) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isBackingUp
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: _isBackingUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.backup_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '立即备份',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD4A574),
            size: 18,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '备份文件仅保存在本地设备，不会上传到云端，请妥善保管你的备份文件。',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8B6F5E),
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.backup_outlined,
            size: 48,
            color: const Color(0xFFB0A09A).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无备份记录',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFB0A09A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击上方按钮创建第一个备份',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFD0C4B8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 备份记录项
  // ---------------------------------------------------------------------------

  Widget _buildBackupTile(BackupRecord record) {
    final fileName = _fileName(record.backupPath);
    final fileSize = _formatFileSize(record.fileSize ?? 0);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF35C976).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: Color(0xFF35C976),
            size: 20,
          ),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5C3D2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$fileSize · ${_formatDateTime(dateTime)}',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFB0A09A),
          ),
        ),
        trailing: GestureDetector(
          onTap: () => _deleteBackup(record),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFFF6B6B),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
