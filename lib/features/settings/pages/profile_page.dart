import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/dashboard_provider.dart'
    hide settingRepositoryProvider;
import '../../../shared/providers/fitness_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/settings_provider.dart';

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

  Future<void> _showAvatarPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAvatarPickerSheet(ctx),
    );
  }

  Widget _buildAvatarPickerSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '更换头像',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C3D2E),
            ),
          ),
          const SizedBox(height: 24),

          // 选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAvatarOption(
                icon: Icons.camera_alt_rounded,
                label: '拍照',
                color: const Color(0xFF5D68F2),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildAvatarOption(
                icon: Icons.photo_library_rounded,
                label: '相册',
                color: const Color(0xFF35C976),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_avatarPath != null)
                _buildAvatarOption(
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  color: const Color(0xFFFF6B6B),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // 复制到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy(
        '${avatarDir.path}/$fileName',
      );

      setState(() => _avatarPath = savedFile.path);
      await _saveField('avatar_path', savedFile.path);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('头像已更新'),
            backgroundColor: Color(0xFF35C976),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteAvatar() async {
    if (_avatarPath != null) {
      final file = File(_avatarPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() => _avatarPath = null);
    await _saveField('avatar_path', '');

    if (mounted) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _showNicknameEditor() async {
    final controller = TextEditingController(text: _nicknameController.text);

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _buildEditSheet(
          ctx,
          title: '修改昵称',
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF5D68F2),
          child: TextField(
            controller: controller,
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
                borderSide: const BorderSide(color: Color(0xFFD4A574), width: 2),
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
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildGenderPickerSheet(ctx),
    );

    if (result != null) {
      setState(() => _gender = result);
      await _saveField('gender', result);
    }
  }

  Widget _buildGenderPickerSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '选择性别',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C3D2E),
            ),
          ),
          const SizedBox(height: 24),
          _buildGenderOption(context, 'male', '男', Icons.male_rounded),
          const SizedBox(height: 12),
          _buildGenderOption(context, 'female', '女', Icons.female_rounded),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1DF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4A574)
                : const Color(0xFFE8C9A0).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFD4A574) : const Color(0xFF8B6F5E), size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF5C3D2E) : const Color(0xFF8B6F5E),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFD4A574), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4A574),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF5C3D2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthday = picked);
      await _saveField('birthday', picked.toIso8601String());
    }
  }

  Future<void> _showHeightEditor() async {
    final controller = TextEditingController(text: _heightController.text);
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF35C976).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.height, color: Color(0xFF35C976), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '设置身高',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C3D2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3D2E),
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: 'cm',
                    suffixStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB0A09A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8C9A0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD4A574), width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请输入身高';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0 || n > 250) return '请输入有效身高';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, controller.text);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A574),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _heightController.text = result);
      await _saveField('height', result);
    }
  }

  Widget _buildEditSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5C3D2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // 获取TextField的值并返回
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelName(int level) {
    if (level < 5) return '成长新手';
    if (level < 10) return '习惯探索者';
    if (level < 20) return '成长实践家';
    if (level < 30) return '成长探索家';
    if (level < 50) return '长期主义者';
    return '成长大师';
  }

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
            _buildAvatarSection(dashboard),
            const SizedBox(height: 32),

            // ── 基本信息 ──
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 12),
            _buildInfoGroup(latestWeight),
            const SizedBox(height: 24),

            // ── 身体数据（同步） ──
            _buildSectionTitle('身体数据（自动同步）'),
            const SizedBox(height: 12),
            _buildBodyDataGroup(latestWeight),
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

  // ---------------------------------------------------------------------------
  // 头像区域
  // ---------------------------------------------------------------------------

  Widget _buildAvatarSection(AsyncValue<DashboardData> dashboard) {
    return Column(
      children: [
        // 头像（点击可更换）
        GestureDetector(
          onTap: _showAvatarPicker,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
                // 头像容器
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: _avatarPath == null
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFD4A574), Color(0xFFE8C9A0)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _avatarPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.file(
                            File(_avatarPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, ___) => const Center(
                              child: Text('🐱', style: TextStyle(fontSize: 56)),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text('🐱', style: TextStyle(fontSize: 56)),
                        ),
                ),
                // 相机图标
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C3D2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 昵称（点击可编辑）
        GestureDetector(
          onTap: _showNicknameEditor,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Row(
              key: ValueKey(_nicknameController.text),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _nicknameController.text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3D2E),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFFB0A09A),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 等级
        dashboard.when(
          data: (data) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(data.currentLevel),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv.${data.currentLevel} · ${_getLevelName(data.currentLevel)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFD4A574),
                ),
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 基本信息
  // ---------------------------------------------------------------------------

  Widget _buildInfoGroup(AsyncValue<BodyMetric?> latestWeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 性别
          _buildInfoTile(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF5D68F2),
            label: '性别',
            value: _gender == 'male' ? '男' : '女',
            onTap: _showGenderPicker,
          ),
          _buildDivider(),

          // 生日
          _buildInfoTile(
            icon: Icons.cake_outlined,
            iconColor: const Color(0xFFFF8A3D),
            label: '生日',
            value: '${_birthday.year}年${_birthday.month}月${_birthday.day}日',
            onTap: _pickBirthday,
          ),
          _buildDivider(),

          // 身高
          _buildInfoTile(
            icon: Icons.height,
            iconColor: const Color(0xFF35C976),
            label: '身高',
            value: _heightController.text.isNotEmpty
                ? '${_heightController.text} cm'
                : '未设置',
            onTap: _showHeightEditor,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 身体数据（自动同步）
  // ---------------------------------------------------------------------------

  Widget _buildBodyDataGroup(AsyncValue<BodyMetric?> latestWeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: latestWeight.when(
        data: (metric) => Column(
          children: [
            // 体重
            _buildInfoTile(
              icon: Icons.monitor_weight_outlined,
              iconColor: const Color(0xFF5D68F2),
              label: '体重',
              value: metric?.weight != null
                  ? '${metric!.weight!.toStringAsFixed(1)} kg'
                  : '未记录',
              subtitle: '每日自动同步',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF35C976).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '自动',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF35C976),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            _buildDivider(),

            // 体脂率
            _buildInfoTile(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFFFF8A3D),
              label: '体脂率',
              value: metric?.bodyFat != null
                  ? '${metric!.bodyFat!.toStringAsFixed(1)}%'
                  : '未记录',
              subtitle: '每日自动同步',
            ),
            _buildDivider(),

            // BMI
            _buildInfoTile(
              icon: Icons.analytics_outlined,
              iconColor: const Color(0xFF7058F5),
              label: 'BMI',
              value: _calculateBMI(metric),
              subtitle: '根据身高体重计算',
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const Padding(
          padding: EdgeInsets.all(20),
          child: Text('加载失败'),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // 标签和副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5C3D2E),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB0A09A),
                      ),
                    ),
                ],
              ),
            ),

            // 值
            if (trailing != null) trailing,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                value,
                key: ValueKey(value),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B6F5E),
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFB0A09A),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64,
      color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
    );
  }

  String _calculateBMI(BodyMetric? metric) {
    if (metric?.weight == null || _heightController.text.isEmpty) {
      return '需要身高体重';
    }
    final height = double.tryParse(_heightController.text);
    if (height == null || height <= 0) return '身高数据异常';

    final bmi = calculateBMI(metric!.weight, height);
    if (bmi == null) return '计算失败';

    final category = getBMICategory(bmi);
    return '${bmi.toStringAsFixed(1)} ($category)';
  }
}
