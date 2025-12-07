import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Team assignment model for tasks assigned by team owner
class TeamAssignmentModel {
  final String id;
  final String teamId;
  final String assignedToUid; // Member who must complete the task
  final String assignedByUid; // Owner who created the assignment
  final String title;
  final String? description;
  final String? level; // 'Easy' or 'Hard'
  final DateTime? dueDate; // Due date for the task
  final TimeOfDay? dueTime; // Due time for the task
  final String? category;
  final String? priority; // 'Low', 'Medium', 'High'
  final String status; // 'pending', 'in_progress', 'done'

  // IMPORTANT: Photos are stored in Appwrite Documents, NOT Firestore
  // These fields exist only for backward compatibility with old data
  // New photos: Use ImageHelper.uploadPhotoToAppwrite() / getPhotoFromAppwrite()
  // Old photos: Will load from these fields if Appwrite photo doesn't exist
  final String? photoBeforeBase64; // Base64 WebP (legacy field)
  final String? photoAfterBase64; // Base64 WebP (legacy field)

  final DateTime? completedAt;
  final DateTime createdAt;
  final bool viewedByOwner; // Has owner viewed completed/overdue task
  final bool viewedByMember; // Has member viewed new assignment

  TeamAssignmentModel({
    required this.id,
    required this.teamId,
    required this.assignedToUid,
    required this.assignedByUid,
    required this.title,
    this.description,
    this.level,
    this.dueDate,
    this.dueTime,
    this.category,
    this.priority,
    this.status = 'pending',
    this.photoBeforeBase64,
    this.photoAfterBase64,
    this.completedAt,
    required this.createdAt,
    this.viewedByOwner = false,
    this.viewedByMember = false,
  });

  /// Convert from Firestore document
  factory TeamAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse dueTime from string (HH:mm format)
    TimeOfDay? parsedTime;
    if (data['dueTime'] != null) {
      final parts = data['dueTime'].toString().split(':');
      if (parts.length == 2) {
        parsedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    return TeamAssignmentModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      assignedToUid: data['assignedToUid'] ?? '',
      assignedByUid: data['assignedByUid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      level: data['level'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      dueTime: parsedTime,
      category: data['category'],
      priority: data['priority'],
      status: data['status'] ?? 'pending',
      photoBeforeBase64: data['photoBeforeBase64'],
      photoAfterBase64: data['photoAfterBase64'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewedByOwner: data['viewedByOwner'] ?? false,
      viewedByMember: data['viewedByMember'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    // Convert TimeOfDay to string format (HH:mm)
    String? timeString;
    if (dueTime != null) {
      timeString =
          '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}';
    }

    return {
      'teamId': teamId,
      'assignedToUid': assignedToUid,
      'assignedByUid': assignedByUid,
      'title': title,
      'description': description,
      'level': level,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'dueTime': timeString,
      'category': category,
      'priority': priority,
      'status': status,
      // Photos NOT saved to Firestore - stored in Appwrite Documents
      // 'photoBeforeBase64': null, // Explicitly not saving
      // 'photoAfterBase64': null,  // Explicitly not saving
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewedByOwner': viewedByOwner,
      'viewedByMember': viewedByMember,
    };
  }

  /// Get combined date and time as DateTime
  DateTime? get dueDateTime {
    if (dueDate == null) return null;
    if (dueTime == null) return dueDate;

    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime!.hour,
      dueTime!.minute,
    );
  }

  /// Check if photos should be pruned (done for 7+ days)
  bool get shouldPrunePhotos {
    if (status != 'done' || completedAt == null) return false;
    return DateTime.now().difference(completedAt!).inDays > 7;
  }

  /// Check if task should be deleted (completed OR overdue for 7+ days)
  bool get shouldBeDeleted {
    final now = DateTime.now();

    // Delete if task is COMPLETED for 7+ days
    if (status == 'done' && completedAt != null) {
      return now.difference(completedAt!).inDays > 7;
    }

    // OR delete if task is OVERDUE (not completed) for 7+ days
    if (status != 'done' && dueDateTime != null) {
      if (now.isAfter(dueDateTime!)) {
        return now.difference(dueDateTime!).inDays > 7;
      }
    }

    return false;
  }

  /// Get time remaining until auto-deletion
  /// Shows for COMPLETED tasks OR OVERDUE tasks
  Duration? get timeUntilDeletion {
    final now = DateTime.now();

    // Show countdown if task is COMPLETED (7 days from completion)
    if (status == 'done' && completedAt != null) {
      final deletionDate = completedAt!.add(const Duration(days: 7));
      final remaining = deletionDate.difference(now);
      if (!remaining.isNegative) return remaining;
    }

    // OR show countdown if task is OVERDUE and not completed (7 days from due date)
    if (status != 'done' && dueDateTime != null) {
      if (now.isAfter(dueDateTime!)) {
        final deletionDate = dueDateTime!.add(const Duration(days: 7));
        final remaining = deletionDate.difference(now);
        if (!remaining.isNegative) return remaining;
      }
    }

    return null;
  }

  /// Get human-readable countdown text
  String get deletionCountdownText {
    final duration = timeUntilDeletion;
    if (duration == null) return '';

    final days = duration.inDays;
    if (days > 0) {
      return 'Auto-delete in $days day${days == 1 ? '' : 's'}';
    }

    final hours = duration.inHours;
    if (hours > 0) {
      return 'Auto-delete in $hours hour${hours == 1 ? '' : 's'}';
    }

    return 'Auto-delete soon';
  }

  /// Check if task was completed late (after due date)
  bool get wasCompletedLate {
    if (status != 'done' || completedAt == null || dueDateTime == null) {
      return false;
    }
    return completedAt!.isAfter(dueDateTime!);
  }

  /// Get deletion reason message
  String get deletionReasonMessage {
    final now = DateTime.now();

    // Completed task
    if (status == 'done' && completedAt != null) {
      if (wasCompletedLate) {
        return 'This task will be permanently deleted in ${timeUntilDeletion!.inDays} days because it was completed late.';
      } else {
        return 'This task will be permanently deleted in ${timeUntilDeletion!.inDays} days. It was completed successfully.';
      }
    }

    // Overdue and not completed
    if (status != 'done' && dueDateTime != null && now.isAfter(dueDateTime!)) {
      return 'This task will be permanently deleted in ${timeUntilDeletion!.inDays} days because it is overdue and not completed.';
    }

    return 'This task will be automatically deleted soon.';
  }

  /// Check if task is completed
  bool get isCompleted => status == 'done';

  /// Check if task has proof photos
  bool get hasProof => photoBeforeBase64 != null && photoAfterBase64 != null;

  /// Check if task needs owner review (for badge)
  bool get needsOwnerReview {
    if (viewedByOwner) return false;

    // Show badge if completed
    if (status == 'done') return true;

    // OR show badge if overdue
    if (dueDateTime != null && DateTime.now().isAfter(dueDateTime!)) {
      if (status != 'done') return true;
    }

    return false;
  }

  /// Check if task needs member review (for badge)
  bool get needsMemberReview {
    // Show badge for any unviewed assignment
    return !viewedByMember;
  }

  /// Create a copy with updated fields
  TeamAssignmentModel copyWith({
    String? id,
    String? teamId,
    String? assignedToUid,
    String? assignedByUid,
    String? title,
    String? description,
    String? level,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    String? category,
    String? priority,
    String? status,
    String? photoBeforeBase64,
    String? photoAfterBase64,
    DateTime? completedAt,
    DateTime? createdAt,
    bool? viewedByOwner,
    bool? viewedByMember,
  }) {
    return TeamAssignmentModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedByUid: assignedByUid ?? this.assignedByUid,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      photoBeforeBase64: photoBeforeBase64 ?? this.photoBeforeBase64,
      photoAfterBase64: photoAfterBase64 ?? this.photoAfterBase64,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      viewedByOwner: viewedByOwner ?? this.viewedByOwner,
      viewedByMember: viewedByMember ?? this.viewedByMember,
    );
  }
}
