import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_history_service.dart';
import '../services/notification_scheduler.dart';

/// Background notification checker
/// Runs timer to check for pending notifications and show them
class NotificationChecker {
  static final NotificationChecker _instance = NotificationChecker._internal();
  factory NotificationChecker() => _instance;
  NotificationChecker._internal();

  final NotificationHistoryService _historyService =
      NotificationHistoryService();
  Timer? _timer;
  bool _isRunning = false;

  // Track notification IDs that have been shown in this session
  // Prevents duplicate notifications while keeping shown=false for badge
  final Set<String> _shownInSession = {};

  /// Start the notification checker
  /// Checks every 60 seconds for pending notifications
  void start() {
    if (_isRunning) {
      print('⏰ NotificationChecker already running');
      return;
    }

    print('🚀 Starting NotificationChecker...');
    _isRunning = true;

    // Check immediately on start
    _checkAndShowNotifications();

    // Then check every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkAndShowNotifications();
    });

    print('✅ NotificationChecker started (10s interval)');
  }

  /// Stop the notification checker
  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _isRunning = false;
      print('⏹️ NotificationChecker stopped');
    }
  }

  /// Check for pending notifications and show them
  Future<void> _checkAndShowNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get pending notifications (not shown, time passed)
      final pending = await _historyService.getPendingNotifications(user.uid);

      if (pending.isEmpty) {
        // print('✓ No pending notifications');
        return;
      }

      print('📬 Found ${pending.length} pending notification(s)');

      for (var notification in pending) {
        // Skip if already shown in this session
        if (_shownInSession.contains(notification.id)) {
          continue;
        }

        // Show immediate notification
        await NotificationScheduler.showImmediateNotification(
          title: 'Task Reminder',
          body:
              '${notification.taskTitle} - Due in ${notification.notificationType}',
        );

        // Add to session tracking (prevents duplicate notifications)
        _shownInSession.add(notification.id);

        // DON'T mark as shown in Firestore yet! Badge should appear until user opens notification screen
        // User will mark it as shown when they tap notification in the list

        print(
          '✅ Showed notification: ${notification.taskTitle} (${notification.notificationType})',
        );
      }

      // Cleanup old notifications (30+ days)
      final deleted = await _historyService.deleteOldNotifications(user.uid);
      if (deleted > 0) {
        print('🗑️ Cleaned up $deleted old notification(s)');
      }
    } catch (e) {
      print('❌ NotificationChecker error: $e');
    }
  }

  /// Manual trigger for testing
  Future<void> checkNow() async {
    print('🔄 Manual notification check triggered');
    await _checkAndShowNotifications();
  }
}
