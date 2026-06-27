import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/pages/add_sleep_record_sheet.dart';

/// Facade for dashboard to access health module quick actions.
///
/// This decouples the dashboard from directly importing health module pages.
/// The dashboard only needs to show quick action sheets.
class DashboardQuickActions {
  /// Show the add sleep record sheet.
  Future<void> showAddSleepRecord(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSleepRecordSheet(
        onSave: () {
          // Callback after saving
        },
      ),
    );
  }
}

/// Provider for DashboardQuickActions.
final dashboardQuickActionsProvider = Provider<DashboardQuickActions>((ref) {
  return DashboardQuickActions();
});
