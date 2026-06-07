import 'package:flutter/material.dart';

import '../../app/theme.dart';

class SwipeDeleteTile extends StatelessWidget {
  const SwipeDeleteTile({
    super.key,
    required this.child,
    required this.onDismissed,
    this.onConfirmDelete,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onDismissed;
  final Future<bool> Function()? onConfirmDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);

    return Dismissible(
      key: key ?? UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onError,
          size: 28,
        ),
      ),
      confirmDismiss: onConfirmDelete != null
          ? (_) => onConfirmDelete!()
          : null,
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }
}
