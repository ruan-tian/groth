import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// =============================================================================
// 头像选择 Sheet
// =============================================================================

Future<void> showAvatarPickerSheet(
  BuildContext context, {
  required String? avatarPath,
  required ValueChanged<String> onAvatarUpdated,
  required VoidCallback onAvatarDeleted,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AvatarPickerSheet(
      avatarPath: avatarPath,
      onAvatarUpdated: onAvatarUpdated,
      onAvatarDeleted: onAvatarDeleted,
    ),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  final String? avatarPath;
  final ValueChanged<String> onAvatarUpdated;
  final VoidCallback onAvatarDeleted;

  const _AvatarPickerSheet({
    required this.avatarPath,
    required this.onAvatarUpdated,
    required this.onAvatarDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AvatarOption(
                icon: Icons.camera_alt_rounded,
                label: '拍照',
                color: const Color(0xFF5D68F2),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSave(context, ImageSource.camera);
                },
              ),
              _AvatarOption(
                icon: Icons.photo_library_rounded,
                label: '相册',
                color: const Color(0xFF35C976),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSave(context, ImageSource.gallery);
                },
              ),
              if (avatarPath != null)
                _AvatarOption(
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  color: const Color(0xFFFF6B6B),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar(context);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSave(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy(
        '${avatarDir.path}/$fileName',
      );

      onAvatarUpdated(savedFile.path);

      if (context.mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('头像已更新'),
            backgroundColor: Color(0xFF35C976),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  Future<void> _deleteAvatar(BuildContext context) async {
    if (avatarPath != null) {
      final file = File(avatarPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    onAvatarDeleted();
    HapticFeedback.lightImpact();
  }
}

class _AvatarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
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
      ),
    );
  }
}

// =============================================================================
// 性别选择 Sheet
// =============================================================================

Future<String?> showGenderPickerSheet(
  BuildContext context, {
  required String currentGender,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GenderPickerSheet(currentGender: currentGender),
  );
}

class _GenderPickerSheet extends StatelessWidget {
  final String currentGender;

  const _GenderPickerSheet({required this.currentGender});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
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
          _GenderOption(
            value: 'male',
            label: '男',
            icon: Icons.male_rounded,
            isSelected: currentGender == 'male',
            onTap: () => Navigator.pop(context, 'male'),
          ),
          const SizedBox(height: 12),
          _GenderOption(
            value: 'female',
            label: '女',
            icon: Icons.female_rounded,
            isSelected: currentGender == 'female',
            onTap: () => Navigator.pop(context, 'female'),
          ),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '选择性别：$label',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFF1DF)
                : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4A574)
                  : const Color(0xFFE8C9A0).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFD4A574)
                    : const Color(0xFF8B6F5E),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF5C3D2E)
                      : const Color(0xFF8B6F5E),
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFD4A574),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 身高编辑 Sheet
// =============================================================================

Future<String?> showHeightEditorSheet(
  BuildContext context, {
  required String currentHeight,
}) {
  final controller = TextEditingController(text: currentHeight);
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _HeightEditorSheet(
        controller: controller,
        formKey: formKey,
      ),
    ),
  );
}

class _HeightEditorSheet extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  const _HeightEditorSheet({
    required this.controller,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildDragHandle(),
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
                  child: const Icon(
                    Icons.height,
                    color: Color(0xFF35C976),
                    size: 20,
                  ),
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
              textInputAction: TextInputAction.done,
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
                  borderSide: const BorderSide(
                    color: Color(0xFFD4A574),
                    width: 2,
                  ),
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
                    Navigator.pop(context, controller.text);
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
    );
  }
}

// =============================================================================
// 通用编辑 Sheet 壳
// =============================================================================

/// 通用底部编辑弹窗外壳，[child] 为编辑内容区域。
/// 返回值由调用方通过 Navigator.pop 传回。
Widget buildEditSheet(
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
        _buildDragHandle(),
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
            onPressed: () => Navigator.pop(context),
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

// =============================================================================
// 共用拖拽条
// =============================================================================

Widget _buildDragHandle() {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFB0A09A).withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// =============================================================================
// 体重编辑 Sheet
// =============================================================================

Future<double?> showWeightEditorSheet(
  BuildContext context, {
  required double? currentWeight,
}) {
  final controller = TextEditingController(
    text: currentWeight?.toStringAsFixed(1) ?? '',
  );
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _WeightEditorSheet(
        controller: controller,
        formKey: formKey,
      ),
    ),
  );
}

class _WeightEditorSheet extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  const _WeightEditorSheet({
    required this.controller,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildDragHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D68F2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_outlined,
                    color: Color(0xFF5D68F2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '记录体重',
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
              textInputAction: TextInputAction.done,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C3D2E),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'kg',
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
                  borderSide: const BorderSide(
                    color: Color(0xFFD4A574),
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入体重';
                final n = double.tryParse(v);
                if (n == null || n <= 0 || n > 500) return '请输入有效体重';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, double.tryParse(controller.text));
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
    );
  }
}

// =============================================================================
// 体脂率编辑 Sheet
// =============================================================================

Future<double?> showBodyFatEditorSheet(
  BuildContext context, {
  required double? currentBodyFat,
}) {
  final controller = TextEditingController(
    text: currentBodyFat?.toStringAsFixed(1) ?? '',
  );
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _BodyFatEditorSheet(
        controller: controller,
        formKey: formKey,
      ),
    ),
  );
}

class _BodyFatEditorSheet extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  const _BodyFatEditorSheet({
    required this.controller,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildDragHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFFFF8A3D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '记录体脂率',
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
              textInputAction: TextInputAction.done,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C3D2E),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: '%',
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
                  borderSide: const BorderSide(
                    color: Color(0xFFD4A574),
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入体脂率';
                final n = double.tryParse(v);
                if (n == null || n < 0 || n > 60) return '请输入有效体脂率';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, double.tryParse(controller.text));
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
    );
  }
}
