import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notification tap callback — set by the app to handle navigation.
typedef NotificationTapCallback = void Function(String? payload);

final reminderNotificationServiceProvider =
    Provider<ReminderNotificationService>((ref) {
      final service = ReminderNotificationService();
      // Auto-initialize when first read
      service.initialize();
      ref.onDispose(() => service.dispose());
      return service;
    });

class ReminderNotificationService {
  ReminderNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  Future<bool>? _initFuture;

  /// Callback invoked when user taps a notification.
  NotificationTapCallback? onTap;

  /// Initialize the notification plugin with the device's local timezone.
  ///
  /// Safe to call multiple times — only initializes once.
  Future<bool> initialize({NotificationTapCallback? onNotificationTap}) async {
    if (_initialized) return true;
    if (_initFuture != null) return _initFuture!;

    _initFuture = _doInitialize(onNotificationTap);
    return _initFuture!;
  }

  Future<bool> _doInitialize(NotificationTapCallback? onNotificationTap) async {
    try {
      onTap = onNotificationTap;

      // Initialize timezone with device's actual timezone
      tz_data.initializeTimeZones();
      try {
        final offsetHours = DateTime.now().timeZoneOffset.inHours;
        final tzName = _findTimezoneByOffset(offsetHours);
        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint('[NotificationService] Timezone: $tzName (UTC+$offsetHours)');
      } catch (e) {
        debugPrint('[NotificationService] Timezone detection failed, using UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );
      _initialized = true;
      debugPrint('[NotificationService] Initialized successfully');
      return true;
    } catch (e) {
      _initFuture = null;
      debugPrint('[NotificationService] Initialize failed: $e');
      return false;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    onTap?.call(response.payload);
  }

  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] Background notification tapped: ${response.payload}');
  }

  /// Request notification permissions (Android 13+, iOS, macOS).
  Future<bool> requestPermissions() async {
    final ready = await initialize();
    if (!ready) return false;
    var granted = true;
    try {
      if (Platform.isAndroid) {
        final androidGranted = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        if (androidGranted != null) granted = granted && androidGranted;
      }

      if (Platform.isIOS) {
        final iosGranted = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        if (iosGranted != null) granted = granted && iosGranted;
      }

      if (Platform.isMacOS) {
        final macGranted = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        if (macGranted != null) granted = granted && macGranted;
      }

      debugPrint('[NotificationService] Permissions granted: $granted');
    } catch (e) {
      debugPrint('[NotificationService] Permission request failed: $e');
      return false;
    }
    return granted;
  }

  /// Schedule a one-shot reminder at [scheduledAt].
  Future<bool> scheduleReminder({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? payload,
  }) async {
    final ready = await initialize();
    if (!ready) return false;
    try {
      final tzDateTime = tz.TZDateTime.from(scheduledAt, tz.local);
      debugPrint('[NotificationService] Scheduling #$id at $tzDateTime (local: ${tz.local})');

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'growth_os_reminders',
            'Growth OS Reminders',
            channelDescription: 'Timer and reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('[NotificationService] Scheduled #$id successfully');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Schedule failed for #$id: $e');
      return false;
    }
  }

  /// Show an immediate notification (e.g., focus/fitness completion).
  Future<bool> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final ready = await initialize();
    if (!ready) return false;
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'growth_os_instant',
            'Growth OS Instant',
            channelDescription: 'Instant notifications for task completion',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
      debugPrint('[NotificationService] Showed immediate #$id');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Show immediate failed for #$id: $e');
      return false;
    }
  }

  /// Cancel a scheduled notification by ID.
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('[NotificationService] Cancelled #$id');
    } catch (e) {
      debugPrint('[NotificationService] Cancel failed for #$id: $e');
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('[NotificationService] Cancelled all notifications');
    } catch (e) {
      debugPrint('[NotificationService] CancelAll failed: $e');
    }
  }

  /// Find timezone name by UTC offset hours.
  /// Prioritizes Asia/Shanghai for UTC+8 (China target audience).
  String _findTimezoneByOffset(int offsetHours) {
    const offsetToTz = <int, String>{
      -5: 'America/New_York',
      -6: 'America/Chicago',
      -7: 'America/Denver',
      -8: 'America/Los_Angeles',
      0: 'Europe/London',
      1: 'Europe/Paris',
      2: 'Europe/Berlin',
      3: 'Europe/Moscow',
      5: 'Asia/Kolkata',
      7: 'Asia/Bangkok',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
    };
    return offsetToTz[offsetHours] ?? 'Asia/Shanghai';
  }

  void dispose() {
    _initFuture = null;
  }
}
