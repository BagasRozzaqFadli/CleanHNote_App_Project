import 'package:appwrite/appwrite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_analytics.dart';

/// Service for managing team analytics in Appwrite
/// All analytics data is stored in a single document per team for efficiency
class TeamAnalyticsService {
  static final TeamAnalyticsService _instance =
      TeamAnalyticsService._internal();
  factory TeamAnalyticsService() => _instance;
  TeamAnalyticsService._internal();

  late Client _client;
  late Databases _databases;
  late Account _account;

  // Appwrite Configuration
  static const String _endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String _projectId = '6935585d000912ee1a86';
  static const String _databaseId = '693558df001f7968fabd';
  static const String _collectionId = 'team_analytics';

  bool _isAuthenticated = false;

  /// Initialize Appwrite client
  void initialize() {
    _client = Client().setEndpoint(_endpoint).setProject(_projectId);
    _databases = Databases(_client);
    _account = Account(_client);
  }

  /// Ensure user session exists
  Future<void> _ensureSession() async {
    if (_isAuthenticated) return;

    try {
      await _account.get();
      _isAuthenticated = true;
      print('✅ Analytics: Using existing session');
    } catch (e) {
      try {
        await _account.createAnonymousSession();
        _isAuthenticated = true;
        print('✅ Analytics: Created anonymous session');
      } catch (e) {
        print('❌ Analytics: Failed to create session: $e');
        rethrow;
      }
    }
  }

  /// Initialize analytics for a new team
  Future<void> initializeTeamAnalytics({
    required String teamId,
    required String teamName,
    required String ownerId,
  }) async {
    try {
      await _ensureSession();

      final analytics = TeamAnalytics(
        teamId: teamId,
        teamName: teamName,
        ownerId: ownerId,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
        data: analytics.toJson(),
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.any()),
          Permission.delete(Role.any()),
        ],
      );

      print('✅ Initialized analytics for team: $teamName');
    } catch (e) {
      print('❌ Failed to initialize team analytics: $e');
      rethrow;
    }
  }

  /// Record task assignment
  Future<void> recordTaskAssigned({
    required String teamId,
    required String memberId,
    required String memberName,
    required String memberEmail,
    required String taskId,
    required String title,
    required String description,
    required DateTime assignedAt,
    required DateTime dueAt,
  }) async {
    try {
      await _ensureSession();

      // Get current analytics
      final doc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
      );

      final analytics = TeamAnalytics.fromJson(doc.data);

      // Update or create member performance
      final members = Map<String, MemberPerformance>.from(analytics.members);

      if (!members.containsKey(memberId)) {
        // New member - initialize performance
        members[memberId] = MemberPerformance(
          memberId: memberId,
          name: memberName,
          email: memberEmail,
          joinedAt: DateTime.now(),
          stats: MemberStats(assigned: 1),
          recentTasks: [
            TaskHistory(
              taskId: taskId,
              title: title,
              description: description,
              assignedAt: assignedAt,
              dueAt: dueAt,
              status: 'pending',
            ),
          ],
        );
      } else {
        // Existing member - update stats
        final member = members[memberId]!;
        final updatedTasks = List<TaskHistory>.from(member.recentTasks);

        // Add new task to history
        updatedTasks.insert(
          0,
          TaskHistory(
            taskId: taskId,
            title: title,
            description: description,
            assignedAt: assignedAt,
            dueAt: dueAt,
            status: 'pending',
          ),
        );

        // Keep only last 50 tasks
        if (updatedTasks.length > 50) {
          updatedTasks.removeRange(50, updatedTasks.length);
        }

        members[memberId] = MemberPerformance(
          memberId: member.memberId,
          name: member.name,
          email: member.email,
          joinedAt: member.joinedAt,
          stats: MemberStats(
            assigned: member.stats.assigned + 1,
            completed: member.stats.completed,
            late: member.stats.late,
            incomplete: member.stats.incomplete,
            avgCompletionHours: member.stats.avgCompletionHours,
            completionRate: member.stats.completionRate,
            onTimeRate: member.stats.onTimeRate,
          ),
          recentTasks: updatedTasks,
        );
      }

      // Update team analytics
      final updated = analytics.copyWith(
        totalTasksAssigned: analytics.totalTasksAssigned + 1,
        lastUpdated: DateTime.now(),
        members: members,
      );

      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
        data: updated.toJson(),
      );

      print('✅ Recorded task assignment: $title for $memberName');
    } catch (e) {
      print('❌ Failed to record task assignment: $e');
    }
  }

  /// Record task completion
  Future<void> recordTaskCompleted({
    required String teamId,
    required String memberId,
    required String taskId,
    required DateTime completedAt,
    required bool isLate,
  }) async {
    try {
      await _ensureSession();

      final doc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
      );

      final analytics = TeamAnalytics.fromJson(doc.data);
      final members = Map<String, MemberPerformance>.from(analytics.members);

      if (!members.containsKey(memberId)) {
        print('⚠️ Member $memberId not found in analytics');
        return;
      }

      final member = members[memberId]!;
      final updatedTasks = List<TaskHistory>.from(member.recentTasks);

      // Find and update the task
      final taskIndex = updatedTasks.indexWhere((t) => t.taskId == taskId);
      if (taskIndex != -1) {
        final task = updatedTasks[taskIndex];
        final completionTime = completedAt
            .difference(task.assignedAt)
            .inHours
            .toDouble();

        updatedTasks[taskIndex] = TaskHistory(
          taskId: task.taskId,
          title: task.title,
          description: task.description,
          assignedAt: task.assignedAt,
          dueAt: task.dueAt,
          completedAt: completedAt,
          status: isLate ? 'late' : 'completed',
          completionTimeHours: completionTime,
        );
      }

      // Recalculate member stats
      final completed = member.stats.completed + 1;
      final late = isLate ? member.stats.late + 1 : member.stats.late;

      // Calculate new average completion time
      final totalCompletionTime =
          member.stats.avgCompletionHours * member.stats.completed +
          (updatedTasks[taskIndex].completionTimeHours ?? 0);
      final avgCompletionHours = totalCompletionTime / completed;

      // Calculate rates
      final totalTasks = member.stats.assigned;
      final completionRate = totalTasks > 0
          ? (completed / totalTasks) * 100
          : 0.0;
      final onTimeRate = completed > 0
          ? ((completed - late) / completed) * 100
          : 0.0;

      members[memberId] = MemberPerformance(
        memberId: member.memberId,
        name: member.name,
        email: member.email,
        joinedAt: member.joinedAt,
        stats: MemberStats(
          assigned: member.stats.assigned,
          completed: completed,
          late: late,
          incomplete: member.stats.incomplete,
          avgCompletionHours: avgCompletionHours,
          completionRate: completionRate,
          onTimeRate: onTimeRate,
        ),
        recentTasks: updatedTasks,
      );

      // Update team analytics
      final teamCompleted = analytics.totalTasksCompleted + 1;
      final teamLate = isLate
          ? analytics.totalTasksLate + 1
          : analytics.totalTasksLate;

      final totalTeamCompletionTime =
          analytics.averageCompletionTimeHours * analytics.totalTasksCompleted +
          (updatedTasks[taskIndex].completionTimeHours ?? 0);
      final teamAvgHours = totalTeamCompletionTime / teamCompleted;

      final updated = analytics.copyWith(
        totalTasksCompleted: teamCompleted,
        totalTasksLate: teamLate,
        averageCompletionTimeHours: teamAvgHours,
        lastUpdated: DateTime.now(),
        members: members,
      );

      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
        data: updated.toJson(),
      );

      print('✅ Recorded task completion: ${isLate ? "LATE" : "ON-TIME"}');
    } catch (e) {
      print('❌ Failed to record task completion: $e');
    }
  }

  /// Record task incomplete (overdue and not completed)
  Future<void> recordTaskIncomplete({
    required String teamId,
    required String memberId,
    required String taskId,
  }) async {
    try {
      await _ensureSession();

      final doc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
      );

      final analytics = TeamAnalytics.fromJson(doc.data);
      final members = Map<String, MemberPerformance>.from(analytics.members);

      if (!members.containsKey(memberId)) {
        print('⚠️ Member $memberId not found in analytics');
        return;
      }

      final member = members[memberId]!;
      final updatedTasks = List<TaskHistory>.from(member.recentTasks);

      // Find and update the task
      final taskIndex = updatedTasks.indexWhere((t) => t.taskId == taskId);
      if (taskIndex != -1) {
        final task = updatedTasks[taskIndex];
        updatedTasks[taskIndex] = TaskHistory(
          taskId: task.taskId,
          title: task.title,
          description: task.description,
          assignedAt: task.assignedAt,
          dueAt: task.dueAt,
          status: 'incomplete',
        );
      }

      // Update member stats
      final incomplete = member.stats.incomplete + 1;
      final totalTasks = member.stats.assigned;
      final completionRate = totalTasks > 0
          ? (member.stats.completed / totalTasks) * 100
          : 0.0;

      members[memberId] = MemberPerformance(
        memberId: member.memberId,
        name: member.name,
        email: member.email,
        joinedAt: member.joinedAt,
        stats: MemberStats(
          assigned: member.stats.assigned,
          completed: member.stats.completed,
          late: member.stats.late,
          incomplete: incomplete,
          avgCompletionHours: member.stats.avgCompletionHours,
          completionRate: completionRate,
          onTimeRate: member.stats.onTimeRate,
        ),
        recentTasks: updatedTasks,
      );

      // Update team analytics
      final updated = analytics.copyWith(
        totalTasksIncomplete: analytics.totalTasksIncomplete + 1,
        lastUpdated: DateTime.now(),
        members: members,
      );

      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
        data: updated.toJson(),
      );

      print('✅ Recorded task incomplete');
    } catch (e) {
      print('❌ Failed to record task incomplete: $e');
    }
  }

  /// Get team analytics
  /// Auto-initializes if analytics document doesn't exist
  Future<TeamAnalytics?> getTeamAnalytics(String teamId) async {
    try {
      await _ensureSession();

      final doc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
      );

      return TeamAnalytics.fromJson(doc.data);
    } catch (e) {
      // Check if document doesn't exist (404 error)
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        print('⚠️ Analytics not found for team $teamId, initializing...');

        // Try to get team info from Firestore to initialize analytics
        try {
          final teamDoc = await FirebaseFirestore.instance
              .collection('teams')
              .doc(teamId)
              .get();

          if (teamDoc.exists) {
            final teamData = teamDoc.data()!;
            final teamName = teamData['name'] ?? 'Unknown Team';
            final ownerId = teamData['ownerId'] ?? '';

            // Initialize analytics
            await initializeTeamAnalytics(
              teamId: teamId,
              teamName: teamName,
              ownerId: ownerId,
            );

            // Fetch the newly created analytics
            final newDoc = await _databases.getDocument(
              databaseId: _databaseId,
              collectionId: _collectionId,
              documentId: teamId,
            );

            print('✅ Analytics initialized and fetched successfully');
            return TeamAnalytics.fromJson(newDoc.data);
          } else {
            print('❌ Team $teamId not found in Firestore');
            return null;
          }
        } catch (initError) {
          print('❌ Failed to auto-initialize analytics: $initError');
          return null;
        }
      }

      print('❌ Failed to get team analytics: $e');
      return null;
    }
  }

  /// Get member performance
  Future<MemberPerformance?> getMemberPerformance(
    String teamId,
    String memberId,
  ) async {
    try {
      final analytics = await getTeamAnalytics(teamId);
      return analytics?.members[memberId];
    } catch (e) {
      print('❌ Failed to get member performance: $e');
      return null;
    }
  }

  /// Delete team analytics (when team is deleted)
  Future<void> deleteTeamAnalytics(String teamId) async {
    try {
      await _ensureSession();

      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: teamId,
      );

      print('✅ Deleted analytics for team: $teamId');
    } catch (e) {
      print('❌ Failed to delete team analytics: $e');
    }
  }
}
