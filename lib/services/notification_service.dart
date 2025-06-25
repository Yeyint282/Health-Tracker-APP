import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz; // ✅ FIXED: use latest_all
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones(); // ✅ Load full timezone data

    String? deviceTimeZoneName;
    try {
      deviceTimeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimeZoneName));
      debugPrint(
          'NotificationService: Timezone set to device local: $deviceTimeZoneName');
      debugPrint(
          'NotificationService: Verified tz.local name: ${tz.local.name}');
      debugPrint(
          'NotificationService: Verified tz.local offset: ${tz.local.currentTimeZone.offset ~/ (1000 * 60 * 60)} hours');
    } catch (e) {
      debugPrint(
          'NotificationService: Error setting timezone ($deviceTimeZoneName): $e');
      debugPrint('NotificationService: Attempting fallback to Asia/Yangon...');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Yangon'));
        debugPrint('NotificationService: Fallback to Asia/Yangon succeeded.');
      } catch (e2) {
        debugPrint(
            'NotificationService: Asia/Yangon failed, trying Asia/Rangoon...');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Rangoon'));
          debugPrint(
              'NotificationService: Fallback to Asia/Rangoon succeeded.');
        } catch (e3) {
          debugPrint(
              'NotificationService: All time zone fallbacks failed. Falling back to UTC.');
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }

      debugPrint('NotificationService: Final tz.local: ${tz.local.name}');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
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
      debugPrint(
          'NotificationService: Notification tapped with payload: ${response.payload}');
    }
    // You can handle navigation or logic based on payload here.
  }

  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      if (!granted)
        debugPrint('NotificationService: Android permission not granted.');
      return granted;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
      if (!granted)
        debugPrint('NotificationService: iOS permission not granted.');
      return granted;
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
    debugPrint('NotificationService: Instant notification shown (ID: $id)');
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool daily = false,
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

    final tz.TZDateTime finalScheduledTZDateTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    debugPrint('*** NotificationService: Scheduling Attempt ***');
    debugPrint('ID: $id');
    debugPrint('Title: $title');
    debugPrint('Body: $body');
    debugPrint('Raw scheduledTime (DateTime): $scheduledTime');
    debugPrint(
        'Final TZDateTime to schedule (tz.local): $finalScheduledTZDateTime');
    debugPrint('Is TZDateTime UTC: ${finalScheduledTZDateTime.isUtc}');
    debugPrint(
        'TZDateTime Timezone name: ${finalScheduledTZDateTime.location.name}');
    debugPrint(
        'TZDateTime Timezone offset: ${finalScheduledTZDateTime.location.currentTimeZone.offset ~/ (1000 * 60 * 60)} hours');

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        finalScheduledTZDateTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      );
      debugPrint(
          'NotificationService: Notification successfully scheduled (ID: $id)');
    } catch (e) {
      debugPrint(
          'NotificationService: Error scheduling notification (ID: $id): $e');
    }
  }

  static Future<void> scheduleDailyActivityNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
    String? payload,
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

    debugPrint(
        'NotificationService: Computed daily scheduledDate: $scheduledDate (for ID: $id)');
    debugPrint(
        'NotificationService: Is this date in the past? ${scheduledDate.isBefore(now)}');

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      payload: payload,
      daily: true,
    );
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('NotificationService: Notification cancelled (ID: $id)');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('NotificationService: All notifications cancelled');
  }
}
