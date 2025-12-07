import 'dart:convert';

/// Team Analytics Model
/// Represents analytics data for a team stored in Appwrite
class TeamAnalytics {
  final String teamId;
  final String teamName;
  final String ownerId;
  final DateTime createdAt;
  final DateTime lastUpdated;

  // Aggregate statistics
  final int totalTasksAssigned;
  final int totalTasksCompleted;
  final int totalTasksLate;
  final int totalTasksIncomplete;
  final double averageCompletionTimeHours;

  // Member performance data
  final Map<String, MemberPerformance> members;

  // Monthly trends (last 12 months)
  final List<MonthlyTrend> monthlyTrends;

  TeamAnalytics({
    required this.teamId,
    required this.teamName,
    required this.ownerId,
    required this.createdAt,
    required this.lastUpdated,
    this.totalTasksAssigned = 0,
    this.totalTasksCompleted = 0,
    this.totalTasksLate = 0,
    this.totalTasksIncomplete = 0,
    this.averageCompletionTimeHours = 0.0,
    this.members = const {},
    this.monthlyTrends = const [],
  });

  /// Completion rate percentage
  double get completionRate {
    if (totalTasksAssigned == 0) return 0.0;
    return (totalTasksCompleted / totalTasksAssigned) * 100;
  }

  /// On-time completion rate
  double get onTimeRate {
    if (totalTasksCompleted == 0) return 0.0;
    final onTime = totalTasksCompleted - totalTasksLate;
    return (onTime / totalTasksCompleted) * 100;
  }

  /// Create from Appwrite document
  factory TeamAnalytics.fromJson(Map<String, dynamic> json) {
    final membersMap = <String, MemberPerformance>{};
    if (json['members'] != null) {
      // Decode JSON string to Map
      final membersData = json['members'] is String
          ? jsonDecode(json['members']) as Map<String, dynamic>
          : json['members'] as Map<String, dynamic>;

      membersData.forEach((key, value) {
        membersMap[key] = MemberPerformance.fromJson(value);
      });
    }

    final trends = <MonthlyTrend>[];
    if (json['monthlyTrends'] != null) {
      // Decode JSON string to List
      final trendsData = json['monthlyTrends'] is String
          ? jsonDecode(json['monthlyTrends']) as List
          : json['monthlyTrends'] as List;

      trends.addAll(trendsData.map((item) => MonthlyTrend.fromJson(item)));
    }

    return TeamAnalytics(
      teamId: json['teamId'] ?? '',
      teamName: json['teamName'] ?? '',
      ownerId: json['ownerId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      totalTasksAssigned: json['totalTasksAssigned'] ?? 0,
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,
      totalTasksLate: json['totalTasksLate'] ?? 0,
      totalTasksIncomplete: json['totalTasksIncomplete'] ?? 0,
      averageCompletionTimeHours: (json['averageCompletionTimeHours'] ?? 0.0)
          .toDouble(),
      members: membersMap,
      monthlyTrends: trends,
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toJson() {
    final membersJson = <String, dynamic>{};
    members.forEach((key, value) {
      membersJson[key] = value.toJson();
    });

    return {
      'teamId': teamId,
      'teamName': teamName,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalTasksAssigned': totalTasksAssigned,
      'totalTasksCompleted': totalTasksCompleted,
      'totalTasksLate': totalTasksLate,
      'totalTasksIncomplete': totalTasksIncomplete,
      'averageCompletionTimeHours': averageCompletionTimeHours,
      'members': jsonEncode(membersJson), // Convert to JSON string
      'monthlyTrends': jsonEncode(
        monthlyTrends.map((t) => t.toJson()).toList(),
      ), // Convert to JSON string
    };
  }

  /// Copy with updated fields
  TeamAnalytics copyWith({
    String? teamId,
    String? teamName,
    String? ownerId,
    DateTime? createdAt,
    DateTime? lastUpdated,
    int? totalTasksAssigned,
    int? totalTasksCompleted,
    int? totalTasksLate,
    int? totalTasksIncomplete,
    double? averageCompletionTimeHours,
    Map<String, MemberPerformance>? members,
    List<MonthlyTrend>? monthlyTrends,
  }) {
    return TeamAnalytics(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalTasksAssigned: totalTasksAssigned ?? this.totalTasksAssigned,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalTasksLate: totalTasksLate ?? this.totalTasksLate,
      totalTasksIncomplete: totalTasksIncomplete ?? this.totalTasksIncomplete,
      averageCompletionTimeHours:
          averageCompletionTimeHours ?? this.averageCompletionTimeHours,
      members: members ?? this.members,
      monthlyTrends: monthlyTrends ?? this.monthlyTrends,
    );
  }
}

/// Member Performance Model
class MemberPerformance {
  final String memberId;
  final String name;
  final String email;
  final DateTime joinedAt;
  final MemberStats stats;
  final List<TaskHistory> recentTasks; // Max 50

  MemberPerformance({
    required this.memberId,
    required this.name,
    required this.email,
    required this.joinedAt,
    required this.stats,
    this.recentTasks = const [],
  });

  factory MemberPerformance.fromJson(Map<String, dynamic> json) {
    final tasks = <TaskHistory>[];
    if (json['recentTasks'] != null) {
      final tasksData = json['recentTasks'] as List;
      tasks.addAll(tasksData.map((item) => TaskHistory.fromJson(item)));
    }

    return MemberPerformance(
      memberId: json['memberId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      joinedAt: DateTime.parse(json['joinedAt']),
      stats: MemberStats.fromJson(json['stats'] ?? {}),
      recentTasks: tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'name': name,
      'email': email,
      'joinedAt': joinedAt.toIso8601String(),
      'stats': stats.toJson(),
      'recentTasks': recentTasks.map((t) => t.toJson()).toList(),
    };
  }
}

/// Member Statistics
class MemberStats {
  final int assigned;
  final int completed;
  final int late;
  final int incomplete;
  final double avgCompletionHours;
  final double completionRate;
  final double onTimeRate;

  MemberStats({
    this.assigned = 0,
    this.completed = 0,
    this.late = 0,
    this.incomplete = 0,
    this.avgCompletionHours = 0.0,
    this.completionRate = 0.0,
    this.onTimeRate = 0.0,
  });

  factory MemberStats.fromJson(Map<String, dynamic> json) {
    return MemberStats(
      assigned: json['assigned'] ?? 0,
      completed: json['completed'] ?? 0,
      late: json['late'] ?? 0,
      incomplete: json['incomplete'] ?? 0,
      avgCompletionHours: (json['avgCompletionHours'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      onTimeRate: (json['onTimeRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assigned': assigned,
      'completed': completed,
      'late': late,
      'incomplete': incomplete,
      'avgCompletionHours': avgCompletionHours,
      'completionRate': completionRate,
      'onTimeRate': onTimeRate,
    };
  }
}

/// Task History Entry
class TaskHistory {
  final String taskId;
  final String title;
  final String description;
  final DateTime assignedAt;
  final DateTime dueAt;
  final DateTime? completedAt;
  final String status; // 'completed', 'late', 'incomplete'
  final double? completionTimeHours;

  TaskHistory({
    required this.taskId,
    required this.title,
    required this.description,
    required this.assignedAt,
    required this.dueAt,
    this.completedAt,
    required this.status,
    this.completionTimeHours,
  });

  /// Check if task was completed late
  bool get wasLate => status == 'late';

  /// Check if task was completed on time
  bool get wasOnTime => status == 'completed';

  /// Check if task was never completed
  bool get wasIncomplete => status == 'incomplete';

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    return TaskHistory(
      taskId: json['taskId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedAt: DateTime.parse(json['assignedAt']),
      dueAt: DateTime.parse(json['dueAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      status: json['status'] ?? 'incomplete',
      completionTimeHours: json['completionTimeHours']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'assignedAt': assignedAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'completionTimeHours': completionTimeHours,
    };
  }
}

/// Monthly Trend Data
class MonthlyTrend {
  final String month; // "2025-12" format
  final int tasksAssigned;
  final int tasksCompleted;
  final double completionRate;
  final double avgCompletionTime;

  MonthlyTrend({
    required this.month,
    this.tasksAssigned = 0,
    required this.tasksCompleted,
    required this.completionRate,
    required this.avgCompletionTime,
  });

  // Parse month number from string (1-12)
  int get monthNumber {
    final parts = month.split('-');
    return parts.length >= 2 ? int.tryParse(parts[1]) ?? 1 : 1;
  }

  // Parse year number from string
  int get year {
    final parts = month.split('-');
    return parts.isNotEmpty
        ? int.tryParse(parts[0]) ?? DateTime.now().year
        : DateTime.now().year;
  }

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      tasksAssigned: json['tasksAssigned'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      avgCompletionTime: (json['avgCompletionTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'tasksAssigned': tasksAssigned,
      'tasksCompleted': tasksCompleted,
      'completionRate': completionRate,
      'avgCompletionTime': avgCompletionTime,
    };
  }
}
