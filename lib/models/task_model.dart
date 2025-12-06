import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Personal task model for individual users
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? level; // 'Easy' or 'Hard'
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final String? category;
  final String? priority; // 'Low', 'Medium', 'High'
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.level,
    this.dueDate,
    this.dueTime,
    this.category,
    this.priority,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
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

    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      level: data['level'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      dueTime: parsedTime,
      category: data['category'],
      priority: data['priority'],
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'userId': userId,
      'title': title,
      'description': description,
      'level': level,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'dueTime': timeString,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
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

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDateTime == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDateTime!);
  }

  /// Check if task should be deleted (completed OR overdue for 7+ days)
  bool get shouldBeDeleted {
    final now = DateTime.now();

    // Delete if task is COMPLETED for 7+ days
    if (isCompleted && completedAt != null) {
      return now.difference(completedAt!).inDays > 7;
    }

    // OR delete if task is OVERDUE (not completed) for 7+ days
    if (!isCompleted && dueDateTime != null) {
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
    if (isCompleted && completedAt != null) {
      final deletionDate = completedAt!.add(const Duration(days: 7));
      final remaining = deletionDate.difference(now);
      if (!remaining.isNegative) return remaining;
    }

    // OR show countdown if task is OVERDUE and not completed (7 days from due date)
    if (!isCompleted && dueDateTime != null) {
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

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? level,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    String? category,
    String? priority,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
