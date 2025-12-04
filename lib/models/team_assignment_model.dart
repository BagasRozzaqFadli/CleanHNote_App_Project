import 'package:cloud_firestore/cloud_firestore.dart';

/// Team assignment model for tasks assigned by team owner
class TeamAssignmentModel {
  final String id;
  final String teamId;
  final String assignedToUid; // Member who must complete the task
  final String assignedByUid; // Owner who created the assignment
  final String title;
  final String? description;
  final String? level; // 'Easy' or 'Hard'
  final String? category;
  final String? priority; // 'Low', 'Medium', 'High'
  final String status; // 'pending', 'in_progress', 'done'
  final String? photoBeforeBase64; // Base64 WebP string
  final String? photoAfterBase64; // Base64 WebP string
  final DateTime? completedAt;
  final DateTime createdAt;

  TeamAssignmentModel({
    required this.id,
    required this.teamId,
    required this.assignedToUid,
    required this.assignedByUid,
    required this.title,
    this.description,
    this.level,
    this.category,
    this.priority,
    this.status = 'pending',
    this.photoBeforeBase64,
    this.photoAfterBase64,
    this.completedAt,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory TeamAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamAssignmentModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      assignedToUid: data['assignedToUid'] ?? '',
      assignedByUid: data['assignedByUid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      level: data['level'],
      category: data['category'],
      priority: data['priority'],
      status: data['status'] ?? 'pending',
      photoBeforeBase64: data['photoBeforeBase64'],
      photoAfterBase64: data['photoAfterBase64'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'assignedToUid': assignedToUid,
      'assignedByUid': assignedByUid,
      'title': title,
      'description': description,
      'level': level,
      'category': category,
      'priority': priority,
      'status': status,
      'photoBeforeBase64': photoBeforeBase64,
      'photoAfterBase64': photoAfterBase64,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if photos should be pruned (done for 7+ days)
  bool get shouldPrunePhotos {
    if (status != 'done' || completedAt == null) return false;
    return DateTime.now().difference(completedAt!).inDays > 7;
  }

  /// Check if task should be deleted (done/overdue for 30+ days)
  bool get shouldBeDeleted {
    if (completedAt != null && status == 'done') {
      return DateTime.now().difference(completedAt!).inDays > 30;
    }
    return false;
  }

  /// Check if task is completed
  bool get isCompleted => status == 'done';

  /// Check if task has proof photos
  bool get hasProof => photoBeforeBase64 != null && photoAfterBase64 != null;

  /// Create a copy with updated fields
  TeamAssignmentModel copyWith({
    String? id,
    String? teamId,
    String? assignedToUid,
    String? assignedByUid,
    String? title,
    String? description,
    String? level,
    String? category,
    String? priority,
    String? status,
    String? photoBeforeBase64,
    String? photoAfterBase64,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return TeamAssignmentModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedByUid: assignedByUid ?? this.assignedByUid,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      photoBeforeBase64: photoBeforeBase64 ?? this.photoBeforeBase64,
      photoAfterBase64: photoAfterBase64 ?? this.photoAfterBase64,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
