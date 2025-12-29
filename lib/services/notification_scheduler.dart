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
    print('🔔 [NotificationScheduler] Initializing...');
    if (_initialized) {
      print('🔔 [NotificationScheduler] Already initialized');
      return;
    }

    try {
      // Initialize timezone data
      print('🔔 [NotificationScheduler] Initializing timezones...');
      tz.initializeTimeZones();
      // Set local timezone to Asia/Jakarta (WIB)
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      print(
        '🔔 [NotificationScheduler] Timezones initialized - Local: ${tz.local.name}',
      );

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      print(
        '🔔 [NotificationScheduler] Initializing flutter_local_notifications...',
      );
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      print(
        '🔔 [NotificationScheduler] flutter_local_notifications initialized',
      );

      // Create notification channel for Android
      print('🔔 [NotificationScheduler] Creating notification channel...');
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'task_reminders', // id
        'Task Reminders', // name
        description: 'Reminders for upcoming tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('✅ [NotificationScheduler] Notification channel created');
      }

      // Request permission for Android 13+
      print('🔔 [NotificationScheduler] Requesting permissions...');
      final granted = await androidPlugin?.requestNotificationsPermission();
      print('🔔 [NotificationScheduler] Permissions granted: $granted');

      // Request exact alarm permission for Android 12+ (S and above)
      print('🔔 [NotificationScheduler] Requesting exact alarm permission...');
      final canScheduleExact = await androidPlugin
          ?.canScheduleExactNotifications();
      print(
        '🔔 [NotificationScheduler] Can schedule exact alarms: $canScheduleExact',
      );

      if (canScheduleExact == false) {
        print('⚠️ [NotificationScheduler] Exact alarm permission not granted!');
        print(
          '📌 User needs to enable "Alarms & reminders" in Android Settings',
        );
        // Note: Can't request this permission programmatically on Android 12+
        // User must enable it manually in Settings > Apps > CleanHNote > Alarms & reminders
      }

      _initialized = true;
      print('✅ [NotificationScheduler] Initialization complete!');
    } catch (e, stackTrace) {
      print('❌ [NotificationScheduler] Initialization failed: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to task detail screen
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> scheduleTaskReminders({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
    String? dueTime,
  }) async {
    print('📅 [NotificationScheduler] Scheduling reminders for: $taskTitle');
    print('📅 Task ID: $taskId');
    print('📅 Due Date: $dueDate');
    print('📅 Due Time: $dueTime');

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

    print('🕐 Target datetime: $dueDateTime');
    print('🕐 Current time: ${DateTime.now()}');

    // Define reminder intervals (in minutes before due time)
    final intervals = [120, 90, 60, 30, 20, 10]; // 2h, 1.5h, 1h, 30m, 20m, 10m

    int scheduledCount = 0;
    for (var i = 0; i < intervals.length; i++) {
      final minutesBefore = intervals[i];
      final reminderTime = dueDateTime.subtract(
        Duration(minutes: minutesBefore),
      );

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        final notificationId = _generateNotificationId(taskId, i);
        try {
          await _scheduleNotification(
            id: notificationId,
            title: 'Task Reminder',
            body: '$taskTitle - Due in ${_formatDuration(minutesBefore)}',
            scheduledTime: reminderTime,
            payload: taskId,
          );
          print(
            '✅ Scheduled notification $minutesBefore min before at $reminderTime',
          );
          scheduledCount++;
        } catch (e) {
          print('❌ Failed to schedule notification: $e');
        }
      } else {
        print(
          '⏭️ Skipped notification $minutesBefore min before (time already passed)',
        );
      }
    }

    print(
      '📊 Total notifications scheduled: $scheduledCount/${intervals.length}',
    );
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    print('⏰ [Schedule] ID: $id, Time: $scheduledTime');

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      print('⏰ TZ Scheduled Time: $tzScheduledTime (${tz.local.name})');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('✅ [Schedule] Notification queued successfully!');
    } catch (e, stackTrace) {
      print('❌ [Schedule] Failed: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Cancel all notifications for a task
  static Future<void> cancelTaskReminders(String taskId) async {
    try {
      for (var i = 0; i < 6; i++) {
        final notificationId = _generateNotificationId(taskId, i);
        await _notifications.cancel(notificationId);
      }
    } catch (e) {
      // Silently fail - notifications will auto-clear anyway
      // This prevents crashes from flutter_local_notifications plugin issues
      print('⚠️ Could not cancel notifications for task $taskId: $e');
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
    print('🔔 [TEST] Showing immediate notification...');
    print('Title: $title');
    print('Body: $body');

    try {
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

      print('✅ [TEST] Notification shown successfully!');
    } catch (e, stackTrace) {
      print('❌ [TEST] Failed to show notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send test notification (for user testing)
  static Future<void> sendTestNotification() async {
    await showImmediateNotification(
      title: 'Test Notification',
      body: 'If you see this, notifications are working! 🎉',
    );
  }

  /// Test scheduled notification (30 seconds from now)
  static Future<void> testScheduledNotification() async {
    print('🧪 [DEBUG] Scheduling test notification 30 seconds from now...');

    await initialize();

    final scheduledTime = DateTime.now().add(const Duration(seconds: 30));
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    print('🧪 Current time: ${DateTime.now()}');
    print('🧪 Will trigger at: $scheduledTime');
    print('🧪 TZ time: $tzScheduledTime');

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        999999, // unique test ID
        '🧪 Test Scheduled Notification',
        'This should appear in 30 seconds!',
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ [DEBUG] Test notification scheduled successfully!');
      print('⏰ Wait 30 seconds to see if it appears...');
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Failed to schedule: $e');
      print('Stack: $stackTrace');
    }
  }

  /// Check pending scheduled notifications (for debugging)
  static Future<void> checkPendingNotifications() async {
    print('🔍 [DEBUG] Checking pending notifications...');

    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Total pending notifications: ${pending.length}');

      if (pending.isEmpty) {
        print('⚠️ No pending notifications found!');
        print('💡 This means notifications are not being scheduled properly.');
      } else {
        for (var notif in pending) {
          print(
            '  - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}',
          );
        }
      }
    } catch (e) {
      print('❌ Failed to get pending notifications: $e');
    }
  }

  /// Cancel all pending notifications (for cleanup)
  static Future<void> cancelAllPendingNotifications() async {
    print('🗑️ [DEBUG] Cancelling all pending notifications...');

    try {
      await _notifications.cancelAll();
      print('✅ All pending notifications cancelled!');
    } catch (e) {
      print('❌ Failed to cancel notifications: $e');
    }
  }
}
