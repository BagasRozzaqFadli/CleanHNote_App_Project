import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/team_assignment_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

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
    await FirebaseFirestore.instance
        .collection('team_assignments')
        .doc(assignmentId)
        .delete();
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
}
