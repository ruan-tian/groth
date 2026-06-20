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
      service.initialize(onNotificationTap: (payload) {
        debugPrint('[NotificationService] Tapped: $payload');
      });
      ref.onDispose(() => service.dispose());
      return service;
    });

abstract class ReminderNotificationGateway {
  Future<bool> requestPermissions({bool requestExactAlarm = false});

  Future<bool> areNotificationsEnabled();

  Future<bool> canScheduleExactAlarms();

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  Future<int> pendingCountWhere(bool Function(int id) test);

  Future<bool> hasPendingNotification(int id);

  Future<bool> scheduleReminder({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? payload,
    bool requestPermissionsIfNeeded = true,
    DateTimeComponents? matchDateTimeComponents,
  });

  Future<bool> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  Future<bool> showTestNotification();

  Future<bool> scheduleTestReminder({
    Duration delay = const Duration(minutes: 1),
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();
}

class ReminderNotificationService implements ReminderNotificationGateway {
  ReminderNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  Future<bool>? _initFuture;

  static const _darwinNotificationDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    presentBanner: true,
    presentList: true,
  );

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
        debugPrint(
          '[NotificationService] Timezone: $tzName (UTC+$offsetHours)',
        );
      } catch (e) {
        debugPrint(
          '[NotificationService] Timezone detection failed, using UTC: $e',
        );
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

      // 显式创建通知渠道（确保 Android 8+ 渠道存在）
      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              'growth_os_reminders',
              'Growth OS Reminders',
              description: '定时提醒通知',
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              'growth_os_instant',
              'Growth OS Instant',
              description: '即时通知（任务完成等）',
              importance: Importance.high,
            ),
          );
        }
      }

      debugPrint('[NotificationService] Initialized successfully');
      return true;
    } catch (e) {
      _initFuture = null;
      debugPrint('[NotificationService] Initialize failed: $e');
      return false;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Notification tapped: ${response.payload}',
    );
    onTap?.call(response.payload);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Background notification tapped: ${response.payload}',
    );
  }

  /// Request notification permissions (Android 13+, iOS, macOS).
  ///
  /// Exact alarm permission is best-effort. Scheduled reminders fall back to
  /// inexact alarms when Android does not grant exact alarm access.
  @override
  Future<bool> requestPermissions({bool requestExactAlarm = false}) async {
    final ready = await initialize();
    if (!ready) return false;
    var granted = true;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl != null) {
          final notifGranted = await androidImpl
              .requestNotificationsPermission();
          if (notifGranted != null) granted = granted && notifGranted;

          // 精确闹钟权限（Android 12+ 需要用户授权）
          if (granted && requestExactAlarm) {
            final canScheduleExact = await androidImpl
                .canScheduleExactNotifications();
            debugPrint(
              '[NotificationService] Can schedule exact: $canScheduleExact',
            );
            if (canScheduleExact == false) {
              final exactGranted = await androidImpl
                  .requestExactAlarmsPermission();
              debugPrint(
                '[NotificationService] Exact alarm permission: $exactGranted',
              );
              if (exactGranted == false) {
                debugPrint(
                  '[NotificationService] Exact alarm denied; '
                  'scheduled reminders will use inexact alarms',
                );
              }
            }
          }
        }
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

  @override
  Future<bool> areNotificationsEnabled() async {
    final ready = await initialize();
    if (!ready) return false;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      }
    } catch (e) {
      debugPrint('[NotificationService] Notification status check failed: $e');
    }
    return true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    final ready = await initialize();
    if (!ready) return false;
    return _canScheduleExactNotifications();
  }

  Future<bool> _canScheduleExactNotifications() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImpl?.canScheduleExactNotifications() ?? true;
    } catch (e) {
      debugPrint('[NotificationService] Exact alarm status check failed: $e');
      return false;
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final canScheduleExact = await _canScheduleExactNotifications();
    if (canScheduleExact) return AndroidScheduleMode.exactAllowWhileIdle;
    debugPrint('[NotificationService] Falling back to inexactAllowWhileIdle');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Schedule a one-shot reminder at [scheduledAt].
  ///
  /// Uses exact scheduling when allowed. On Android 12+/14+ devices without
  /// exact alarm access, falls back to an inexact allow-while-idle alarm.
  @override
  Future<bool> scheduleReminder({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? payload,
    bool requestPermissionsIfNeeded = true,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final ready = await initialize();
    if (!ready) return false;
    try {
      final notificationsGranted = requestPermissionsIfNeeded
          ? await requestPermissions(requestExactAlarm: true)
          : await areNotificationsEnabled();
      if (!notificationsGranted) {
        debugPrint(
          '[NotificationService] Schedule skipped; notifications denied',
        );
        return false;
      }

      final androidScheduleMode = await _androidScheduleMode();
      final tzDateTime = tz.TZDateTime.from(scheduledAt, tz.local);
      debugPrint(
        '[NotificationService] Scheduling #$id at $tzDateTime '
        '(local: ${tz.local}, androidMode: $androidScheduleMode)',
      );

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
          iOS: _darwinNotificationDetails,
          macOS: _darwinNotificationDetails,
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
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
  @override
  Future<bool> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final ready = await initialize();
    if (!ready) return false;
    try {
      final notificationsGranted = await requestPermissions(
        requestExactAlarm: false,
      );
      if (!notificationsGranted) {
        debugPrint(
          '[NotificationService] Immediate notification skipped; '
          'notifications denied',
        );
        return false;
      }

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
          iOS: _darwinNotificationDetails,
          macOS: _darwinNotificationDetails,
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

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    final ready = await initialize();
    if (!ready) return const [];
    try {
      return _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('[NotificationService] Pending notification check failed: $e');
      return const [];
    }
  }

  @override
  Future<int> pendingCountWhere(bool Function(int id) test) async {
    final pending = await pendingNotificationRequests();
    return pending.where((request) => test(request.id)).length;
  }

  @override
  Future<bool> hasPendingNotification(int id) async {
    final pending = await pendingNotificationRequests();
    return pending.any((request) => request.id == id);
  }

  @override
  Future<bool> showTestNotification() {
    return showImmediate(
      id: 529998,
      title: 'Reminder test',
      body: 'Immediate notification is working.',
      payload: 'health_reminder_test_now',
    );
  }

  @override
  Future<bool> scheduleTestReminder({
    Duration delay = const Duration(minutes: 1),
  }) {
    return scheduleReminder(
      id: 529999,
      scheduledAt: DateTime.now().add(delay),
      title: 'Reminder test',
      body: 'Scheduled reminder is working.',
      payload: 'health_reminder_test_later',
      requestPermissionsIfNeeded: true,
    );
  }

  /// Cancel a scheduled notification by ID.
  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('[NotificationService] Cancelled #$id');
    } catch (e) {
      debugPrint('[NotificationService] Cancel failed for #$id: $e');
    }
  }

  /// Cancel all scheduled notifications.
  @override
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
