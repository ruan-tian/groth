import 'package:flutter/material.dart';

import '../../../app/design/design.dart';

enum AvatarPickerAction { camera, gallery, delete }

Future<AvatarPickerAction?> showAvatarPickerSheet(
  BuildContext context, {
  required String? avatarPath,
}) {
  return showModalBottomSheet<AvatarPickerAction?>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AvatarPickerSheet(avatarPath: avatarPath),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({required this.avatarPath});

  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 20),
          Text('\u66f4\u6362\u5934\u50cf', style: _sheetTitleStyle(colors)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AvatarOption(
                icon: Icons.camera_alt_rounded,
                label: '\u62cd\u7167',
                color: colors.primary,
                onTap: () => Navigator.pop(context, AvatarPickerAction.camera),
              ),
              _AvatarOption(
                icon: Icons.photo_library_rounded,
                label: '\u76f8\u518c',
                color: colors.success,
                onTap: () => Navigator.pop(context, AvatarPickerAction.gallery),
              ),
              if (avatarPath != null)
                _AvatarOption(
                  icon: Icons.delete_outline_rounded,
                  label: '\u5220\u9664',
                  color: colors.danger,
                  onTap: () =>
                      Navigator.pop(context, AvatarPickerAction.delete),
                ),
            ],
          ),
        ],
      ),
    );
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
          Text('\u9009\u62e9\u6027\u522b', style: _sheetTitleStyle(colors)),
          const SizedBox(height: 24),
          _GenderOption(
            value: 'male',
            label: '\u7537',
            icon: Icons.male_rounded,
            isSelected: currentGender == 'male',
            onTap: () => Navigator.pop(context, 'male'),
          ),
          const SizedBox(height: 12),
          _GenderOption(
            value: 'female',
            label: '\u5973',
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
      label: '\u9009\u62e9\u6027\u522b: $label',
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
        title: '\u8bbe\u7f6e\u8eab\u9ad8',
        icon: Icons.height,
        iconColor: context.growthColors.success,
        suffixText: 'cm',
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '\u8bf7\u8f93\u5165\u8eab\u9ad8';
          }
          final number = double.tryParse(value);
          if (number == null || number <= 0 || number > 250) {
            return '\u8bf7\u8f93\u5165\u6709\u6548\u8eab\u9ad8';
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
            child: const Text('\u4fdd\u5b58'),
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
        title: '\u8bb0\u5f55\u4f53\u91cd',
        icon: Icons.monitor_weight_outlined,
        iconColor: context.growthColors.primary,
        suffixText: 'kg',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '\u8bf7\u8f93\u5165\u4f53\u91cd';
          }
          final number = double.tryParse(value);
          if (number == null || number <= 0 || number > 500) {
            return '\u8bf7\u8f93\u5165\u6709\u6548\u4f53\u91cd';
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
        title: '\u8bb0\u5f55\u4f53\u8102\u7387',
        icon: Icons.water_drop_outlined,
        iconColor: context.growthColors.fitness,
        suffixText: '%',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '\u8bf7\u8f93\u5165\u4f53\u8102\u7387';
          }
          final number = double.tryParse(value);
          if (number == null || number < 0 || number > 60) {
            return '\u8bf7\u8f93\u5165\u6709\u6548\u4f53\u8102\u7387';
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
                child: const Text('\u4fdd\u5b58'),
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
