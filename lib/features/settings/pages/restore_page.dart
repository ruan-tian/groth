import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/service_providers.dart';
import 'backup_page.dart';

/// 恢复页面（褐色渐变风格）
class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key});

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  PlatformFile? _selectedFile;
  bool _isRestoring = false;
  bool _isCorrupted = false;
  String _restoreWarning = '';

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _selectedFile = file;
        _isCorrupted = false;
        _restoreWarning = '';
      });

      if (file.extension != 'json') {
        setState(() {
          _isCorrupted = true;
          _restoreWarning = '请选择 .json 格式的备份文件';
        });
        return;
      }

      if (file.size > 100 * 1024 * 1024) {
        setState(() {
          _isCorrupted = true;
          _restoreWarning = '文件大小超过 100MB 限制';
        });
        return;
      }

      if (file.path != null) {
        try {
          final content = await File(file.path!).readAsString();
          final parsed = jsonDecode(content);
          if (parsed is! Map<String, dynamic> || !parsed.containsKey('data')) {
            setState(() {
              _isCorrupted = true;
              _restoreWarning = '无效的备份文件格式，缺少 data 字段';
            });
          }
        } catch (e) {
          setState(() {
            _isCorrupted = true;
            _restoreWarning = '文件内容解析失败: $e';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('文件选择失败: $e')));
      }
    }
  }

  Future<void> _restoreData() async {
    if (_selectedFile == null || _selectedFile!.path == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认恢复'),
        content: Text('确定要从备份文件 ${_selectedFile!.name} 恢复数据吗？\n\n这将覆盖当前所有数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD4A574),
            ),
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);

    try {
      final content = await File(_selectedFile!.path!).readAsString();
      final backupService = ref.read(backupServiceProvider);
      await backupService.importFromJson(content);

      ref.invalidate(backupRecordsProvider);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据恢复成功'),
            backgroundColor: Color(0xFF35C976),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E1),
      appBar: AppBar(
        title: const Text(
          '数据恢复',
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
            // ── 警告卡片 ──
            _buildWarningCard(),
            const SizedBox(height: 24),

            // ── 文件选择区域 ──
            _buildSectionTitle('选择备份文件'),
            const SizedBox(height: 12),
            _buildFilePicker(),
            const SizedBox(height: 24),

            // ── 选中文件信息 ──
            if (_selectedFile != null) ...[
              _buildSectionTitle('文件信息'),
              const SizedBox(height: 12),
              _buildFileInfo(),
              const SizedBox(height: 24),
            ],

            // ── 错误提示 ──
            if (_isCorrupted) ...[
              _buildErrorCard(),
              const SizedBox(height: 24),
            ],

            // ── 恢复按钮 ──
            if (_selectedFile != null && !_isCorrupted) ...[
              _buildRestoreButton(),
              const SizedBox(height: 24),
            ],

            // ── 使用说明 ──
            _buildSectionTitle('使用说明'),
            const SizedBox(height: 12),
            _buildInstructions(),
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
  // 警告卡片
  // ---------------------------------------------------------------------------

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A3D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A3D).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF8A3D),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '恢复数据将覆盖当前所有数据，请谨慎操作。建议先备份当前数据。',
              style: TextStyle(
                fontSize: 13,
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
  // 文件选择器
  // ---------------------------------------------------------------------------

  Widget _buildFilePicker() {
    return Semantics(
      button: true,
      label: '选择备份文件',
      child: GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A574).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: Color(0xFFD4A574),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '点击选择备份文件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5C3D2E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '支持 .json 格式的备份文件',
              style: TextStyle(fontSize: 12, color: Color(0xFFB0A09A)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 文件信息
  // ---------------------------------------------------------------------------

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isCorrupted
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.1)
                  : const Color(0xFF35C976).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isCorrupted
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: _isCorrupted
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF35C976),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5C3D2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(_selectedFile!.size),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0A09A),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: '移除选中文件',
            child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFile = null;
                _isCorrupted = false;
                _restoreWarning = '';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFB0A09A),
                size: 18,
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 错误卡片
  // ---------------------------------------------------------------------------

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF6B6B),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _restoreWarning,
              style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 恢复按钮
  // ---------------------------------------------------------------------------

  Widget _buildRestoreButton() {
    return Semantics(
      button: true,
      label: '开始恢复数据',
      child: GestureDetector(
      onTap: _isRestoring ? null : _restoreData,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isRestoring
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4A574), Color(0xFFE8C9A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isRestoring ? const Color(0xFFE8C9A0) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isRestoring
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
          child: _isRestoring
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
                    Icon(Icons.restore_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '开始恢复',
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 使用说明
  // ---------------------------------------------------------------------------

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildInstructionItem('1', '点击上方区域选择备份文件'),
          const SizedBox(height: 12),
          _buildInstructionItem('2', '系统会自动验证文件格式'),
          const SizedBox(height: 12),
          _buildInstructionItem('3', '确认无误后点击"开始恢复"'),
          const SizedBox(height: 12),
          _buildInstructionItem('4', '恢复完成后会自动刷新数据'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A574).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4A574),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8B6F5E)),
          ),
        ),
      ],
    );
  }
}
