import 'dart:async';

import 'package:flutter/foundation.dart';
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
        return _GrowthOSErrorWidget(details: details);
      };

      // Notifications are initialized via Riverpod provider (reminderNotificationServiceProvider)
      // when first read by any widget. No standalone initialization needed here.

      runApp(const ProviderScope(child: GrowthOSApp()));
    },
    (error, stack) {
      unawaited(LocalErrorLogService.record(error, stack, source: 'zone'));
    },
  );
}

class _GrowthOSErrorWidget extends StatelessWidget {
  const _GrowthOSErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF8F3),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF5A3A32), size: 32),
              const SizedBox(height: 12),
              const Text(
                '页面渲染出错',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5A3A32),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode
                    ? '${details.exception}\n\n${details.stack ?? ""}'
                    : '此页面遇到了渲染问题，请尝试重启应用。',
                textAlign: TextAlign.center,
                maxLines: kDebugMode ? 20 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF5A3A32).withValues(alpha: 0.7),
                  fontSize: kDebugMode ? 11 : 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}