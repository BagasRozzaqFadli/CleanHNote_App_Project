import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification History Model
/// Stores notification metadata in Firestore for reliable delivery
class NotificationHistoryModel {
  final String id;
  final String userId;
  final String taskId;
  final String taskTitle;
  final String
  notificationType; // '10min', '20min', '30min', '1h', '1.5h', '2h'
  final DateTime scheduledFor; // When to show
  final DateTime createdAt;
  final bool shown; // Has been displayed
  final DateTime? shownAt; // When displayed

  NotificationHistoryModel({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskTitle,
    required this.notificationType,
    required this.scheduledFor,
    required this.createdAt,
    this.shown = false,
    this.shownAt,
  });

  /// Create from Firestore document
  factory NotificationHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      taskId: data['taskId'] ?? '',
      taskTitle: data['taskTitle'] ?? '',
      notificationType: data['notificationType'] ?? '',
      scheduledFor: (data['scheduledFor'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      shown: data['shown'] ?? false,
      shownAt: (data['shownAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'notificationType': notificationType,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': Timestamp.fromDate(createdAt),
      'shown': shown,
      'shownAt': shownAt != null ? Timestamp.fromDate(shownAt!) : null,
    };
  }

  /// Check if this notification should be auto-deleted (10+ days after scheduled time)
  bool get shouldAutoDelete {
    final now = DateTime.now();
    final age = now.difference(scheduledFor);
    return age.inDays >= 10;
  }

  /// Check if notification is overdue (scheduled time has passed)
  bool get isOverdue {
    return DateTime.now().isAfter(scheduledFor) && !shown;
  }

  /// Get time until deletion (10 days from scheduled time)
  Duration? get timeUntilDeletion {
    final now = DateTime.now();
    final deletionDate = scheduledFor.add(const Duration(days: 10));
    final remaining = deletionDate.difference(now);

    if (remaining.isNegative) return null;
    return remaining;
  }

  /// Human-readable deletion countdown
  String get deletionCountdownText {
    final duration = timeUntilDeletion;
    if (duration == null) return 'Will be deleted soon';

    final days = duration.inDays;
    if (days > 0) {
      return 'Deletes in $days day${days == 1 ? '' : 's'}';
    }

    final hours = duration.inHours;
    if (hours > 0) {
      return 'Deletes in $hours hour${hours == 1 ? '' : 's'}';
    }

    return 'Deletes soon';
  }

  /// Copy with updated fields
  NotificationHistoryModel copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? taskTitle,
    String? notificationType,
    DateTime? scheduledFor,
    DateTime? createdAt,
    bool? shown,
    DateTime? shownAt,
  }) {
    return NotificationHistoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      notificationType: notificationType ?? this.notificationType,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      shown: shown ?? this.shown,
      shownAt: shownAt ?? this.shownAt,
    );
  }
}
