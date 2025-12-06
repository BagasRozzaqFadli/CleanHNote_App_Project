import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/team_assignment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/notification_history_service.dart';
import '../services/notification_scheduler.dart';

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
  Future<void> assignTask(
    String ownerId,
    String teamId,
    String assignedToUid,
    TeamAssignmentModel assignment,
  ) async {
    try {
      await _dbService.assignTask(ownerId, teamId, assignedToUid, assignment);
      notifyListeners();
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

    // Delete the assignment document
    await FirebaseFirestore.instance
        .collection('team_assignments')
        .doc(assignmentId)
        .delete();

    print('✅ Team assignment and related notifications deleted');
  }

  /// Submit proof of work
  Future<void> submitProof(
    String assignmentId,
    String photoBeforeBase64,
    String photoAfterBase64,
    String uid,
  ) async {
    try {
      await _dbService.submitTeamProof(
        assignmentId,
        photoBeforeBase64,
        photoAfterBase64,
        uid,
      );
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
}
