import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/local_error_log_service.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(LocalErrorLogService.recordFlutterError(details));
      };

      ErrorWidget.builder = (details) {
        unawaited(LocalErrorLogService.recordFlutterError(details));
        return const _GrowthOSErrorWidget();
      };

      runApp(const ProviderScope(child: GrowthOSApp()));
    },
    (error, stack) {
      unawaited(LocalErrorLogService.record(error, stack, source: 'zone'));
    },
  );
}

class _GrowthOSErrorWidget extends StatelessWidget {
  const _GrowthOSErrorWidget();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFF8F3),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This page could not be displayed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5A3A32),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
