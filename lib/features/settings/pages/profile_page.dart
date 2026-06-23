import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/fitness_provider.dart';
import '../../../shared/providers/settings_facade.dart';
import '../../../shared/providers/settings_provider.dart';
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
  String? _profileSnapshotKey;

  late AnimationController _saveAnimController;

  @override
  void initState() {
    super.initState();
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

  void _applyProfileSnapshot(UserProfileSnapshot snapshot) {
    final nextKey = snapshot.cacheKey;
    if (_profileSnapshotKey == nextKey) return;
    _profileSnapshotKey = nextKey;
    _nicknameController.text = snapshot.nickname;
    _heightController.text = snapshot.heightText;
    _birthday = snapshot.birthday;
    _gender = snapshot.gender;
    _avatarPath = snapshot.avatarPath;
  }

  Future<void> _saveField(String key, String value) async {
    await ref.read(settingsFacadeProvider).setUserProfileField(key, value);
    HapticFeedback.lightImpact();
  }

  // ── 编辑动作回调 ────────────────────────────────────────────────────────────

  Future<void> _showAvatarPicker() async {
    final action = await showAvatarPickerSheet(
      context,
      avatarPath: _avatarPath,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case AvatarPickerAction.camera:
        await _pickAndSaveAvatar(ImageSource.camera);
        break;
      case AvatarPickerAction.gallery:
        await _pickAndSaveAvatar(ImageSource.gallery);
        break;
      case AvatarPickerAction.delete:
        await _deleteAvatar();
        break;
    }
  }

  Future<void> _pickAndSaveAvatar(ImageSource source) async {
    final colors = context.growthColors;
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(
        pickedFile.path,
      ).copy('${avatarDir.path}/$fileName');

      await ref.read(settingsFacadeProvider).setUserAvatarPath(savedFile.path);
      if (!mounted) return;
      setState(() => _avatarPath = savedFile.path);
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('\u5934\u50cf\u5df2\u66f4\u65b0'),
          backgroundColor: colors.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u9009\u62e9\u56fe\u7247\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAvatar() async {
    final current = _avatarPath;
    if (current != null) {
      final file = File(current);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await ref.read(settingsFacadeProvider).setUserAvatarPath(null);
    if (!mounted) return;
    setState(() => _avatarPath = null);
    HapticFeedback.lightImpact();
  }

  Future<void> _showNicknameEditor() async {
    final colors = context.growthColors;
    final controller = TextEditingController(text: _nicknameController.text);
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: buildEditSheet(
            ctx,
            title: '修改昵称',
            icon: Icons.person_rounded,
            iconColor: colors.primary,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              maxLength: 20,
              autofocus: true,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '输入昵称',
                counterText: '',
                hintStyle: TextStyle(color: colors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() => _nicknameController.text = result);
        await _saveField('nickname', result);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showGenderPicker() async {
    final result = await showGenderPickerSheet(context, currentGender: _gender);
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
    final recordDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db
        .into(db.bodyMetrics)
        .insert(
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
      final height = double.tryParse(result);
      if (height == null || height < 50 || height > 250) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请输入有效的身高（50-250cm）')));
        }
        return;
      }
      setState(() => _heightController.text = result);
      await _saveField('height', result);
    }
  }

  // ── 构建 ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileSnapshotProvider);
    final latestWeight = ref.watch(latestBodyMetricProvider);
    final dashboard = ref.watch(dashboardProvider);
    final colors = context.growthColors;

    profile.whenData(_applyProfileSnapshot);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          '个人资料',
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
          children: [
            // ── 头像区域 ──
            ProfileAvatarSection(
              avatarPath: _avatarPath,
              nickname: _nicknameController.text,
              dashboard: dashboard,
              onAvatarTap: _showAvatarPicker,
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
    final colors = context.growthColors;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
