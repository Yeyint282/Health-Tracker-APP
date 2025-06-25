import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    String? deviceTimeZoneName;
    try {
      deviceTimeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimeZoneName));
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Yangon'));
      } catch (e2) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      debugPrint('Notification tapped with payload: ${response.payload}');
    }
  }

  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'health_tracker_channel',
      'Health Tracker Notifications',
      channelDescription: 'Notifications for health tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notifications.show(id, title, body, notificationDetails,
        payload: payload);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool daily = false,
    String notificationType = 'notification',
  }) async {
    NotificationDetails notificationDetails;

    if (notificationType == 'alarm') {
      const androidAlarmDetails = AndroidNotificationDetails(
        'health_tracker_alarm_channel',
        'Health Tracker Alarms',
        channelDescription: 'High-priority alerts for medication alarms',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        enableVibration: true,
      );
      const iosAlarmDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      notificationDetails = NotificationDetails(
        android: androidAlarmDetails,
        iOS: iosAlarmDetails,
      );
    } else {
      const androidDetails = AndroidNotificationDetails(
        'health_tracker_channel',
        'Health Tracker Notifications',
        channelDescription: 'Notifications for health tracking reminders',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    }

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
    );
  }

  static Future<void> scheduleDailyActivityNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
    String? payload,
    String notificationType = 'notification',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      payload: payload,
      daily: true,
      notificationType: notificationType,
    );
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
