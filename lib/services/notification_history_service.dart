import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_history_model.dart';

/// Service for managing notification history in Firestore
class NotificationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxNotificationsPerUser = 10;

  /// Create notification history entry
  Future<String> createNotificationHistory(
    NotificationHistoryModel notification,
  ) async {
    try {
      final docRef = await _firestore
          .collection('notification_history')
          .add(notification.toFirestore());

      // Enforce 10-notification limit after creating
      await _enforceLimit(notification.userId);

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's notifications as stream (last 10, ordered by scheduled time DESC)
  Stream<List<NotificationHistoryModel>> getMyNotifications(String userId) {
    return _firestore
        .collection('notification_history')
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledFor', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationHistoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  ///Get count of unshown notifications (for badge) - only those that should be visible
  Stream<int> getUnshownCount(String userId) {
    return _firestore
        .collection('notification_history')
        .where('userId', isEqualTo: userId)
        .where('shown', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          // Filter to only count notifications where scheduledFor has passed
          final now = DateTime.now();

          print(
            '🔍 [Badge Debug] Total unshown notifications: ${snapshot.docs.length}',
          );

          final validNotifications = snapshot.docs
              .map((doc) => NotificationHistoryModel.fromFirestore(doc))
              .where((notif) {
                final isPast = notif.scheduledFor.isBefore(now);
                print('  📋 ${notif.taskTitle} (${notif.notificationType}):');
                print('     scheduledFor: ${notif.scheduledFor}');
                print('     now: $now');
                print('     isPast: $isPast');
                return isPast;
              })
              .toList();

          final count = validNotifications.length;
          print('🔴 [Badge Count] = $count');

          return count;
        });
  }

  /// Get pending notifications (not shown yet, scheduled time passed)
  Future<List<NotificationHistoryModel>> getPendingNotifications(
    String userId,
  ) async {
    final now = DateTime.now();

    final snapshot = await _firestore
        .collection('notification_history')
        .where('userId', isEqualTo: userId)
        .where('shown', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => NotificationHistoryModel.fromFirestore(doc))
        .where((notif) => notif.scheduledFor.isBefore(now))
        .toList();
  }

  /// Mark notification as shown
  Future<void> markAsShown(String notificationId) async {
    try {
      await _firestore
          .collection('notification_history')
          .doc(notificationId)
          .update({
            'shown': true,
            'shownAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete single notification by ID
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notification_history')
          .doc(notificationId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all visible notifications for a user (only those where scheduledFor has passed)
  Future<int> deleteAllNotifications(String userId) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: userId)
          .get();

      int deleted = 0;
      for (var doc in snapshot.docs) {
        final notification = NotificationHistoryModel.fromFirestore(doc);
        // Only delete if scheduled time has passed (i.e., notification is visible)
        if (notification.scheduledFor.isBefore(now)) {
          await doc.reference.delete();
          deleted++;
        }
      }

      return deleted;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete old notifications (10+ days after scheduled time)
  Future<int> deleteOldNotifications(String userId) async {
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 10));

      final snapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: userId)
          .where('scheduledFor', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deleted = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        deleted++;
      }

      return deleted;
    } catch (e) {
      rethrow;
    }
  }

  /// Enforce 10-notification limit (delete oldest if exceeded)
  Future<void> _enforceLimit(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.length > maxNotificationsPerUser) {
        // Delete excess (oldest) notifications
        final toDelete = snapshot.docs.skip(maxNotificationsPerUser).toList();
        for (var doc in toDelete) {
          await doc.reference.delete();
        }
        print(
          '🗑️ Deleted ${toDelete.length} old notifications to enforce limit',
        );
      }
    } catch (e) {
      print('⚠️ Failed to enforce notification limit: $e');
    }
  }

  /// Delete all notifications for a task (e.g., when task is deleted/completed)
  Future<void> deleteNotificationsForTask(String taskId) async {
    try {
      final snapshot = await _firestore
          .collection('notification_history')
          .where('taskId', isEqualTo: taskId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('⚠️ Failed to delete task notifications: $e');
    }
  }

  /// Batch create notification histories for a task
  Future<void> createTaskNotifications({
    required String userId,
    required String taskId,
    required String taskTitle,
    required DateTime dueDateTime,
    String? teamId,
    String? assignmentId,
  }) async {
    final now = DateTime.now();

    // Define intervals: 2h, 1.5h, 1h, 30m, 20m, 10m before due
    final intervals = [
      {'minutes': 120, 'type': '2h'},
      {'minutes': 90, 'type': '1.5h'},
      {'minutes': 60, 'type': '1h'},
      {'minutes': 30, 'type': '30min'},
      {'minutes': 20, 'type': '20min'},
      {'minutes': 10, 'type': '10min'},
    ];

    for (var interval in intervals) {
      final scheduledFor = dueDateTime.subtract(
        Duration(minutes: interval['minutes'] as int),
      );

      // Only create if scheduled time is in the future
      if (scheduledFor.isAfter(now)) {
        final notification = NotificationHistoryModel(
          id: '', // Will be generated by Firestore
          userId: userId,
          taskId: taskId,
          taskTitle: taskTitle,
          notificationType: interval['type'] as String,
          scheduledFor: scheduledFor,
          createdAt: DateTime.now(),
          shown: false,
          teamId: teamId,
          assignmentId: assignmentId,
        );

        await createNotificationHistory(notification);
      }
    }

    print('✅ Created notification histories for task: $taskTitle');
  }
}
