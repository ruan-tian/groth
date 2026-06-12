import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    hide settingRepositoryProvider;
import '../../../shared/providers/fitness_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/common/growth_date_picker.dart';
import '../widgets/profile_avatar_section.dart';
import '../widgets/profile_info_tiles.dart';
import '../widgets/profile_sheets.dart';

/// 个人资料页面（点击即编辑模式）
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _nicknameController = TextEditingController(text: '甜甜');
  final _heightController = TextEditingController();

  DateTime _birthday = DateTime(2000, 6, 15);
  String _gender = 'male';
  String? _avatarPath;

  late AnimationController _saveAnimController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  // ── 数据持久化 ──────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final repo = ref.read(settingRepositoryProvider);
    final nickname = await repo.getSetting('nickname');
    final birthday = await repo.getSetting('birthday');
    final gender = await repo.getSetting('gender');
    final height = await repo.getSetting('height');
    final avatarPath = await repo.getSetting('avatar_path');

    if (mounted) {
      setState(() {
        if (nickname != null) _nicknameController.text = nickname;
        if (birthday != null) {
          _birthday = DateTime.tryParse(birthday) ?? _birthday;
        }
        if (gender != null) _gender = gender;
        if (height != null) _heightController.text = height;
        if (avatarPath != null) _avatarPath = avatarPath;
      });
    }
  }

  Future<void> _saveField(String key, String value) async {
    final repo = ref.read(settingRepositoryProvider);
    await repo.setSetting(key, value);
    HapticFeedback.lightImpact();
  }

  // ── 编辑动作回调 ────────────────────────────────────────────────────────────

  void _onAvatarUpdated(String path) {
    setState(() => _avatarPath = path);
    _saveField('avatar_path', path);
  }

  void _onAvatarDeleted() {
    setState(() => _avatarPath = null);
    _saveField('avatar_path', '');
  }

  Future<void> _showNicknameEditor() async {
    final controller = TextEditingController(text: _nicknameController.text);

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: buildEditSheet(
          ctx,
          title: '修改昵称',
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF5D68F2),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            autofocus: true,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C3D2E),
            ),
            decoration: InputDecoration(
              hintText: '输入昵称',
              hintStyle: const TextStyle(color: Color(0xFFC9CDD4)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8C9A0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFD4A574),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _nicknameController.text = result);
      await _saveField('nickname', result);
    }
  }

  Future<void> _showGenderPicker() async {
    final result = await showGenderPickerSheet(
      context,
      currentGender: _gender,
    );
    if (result != null) {
      setState(() => _gender = result);
      await _saveField('gender', result);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showGrowthDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _birthday = picked);
      await _saveField('birthday', picked.toIso8601String());
    }
  }

  Future<void> _showWeightEditor() async {
    final latestMetric = ref.read(latestBodyMetricProvider).valueOrNull;
    final currentWeight = latestMetric?.weight;

    final result = await showWeightEditorSheet(
      context,
      currentWeight: currentWeight,
    );

    if (result != null && mounted) {
      await _saveBodyMetric(weight: result);
      ref.invalidate(latestBodyMetricProvider);
      ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _showBodyFatEditor() async {
    final latestMetric = ref.read(latestBodyMetricProvider).valueOrNull;
    final currentBodyFat = latestMetric?.bodyFat;

    final result = await showBodyFatEditorSheet(
      context,
      currentBodyFat: currentBodyFat,
    );

    if (result != null && mounted) {
      await _saveBodyMetric(bodyFat: result);
      ref.invalidate(latestBodyMetricProvider);
      ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _saveBodyMetric({double? weight, double? bodyFat}) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final recordDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db.into(db.bodyMetrics).insert(
      BodyMetricsCompanion.insert(
        recordDate: recordDate,
        weight: Value(weight),
        bodyFat: Value(bodyFat),
        createdAt: now.millisecondsSinceEpoch,
      ),
    );

    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据已保存'),
          backgroundColor: Color(0xFF35C976),
        ),
      );
    }
  }

  Future<void> _showHeightEditor() async {
    final result = await showHeightEditorSheet(
      context,
      currentHeight: _heightController.text,
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _heightController.text = result);
      await _saveField('height', result);
    }
  }

  // ── 构建 ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final latestWeight = ref.watch(latestBodyMetricProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E1),
      appBar: AppBar(
        title: const Text(
          '个人资料',
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
          children: [
            // ── 头像区域 ──
            ProfileAvatarSection(
              avatarPath: _avatarPath,
              nickname: _nicknameController.text,
              dashboard: dashboard,
              onAvatarTap: () => showAvatarPickerSheet(
                context,
                avatarPath: _avatarPath,
                onAvatarUpdated: _onAvatarUpdated,
                onAvatarDeleted: _onAvatarDeleted,
              ),
              onNicknameTap: _showNicknameEditor,
            ),
            const SizedBox(height: 32),

            // ── 基本信息 ──
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 12),
            ProfileBasicInfoGroup(
              gender: _gender,
              birthday: _birthday,
              heightText: _heightController.text,
              onGenderTap: _showGenderPicker,
              onBirthdayTap: _pickBirthday,
              onHeightTap: _showHeightEditor,
            ),
            const SizedBox(height: 24),

            // ── 身体数据（支持手动编辑）──
            _buildSectionTitle('身体数据'),
            const SizedBox(height: 12),
            ProfileBodyDataGroup(
              latestWeight: latestWeight,
              heightText: _heightController.text,
              onWeightTap: _showWeightEditor,
              onBodyFatTap: _showBodyFatEditor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5C3D2E),
        ),
      ),
    );
  }
}
