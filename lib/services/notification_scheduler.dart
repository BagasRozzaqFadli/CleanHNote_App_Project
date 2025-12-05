import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service for scheduling Android local notifications
class NotificationScheduler {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize the notification system
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permission for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to task detail screen
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule task reminders
  /// Schedules 6 notifications: 2h, 1.5h, 1h, 30m, 20m, 10m before due time
  static Future<void> scheduleTaskReminders({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
    String? dueTime,
  }) async {
    await initialize();

    // Parse due time or use end of day
    DateTime dueDateTime;
    if (dueTime != null && dueTime.isNotEmpty) {
      final timeParts = dueTime.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 23;
        final minute = int.tryParse(timeParts[1]) ?? 59;
        dueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
      } else {
        dueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          23,
          59,
        );
      }
    } else {
      dueDateTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59);
    }

    // Define reminder intervals (in minutes before due time)
    final intervals = [120, 90, 60, 30, 20, 10]; // 2h, 1.5h, 1h, 30m, 20m, 10m

    for (var i = 0; i < intervals.length; i++) {
      final minutesBefore = intervals[i];
      final reminderTime = dueDateTime.subtract(
        Duration(minutes: minutesBefore),
      );

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        final notificationId = _generateNotificationId(taskId, i);
        await _scheduleNotification(
          id: notificationId,
          title: 'Task Reminder',
          body: '$taskTitle - Due in ${_formatDuration(minutesBefore)}',
          scheduledTime: reminderTime,
          payload: taskId,
        );
      }
    }
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel all notifications for a task
  static Future<void> cancelTaskReminders(String taskId) async {
    for (var i = 0; i < 6; i++) {
      final notificationId = _generateNotificationId(taskId, i);
      await _notifications.cancel(notificationId);
    }
  }

  /// Generate unique notification ID from task ID and index
  static int _generateNotificationId(String taskId, int index) {
    // Use hash code of taskId + index to generate unique int ID
    final combined = '$taskId-$index';
    return combined.hashCode.abs() % 2147483647; // Max int32 value
  }

  /// Format duration for display
  static String _formatDuration(int minutes) {
    if (minutes >= 120) {
      return '${minutes ~/ 60} hours';
    } else if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours hours $mins minutes' : '$hours hour';
    } else {
      return '$minutes minutes';
    }
  }

  /// Show immediate notification (for testing)
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
    );
  }

  /// Send test notification (for user testing)
  static Future<void> sendTestNotification() async {
    await showImmediateNotification(
      title: '✅ Notification Test',
      body: 'Notifications are working! Your reminders will appear like this.',
    );
  }
}
