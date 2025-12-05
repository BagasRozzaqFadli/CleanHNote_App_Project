import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for handling local scheduled notifications
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to task detail screen if needed
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule a task reminder notification (1-2 hours before due time)
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDateTime,
  }) async {
    if (!_initialized) await initialize();

    // Calculate notification time (2 hours before, or 1 hour if less than 2 hours away)
    final now = DateTime.now();
    final timeUntilDue = dueDateTime.difference(now);

    DateTime notificationTime;
    if (timeUntilDue.inHours >= 2) {
      notificationTime = dueDateTime.subtract(const Duration(hours: 2));
    } else if (timeUntilDue.inHours >= 1) {
      notificationTime = dueDateTime.subtract(const Duration(hours: 1));
    } else {
      // If less than 1 hour away, don't schedule
      return;
    }

    // Don't schedule if notification time is in the past
    if (notificationTime.isBefore(now)) return;

    final notificationId = _getNotificationId(taskId);

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '⏰ Task Reminder',
      'Task "$title" is due soon!',
      tz.TZDateTime.from(notificationTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId,
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String taskId) async {
    final notificationId = _getNotificationId(taskId);
    await _notifications.cancel(notificationId);
  }

  /// Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Convert task ID to notification ID (simple hash)
  int _getNotificationId(String taskId) {
    return taskId.hashCode % 2147483647; // Max int32
  }
}
