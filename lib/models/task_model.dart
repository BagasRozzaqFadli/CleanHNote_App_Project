import 'package:cloud_firestore/cloud_firestore.dart';

/// Personal task model for individual users
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? level; // 'Easy' or 'Hard'
  final DateTime? dueDate;
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
    this.category,
    this.priority,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      level: data['level'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      category: data['category'],
      priority: data['priority'],
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'level': level,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if task should be auto-deleted (completed/overdue for 30+ days)
  bool get shouldBeDeleted {
    final now = DateTime.now();

    // If completed and older than 30 days
    if (isCompleted && completedAt != null) {
      return now.difference(completedAt!).inDays > 30;
    }

    // If overdue for more than 30 days
    if (dueDate != null && now.difference(dueDate!).inDays > 30) {
      return true;
    }

    return false;
  }

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? level,
    DateTime? dueDate,
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
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
