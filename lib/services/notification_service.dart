import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Service for managing notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      // Silently fail - notifications are not critical
      print('Failed to create notification: $e');
    }
  }

  /// Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          // Sort on client side to avoid index requirement
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  /// Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll(String userId) async {
    try {
      final batch = _firestore.batch();
      final userNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in userNotifs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Failed to clear notifications: $e');
    }
  }

  // ==================== Helper Methods to Create Specific Notifications ====================

  /// Create maintenance notification
  Future<void> notifyMaintenance(
    String userId,
    int deletedTasks,
    int prunedImages,
  ) async {
    if (deletedTasks == 0 && prunedImages == 0) return;

    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'maintenance',
      title: 'Auto-Maintenance Completed',
      message:
          'Deleted $deletedTasks old tasks and pruned $prunedImages images.',
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Create task assigned notification
  Future<void> notifyTaskAssigned(
    String userId,
    String taskTitle,
    String teamName,
  ) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'task_assigned',
      title: 'New Task Assigned',
      message: 'You have been assigned "$taskTitle" in $teamName',
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Create team joined notification
  Future<void> notifyTeamJoined(String userId, String teamName) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'team_joined',
      title: 'Joined Team',
      message: 'You successfully joined $teamName',
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// Create role changed notification
  Future<void> notifyRoleChanged(String userId, String newRole) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'role_changed',
      title: 'Role Updated',
      message: 'Your account has been upgraded to $newRole',
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }
}
