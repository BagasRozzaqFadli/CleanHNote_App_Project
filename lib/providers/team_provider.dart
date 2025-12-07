import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/team_assignment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/notification_history_service.dart';
import '../services/notification_scheduler.dart';
import '../services/appwrite_service.dart';
import '../features/analytics/services/team_analytics_service.dart';

/// Provider for team management and assignments
class TeamProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // ============================================================================
  // TEAM MANAGEMENT
  // ============================================================================

  /// Create team (premium only)
  Future<String> createTeam(String ownerId, String teamName) async {
    try {
      final teamId = await _dbService.createTeam(ownerId, teamName);

      // Initialize analytics for the new team
      try {
        TeamAnalyticsService().initialize();
        await TeamAnalyticsService().initializeTeamAnalytics(
          teamId: teamId,
          teamName: teamName,
          ownerId: ownerId,
        );
        print('✅ Analytics initialized for team: $teamName');
      } catch (e) {
        print('⚠️ Failed to initialize analytics: $e');
        // Don't fail team creation if analytics initialization fails
      }

      notifyListeners();
      return teamId;
    } catch (e) {
      rethrow;
    }
  }

  /// Join team using invite code
  Future<void> joinTeam(String userId, String inviteCode) async {
    try {
      await _dbService.joinTeam(userId, inviteCode);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Leave team
  Future<void> leaveTeam(String userId, String teamId) async {
    try {
      await _dbService.leaveTeam(userId, teamId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Kick member (owner only)
  Future<void> kickMember(
    String ownerId,
    String teamId,
    String memberId,
  ) async {
    try {
      await _dbService.kickMember(ownerId, teamId, memberId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete team (owner only)
  Future<void> deleteTeam(String userId, String teamId) async {
    try {
      await _dbService.deleteTeam(userId, teamId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get team
  Future<TeamModel?> getTeam(String teamId) async {
    return await _dbService.getTeam(teamId);
  }

  /// Get team stream
  Stream<TeamModel?> getTeamStream(String teamId) {
    return _dbService.getTeamStream(teamId);
  }

  /// Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    return _dbService.getUserStream(uid);
  }

  /// Get teams for user
  Stream<List<TeamModel>> getUserTeams(String uid) {
    return _dbService.getUserTeams(uid);
  }

  /// Find team by invite code (for QR joining)
  Future<TeamModel?> findTeamByInviteCode(String inviteCode) async {
    return await _dbService.findTeamByInviteCode(inviteCode);
  }

  // ============================================================================
  // TEAM ASSIGNMENTS
  // ============================================================================

  /// Assign task to member (owner only)
  Future<String> assignTask(
    String ownerId,
    String teamId,
    String assignedToUid,
    TeamAssignmentModel assignment,
  ) async {
    try {
      final assignmentId = await _dbService.assignTask(
        ownerId,
        teamId,
        assignedToUid,
        assignment,
      );

      // Record analytics - task assignment
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(assignedToUid)
            .get();

        if (userDoc.exists) {
          final memberData = userDoc.data()!;
          await TeamAnalyticsService().recordTaskAssigned(
            teamId: teamId,
            memberId: assignedToUid,
            memberName: memberData['email'] ?? 'Unknown',
            memberEmail: memberData['email'] ?? 'Unknown',
            taskId: assignmentId,
            title: assignment.title,
            description: assignment.description ?? '',
            assignedAt: assignment.createdAt,
            dueAt:
                assignment.dueDateTime ?? DateTime.now().add(Duration(days: 7)),
          );
        }
      } catch (e) {
        print('⚠️ Analytics tracking failed: $e');
      }

      notifyListeners();
      return assignmentId;
    } catch (e) {
      rethrow;
    }
  }

  /// Update team assignment (owner only)
  Future<void> updateTeamAssignment(
    String assignmentId,
    Map<String, dynamic> updates,
  ) async {
    await FirebaseFirestore.instance
        .collection('team_assignments')
        .doc(assignmentId)
        .update(updates);
  }

  /// Delete team assignment (owner only)
  Future<void> deleteTeamAssignment(String assignmentId) async {
    // Delete related notifications and notification history
    await NotificationHistoryService().deleteNotificationsForTask(assignmentId);

    // Cancel scheduled OS-level reminder notifications
    await NotificationScheduler.cancelTaskReminders(assignmentId);

    // Delete photos from Appwrite
    await AppwriteService().deleteAllPhotosForTask(assignmentId);

    // Delete the assignment document
    await FirebaseFirestore.instance
        .collection('team_assignments')
        .doc(assignmentId)
        .delete();

    print('✅ Team assignment, photos, and related notifications deleted');
  }

  /// Submit proof of work
  /// NOTE: Photos are now stored in Appwrite Documents separately
  /// This method only updates the assignment status and completion time
  /// Photos should be uploaded using ImageHelper.uploadPhotoToAppwrite() before calling this
  Future<void> submitProof(String assignmentId, String uid) async {
    try {
      // Get assignment data first for analytics
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('team_assignments')
          .doc(assignmentId)
          .get();

      if (assignmentDoc.exists) {
        final assignment = TeamAssignmentModel.fromFirestore(assignmentDoc);
        final completedAt = DateTime.now();
        final isLate =
            assignment.dueDateTime != null &&
            completedAt.isAfter(assignment.dueDateTime!);

        // Update assignment status to 'done' and set completion time
        await FirebaseFirestore.instance
            .collection('team_assignments')
            .doc(assignmentId)
            .update({
              'status': 'done',
              'completedAt': FieldValue.serverTimestamp(),
            });

        // Record analytics
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (userDoc.exists) {
            await TeamAnalyticsService().recordTaskCompleted(
              teamId: assignment.teamId,
              memberId: uid,
              taskId: assignmentId,
              completedAt: completedAt,
              isLate: isLate,
            );
          }
        } catch (e) {
          print('⚠️ Analytics tracking failed: $e');
          // Don't fail the task completion if analytics fails
        }
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get assignments for user
  Stream<List<TeamAssignmentModel>> getMyAssignments(String userId) {
    return _dbService.getTeamAssignments(userId);
  }

  /// Get all team assignments (owner dashboard)
  Stream<List<TeamAssignmentModel>> getAllAssignments(String teamId) {
    return _dbService.getAllTeamAssignments(teamId);
  }

  /// Update assignment status
  Future<void> updateAssignmentStatus(
    String teamId,
    String assignmentId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('team_assignments')
          .doc(assignmentId)
          .update({'status': newStatus});
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // ADMIN FUNCTIONS
  // ============================================================================

  /// Search user by email
  Future<UserModel?> searchUserByEmail(String email) async {
    return await _dbService.searchUserByEmail(email);
  }

  /// Search user by tenant ID
  Future<UserModel?> searchUserByTenantId(String tenantId) async {
    return await _dbService.searchUserByTenantId(tenantId);
  }

  /// Update user role
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _dbService.updateUserRole(uid, newRole);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user
  Future<UserModel?> getUser(String uid) async {
    return await _dbService.getUser(uid);
  }

  // ============================================================================
  // BADGE TRACKING
  // ============================================================================

  /// Mark task as viewed by owner
  Future<void> markTaskAsViewedByOwner(String assignmentId) async {
    await FirebaseFirestore.instance
        .collection('team_assignments')
        .doc(assignmentId)
        .update({'viewedByOwner': true});
  }

  /// Mark task as viewed by member
  Future<void> markTaskAsViewedByMember(String assignmentId) async {
    await FirebaseFirestore.instance
        .collection('team_assignments')
        .doc(assignmentId)
        .update({'viewedByMember': true});
  }

  /// Get unviewed count for a specific team (for owner badge on team card)
  Stream<int> getUnviewedCountForTeam(String teamId) {
    return FirebaseFirestore.instance
        .collection('team_assignments')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TeamAssignmentModel.fromFirestore(doc))
              .where((assignment) => assignment.needsOwnerReview)
              .length;
        });
  }

  /// Get total unviewed count across all owned teams (for drawer badge)
  Stream<int> getTotalUnviewedCountForOwner(String userId) {
    return FirebaseFirestore.instance
        .collection('teams')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((teamsSnapshot) async {
          int totalCount = 0;
          for (var teamDoc in teamsSnapshot.docs) {
            final assignmentsSnapshot = await FirebaseFirestore.instance
                .collection('team_assignments')
                .where('teamId', isEqualTo: teamDoc.id)
                .get();

            final count = assignmentsSnapshot.docs
                .map((doc) => TeamAssignmentModel.fromFirestore(doc))
                .where((assignment) => assignment.needsOwnerReview)
                .length;

            totalCount += count;
          }
          return totalCount;
        });
  }

  /// Get unviewed count for member (new assignments not yet viewed)
  Stream<int> getUnviewedCountForMember(String userId) {
    return FirebaseFirestore.instance
        .collection('team_assignments')
        .where('assignedToUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TeamAssignmentModel.fromFirestore(doc))
              .where((assignment) => assignment.needsMemberReview)
              .length;
        });
  }

  /// Get combined unviewed count (owner + member)
  /// For users who both own teams AND are members of other teams
  Stream<int> getCombinedUnviewedCount(String userId) {
    return FirebaseFirestore.instance
        .collection('teams')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((teamsSnapshot) async {
          int totalOwnerCount = 0;

          // Count owner badges
          for (var teamDoc in teamsSnapshot.docs) {
            final assignmentsSnapshot = await FirebaseFirestore.instance
                .collection('team_assignments')
                .where('teamId', isEqualTo: teamDoc.id)
                .get();

            final count = assignmentsSnapshot.docs
                .map((doc) => TeamAssignmentModel.fromFirestore(doc))
                .where((assignment) => assignment.needsOwnerReview)
                .length;

            totalOwnerCount += count;
          }

          // Count member badges
          final memberAssignments = await FirebaseFirestore.instance
              .collection('team_assignments')
              .where('assignedToUid', isEqualTo: userId)
              .get();

          final memberCount = memberAssignments.docs
              .map((doc) => TeamAssignmentModel.fromFirestore(doc))
              .where((assignment) => assignment.needsMemberReview)
              .length;

          return totalOwnerCount + memberCount;
        });
  }
}
