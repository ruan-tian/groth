import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';

/// Facade for fitness module to refresh dashboard data.
///
/// This decouples the fitness module from directly importing dashboard providers.
/// The fitness module only needs to invalidate dashboard after adding a record.
class FitnessDashboardFacade {
  FitnessDashboardFacade(this._ref);

  final Ref _ref;

  /// Invalidate dashboard data to trigger a refresh.
  void refreshDashboard() {
    _ref.invalidate(dashboardProvider);
  }
}

/// Provider for FitnessDashboardFacade.
final fitnessDashboardFacadeProvider = Provider<FitnessDashboardFacade>((ref) {
  return FitnessDashboardFacade(ref);
});
