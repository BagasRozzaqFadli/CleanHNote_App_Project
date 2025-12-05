import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_options.dart';
import 'notification_history_service.dart';
import 'notification_scheduler.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("👷 [BackgroundWorker] Executing background task: $task");

    try {
      // 1. Initialize Firebase
      // checks if already initialized to avoid errors
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print("✅ [BackgroundWorker] Firebase initialized");
      }

      // 2. Check for notifications

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠️ [BackgroundWorker] No user logged in, skipping check");
        return Future.value(true);
      }

      print("👤 [BackgroundWorker] Checking for user: ${user.uid}");

      final historyService = NotificationHistoryService();
      final prefs = await SharedPreferences.getInstance();
      final deliveredIds = prefs.getStringList('delivered_notifications') ?? [];

      // Get pending notifications
      final pending = await historyService.getPendingNotifications(user.uid);

      if (pending.isEmpty) {
        print("✓ [BackgroundWorker] No pending notifications found");
        return Future.value(true);
      }

      print(
        "📬 [BackgroundWorker] Found ${pending.length} pending notification(s)",
      );

      int postedCount = 0;

      // Show notifications
      for (var notification in pending) {
        // Skip if already delivered by background worker
        if (deliveredIds.contains(notification.id)) {
          continue;
        }

        // Show immediate notification
        await NotificationScheduler.showImmediateNotification(
          title: 'Task Reminder',
          body:
              '${notification.taskTitle} - Due in ${notification.notificationType}',
        );

        // Add to delivered list
        deliveredIds.add(notification.id);
        postedCount++;
        print(
          "✅ [BackgroundWorker] Shown: ${notification.taskTitle} (${notification.notificationType})",
        );
      }

      // Save updated list
      if (postedCount > 0) {
        // Prune list if too large (keep last 100)
        if (deliveredIds.length > 100) {
          // simple removal of first few
          final start = deliveredIds.length - 100;
          final newIds = deliveredIds.sublist(start);
          await prefs.setStringList('delivered_notifications', newIds);
        } else {
          await prefs.setStringList('delivered_notifications', deliveredIds);
        }
        print("💾 [BackgroundWorker] Saved delivered IDs");
      } else {
        print(
          "⏭️ [BackgroundWorker] All pending notifications already delivered",
        );
      }
    } catch (e, stack) {
      print("❌ [BackgroundWorker] Error: $e");
      print(stack);
      return Future.value(false); // Valid retry
    }

    return Future.value(true);
  });
}
