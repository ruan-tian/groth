import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../dashboard/providers/dashboard_provider.dart'
    hide backupRecordsProvider, backupServiceProvider;
import '../../plan/providers/task_provider.dart';
import '../../study/providers/study_provider.dart';
import '../../fitness/providers/fitness_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../../../shared/providers/focus_provider.dart';
import '../../health/providers/sleep_provider.dart';
import '../../health/providers/diet_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/providers/service_providers.dart'
    show backupRecordsProvider, backupServiceProvider;

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
        ).showSnackBar(SnackBar(content: Text('文件选择失败，请重试')));
      }
    }
  }

  Future<void> _restoreData() async {
    if (_selectedFile == null || _selectedFile!.path == null) return;
    final colors = context.growthColors;

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
            style: TextButton.styleFrom(foregroundColor: colors.primary),
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
      ref.invalidate(dashboardProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayStudyMinutesProvider);
      ref.invalidate(todayFitnessMinutesProvider);
      ref.invalidate(todayJournalCountProvider);
      ref.invalidate(todayFocusMinutesProvider);
      ref.invalidate(lastNightSleepRecordProvider);
      ref.invalidate(todayDietCountProvider);

      // 刷新设置 Provider
      ref.invalidate(themeModeProvider);
      ref.invalidate(defaultRecordModeProvider);
      ref.invalidate(dailyGoalsProvider);
      ref.invalidate(dailyCalorieGoalProvider);
      ref.invalidate(dailyWaterGoalProvider);
      ref.invalidate(sleepGoalProvider);
      ref.invalidate(weeklyFitnessGoalProvider);

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
        ).showSnackBar(SnackBar(content: Text('恢复失败，请重试')));
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
    final colors = context.growthColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          '数据恢复',
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
  // 警告卡片
  // ---------------------------------------------------------------------------

  Widget _buildWarningCard() {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.softOrange,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: colors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '恢复数据将覆盖当前所有数据，请谨慎操作。建议先备份当前数据。',
              style: TextStyle(
                fontSize: 13,
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
  // 文件选择器
  // ---------------------------------------------------------------------------

  Widget _buildFilePicker() {
    final colors = context.growthColors;

    return Semantics(
      button: true,
      label: '选择备份文件',
      child: GestureDetector(
        onTap: _pickFile,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: colors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '点击选择备份文件',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '支持 .json 格式的备份文件',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
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
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isCorrupted
                  ? colors.danger.withValues(alpha: 0.12)
                  : colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isCorrupted
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: _isCorrupted ? colors.danger : colors.success,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(_selectedFile!.size),
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
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
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textTertiary,
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
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.danger, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _restoreWarning,
              style: TextStyle(fontSize: 13, color: colors.danger),
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
    final colors = context.growthColors;

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
                : LinearGradient(
                    colors: [colors.primary, colors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _isRestoring ? colors.primaryLight : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isRestoring
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
            child: _isRestoring
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
                        Icons.restore_rounded,
                        color: colors.textOnAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '开始恢复',
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 使用说明
  // ---------------------------------------------------------------------------

  Widget _buildInstructions() {
    final colors = context.growthColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
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
    final colors = context.growthColors;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
