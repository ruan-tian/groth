import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/design/design.dart';

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
  const _AvatarPickerSheet({
    required this.avatarPath,
    required this.onAvatarUpdated,
    required this.onAvatarDeleted,
  });

  final String? avatarPath;
  final ValueChanged<String> onAvatarUpdated;
  final VoidCallback onAvatarDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 20),
          Text('更换头像', style: _sheetTitleStyle(colors)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AvatarOption(
                icon: Icons.camera_alt_rounded,
                label: '拍照',
                color: colors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSave(context, ImageSource.camera);
                },
              ),
              _AvatarOption(
                icon: Icons.photo_library_rounded,
                label: '相册',
                color: colors.success,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSave(context, ImageSource.gallery);
                },
              ),
              if (avatarPath != null)
                _AvatarOption(
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  color: colors.danger,
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
    final colors = context.growthColors;
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
      final savedFile = await File(
        pickedFile.path,
      ).copy('${avatarDir.path}/$fileName');

      onAvatarUpdated(savedFile.path);

      if (context.mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('头像已更新'),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('选择图片失败，请重试')));
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
  const _AvatarOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

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
  const _GenderPickerSheet({required this.currentGender});

  final String currentGender;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 20),
          Text('选择性别', style: _sheetTitleStyle(colors)),
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
  const _GenderOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Semantics(
      button: true,
      label: '选择性别: $label',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.1)
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.border.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      child: _NumberEditorSheet<String>(
        controller: controller,
        formKey: formKey,
        title: '设置身高',
        icon: Icons.height,
        iconColor: context.growthColors.success,
        suffixText: 'cm',
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入身高';
          final number = double.tryParse(value);
          if (number == null || number <= 0 || number > 250) {
            return '请输入有效身高';
          }
          return null;
        },
        onSubmit: (value) => value,
      ),
    ),
  );
}

Widget buildEditSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color iconColor,
  required Widget child,
}) {
  final colors = context.growthColors;
  return _SheetShell(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(context),
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
            Expanded(child: Text(title, style: _sheetTitleStyle(colors))),
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
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnAccent,
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
      child: _NumberEditorSheet<double>(
        controller: controller,
        formKey: formKey,
        title: '记录体重',
        icon: Icons.monitor_weight_outlined,
        iconColor: context.growthColors.primary,
        suffixText: 'kg',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入体重';
          final number = double.tryParse(value);
          if (number == null || number <= 0 || number > 500) {
            return '请输入有效体重';
          }
          return null;
        },
        onSubmit: double.tryParse,
      ),
    ),
  );
}

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
      child: _NumberEditorSheet<double>(
        controller: controller,
        formKey: formKey,
        title: '记录体脂率',
        icon: Icons.water_drop_outlined,
        iconColor: context.growthColors.fitness,
        suffixText: '%',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return '请输入体脂率';
          final number = double.tryParse(value);
          if (number == null || number < 0 || number > 60) {
            return '请输入有效体脂率';
          }
          return null;
        },
        onSubmit: double.tryParse,
      ),
    ),
  );
}

class _NumberEditorSheet<T> extends StatelessWidget {
  const _NumberEditorSheet({
    required this.controller,
    required this.formKey,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.suffixText,
    required this.keyboardType,
    required this.validator,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String suffixText;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final T? Function(String) onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SheetShell(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(context),
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
                Text(title, style: _sheetTitleStyle(colors)),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: controller,
              textInputAction: TextInputAction.done,
              autofocus: true,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: suffixText,
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: colors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: iconColor, width: 2),
                ),
              ),
              validator: validator,
              onFieldSubmitted: (value) => _trySubmit(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _trySubmit(context),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.textOnAccent,
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

  void _trySubmit(BuildContext context) {
    if (formKey.currentState!.validate()) {
      Navigator.pop(context, onSubmit(controller.text));
    }
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 32),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: padding,
      child: child,
    );
  }
}

TextStyle _sheetTitleStyle(AppThemeColors colors) {
  return TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: colors.textPrimary,
  );
}

Widget _buildDragHandle(BuildContext context) {
  final colors = context.growthColors;
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: colors.textTertiary.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
