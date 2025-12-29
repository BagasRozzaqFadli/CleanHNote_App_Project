import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_history_service.dart';
import '../models/notification_history_model.dart';
import '../models/task_model.dart';
import '../models/team_assignment_model.dart';
import '../widgets/realtime_countdown_widget.dart';
import 'personal_task_detail_screen.dart';
import 'team_task_detail_screen.dart';

/// Screen to display notification history
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    final notificationService = NotificationHistoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Notifications?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  final count = await notificationService
                      .deleteAllNotifications(user.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$count notification${count == 1 ? '' : 's'} deleted',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationHistoryModel>>(
        stream: notificationService.getMyNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // DEBUG: Log raw data from Firestore
          print(
            '🔍 [NotificationsScreen] Raw data count: ${snapshot.data?.length ?? 0}',
          );
          if (snapshot.data != null) {
            for (var notif in snapshot.data!) {
              print('  📋 ${notif.notificationType}: ${notif.taskTitle}');
              print('     scheduledFor: ${notif.scheduledFor}');
              print('     now: ${DateTime.now()}');
            }
          }

          // Filter notifications:
          // 1. Show "assigned" notifications immediately (even if just created)
          // 2. Show reminder notifications only after scheduled time has passed
          final notifications = (snapshot.data ?? []).where((notif) {
            // Always show assignment notifications
            if (notif.notificationType == 'assigned') {
              print('  ✅ Including assigned: ${notif.taskTitle}');
              return true;
            }
            // Show other notifications only if scheduled time has passed
            final shouldShow = notif.scheduledFor.isBefore(DateTime.now());
            print(
              '  ${shouldShow ? "✅" : "❌"} ${notif.notificationType}: ${notif.taskTitle} (shouldShow: $shouldShow)',
            );
            return shouldShow;
          }).toList();

          print(
            '🎯 [NotificationsScreen] Filtered count: ${notifications.length}',
          );

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(notifications);

          return Column(
            children: [
              // Swipe hint
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.swipe, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Swipe left to delete notification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_back, color: Colors.blue[700], size: 16),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        // Notifications for this date
                        ...entry.value.map(
                          (notif) => _buildNotificationCard(
                            context,
                            notif,
                            notificationService,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationHistoryModel notification,
    NotificationHistoryService service,
  ) {
    // Deletion deadline is 7 days after scheduled time
    final deletionDeadline = notification.scheduledFor.add(
      const Duration(days: 7),
    );

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification?'),
            content: const Text(
              'This notification will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await service.deleteNotification(notification.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        elevation: notification.shown ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 12),
        color: notification.shown ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: const Icon(Icons.notifications, color: Colors.blue),
              ),
              // Red dot indicator for unshown notifications
              if (!notification.shown)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.taskTitle,
            style: TextStyle(
              fontWeight: notification.shown
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Reminder: ${notification.notificationType} before due'),
              const SizedBox(height: 4),
              Text(
                'Scheduled: ${_formatTime(notification.scheduledFor)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              // Realtime countdown widget
              RealtimeCountdownWidget(
                targetTime: deletionDeadline,
                style: TextStyle(fontSize: 11, color: Colors.red[700]),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            // Mark as shown when tapped
            if (!notification.shown) {
              await service.markAsShown(notification.id);
            }

            // Navigate to task detail screen
            if (context.mounted) {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Check if this is a team assignment notification
                if (notification.teamId != null &&
                    notification.assignmentId != null) {
                  // Fetch team assignment from team_assignments collection
                  final assignmentDoc = await FirebaseFirestore.instance
                      .collection('team_assignments')
                      .doc(notification.assignmentId)
                      .get();

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog

                    if (assignmentDoc.exists) {
                      final assignment = TeamAssignmentModel.fromFirestore(
                        assignmentDoc,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TeamTaskDetailScreen(assignment: assignment),
                        ),
                      );
                    } else {
                      // Assignment no longer exists
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team assignment no longer exists'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } else {
                  // Fetch personal task from personal_tasks collection
                  final taskDoc = await FirebaseFirestore.instance
                      .collection('personal_tasks')
                      .doc(notification.taskId)
                      .get();

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog

                    if (taskDoc.exists) {
                      final task = TaskModel.fromFirestore(taskDoc);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PersonalTaskDetailScreen(task: task),
                        ),
                      );
                    } else {
                      // Task no longer exists
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task no longer exists'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading task: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }

  List<MapEntry<String, List<NotificationHistoryModel>>> _groupByDate(
    List<NotificationHistoryModel> notifications,
  ) {
    final Map<String, List<NotificationHistoryModel>> grouped = {};
    final now = DateTime.now();

    for (var notif in notifications) {
      final date = notif.scheduledFor;
      String key;

      if (_isSameDay(date, now)) {
        key = 'Today';
      } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
        key = 'Yesterday';
      } else if (now.difference(date).inDays < 7) {
        key = DateFormat('EEEE').format(date); // Day name
      } else {
        key = DateFormat('MMM d, yyyy').format(date);
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(notif);
    }

    return grouped.entries.toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}
