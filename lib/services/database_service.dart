import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../models/team_assignment_model.dart';
import 'notification_history_service.dart';
import 'notification_scheduler.dart';
import 'appwrite_service.dart';
import 'premium_downgrade_service.dart';
import 'premium_expiry_notifier.dart';
import '../features/analytics/services/team_analytics_service.dart';

/// Result of auto-maintenance operation
class MaintenanceResult {
  final int deletedTasks;
  final int prunedImages;

  MaintenanceResult({required this.deletedTasks, required this.prunedImages});

  @override
  String toString() =>
      'MaintenanceResult(deleted: $deletedTasks, pruned: $prunedImages)';
}

/// Comprehensive database service for CleanHNote
/// Handles all Firestore operations with Firebase Spark Plan constraints
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // PERSONAL TASKS
  // ============================================================================

  /// Create personal task with FREE PLAN LIMIT enforcement
  /// Free users: Max 5 active tasks
  /// Returns the generated task ID
  Future<String> createPersonalTask(TaskModel task, String uid) async {
    try {
      // Get user to check role
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromFirestore(userDoc);

      // If free user, check task count (ALL tasks including completed)
      if (user.role == 'free') {
        final tasksQuery = await _firestore
            .collection('personal_tasks')
            .where('userId', isEqualTo: uid)
            .get();

        if (tasksQuery.docs.length >= 5) {
          throw Exception('FREE_LIMIT_REACHED');
        }
      }

      // Create the task and return generated ID
      final docRef = await _firestore
          .collection('personal_tasks')
          .add(task.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update personal task
  Future<void> updatePersonalTask(
    String taskId,
    Map<String, dynamic> updates,
    String uid,
  ) async {
    try {
      final docRef = _firestore.collection('personal_tasks').doc(taskId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Task not found');
      }

      final task = TaskModel.fromFirestore(doc);
      if (task.userId != uid) {
        throw Exception('Unauthorized: Not your task');
      }

      await docRef.update(updates);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete personal task
  Future<void> deletePersonalTask(String taskId, String uid) async {
    try {
      final docRef = _firestore.collection('personal_tasks').doc(taskId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Task not found');
      }

      final task = TaskModel.fromFirestore(doc);
      if (task.userId != uid) {
        throw Exception('Unauthorized: Not your task');
      }

      print('🗑️ [DatabaseService] Starting cascade delete for task: $taskId');

      // Delete related notifications and notification history
      print('🗑️ [DatabaseService] Deleting notifications...');
      await NotificationHistoryService().deleteNotificationsForTask(taskId);

      // Cancel scheduled OS-level reminder notifications
      print('🗑️ [DatabaseService] Cancelling scheduled reminders...');
      await NotificationScheduler.cancelTaskReminders(taskId);

      // Delete the task document
      print('🗑️ [DatabaseService] Deleting task document...');
      await docRef.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get personal tasks stream
  Stream<List<TaskModel>> getPersonalTasks(String uid) {
    return _firestore
        .collection('personal_tasks')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // ============================================================================
  // TEAM MANAGEMENT
  // ============================================================================

  /// Create team (PREMIUM ONLY - enforced by Firestore rules)
  Future<String> createTeam(String ownerId, String teamName) async {
    try {
      // Check user limits first
      final userDoc = await _firestore.collection('users').doc(ownerId).get();
      final user = UserModel.fromFirestore(userDoc);

      // Validate premium access (auto-downgrades if expired)
      final downgradeService = PremiumDowngradeService();
      final hasValidPremium = await downgradeService.validatePremiumAccess(
        ownerId,
      );

      if (!hasValidPremium) {
        throw Exception('Only Premium users can create teams');
      }

      // Check if user already owns teams (Max 3 created teams for Premium)
      final ownedTeamsQuery = await _firestore
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (ownedTeamsQuery.docs.length >= 3) {
        throw Exception('Premium users can create max 3 teams');
      }

      final limit = 15; // Premium limit for joining
      if (user.joinedTeamIds.length >= limit) {
        throw Exception('Team limit reached ($limit teams max)');
      }

      // Generate unique invite code
      String inviteCode;
      bool isUnique = false;

      while (!isUnique) {
        inviteCode = TeamModel.generateInviteCode();
        final existing = await _firestore
            .collection('teams')
            .where('inviteCode', isEqualTo: inviteCode)
            .get();
        isUnique = existing.docs.isEmpty;

        if (isUnique) {
          // Create team
          final team = TeamModel(
            id: '',
            ownerId: ownerId,
            name: teamName,
            inviteCode: inviteCode,
            memberIds: [ownerId],
            createdAt: DateTime.now(),
          );

          final docRef = await _firestore
              .collection('teams')
              .add(team.toFirestore());

          // Add to user's joinedTeamIds
          await _firestore.collection('users').doc(ownerId).update({
            'joinedTeamIds': FieldValue.arrayUnion([docRef.id]),
          });

          return docRef.id;
        }
      }

      throw Exception('Failed to generate unique invite code');
    } catch (e) {
      rethrow;
    }
  }

  /// Join team using invite code
  Future<void> joinTeam(String userId, String inviteCode) async {
    try {
      // Check user limits first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromFirestore(userDoc);

      final limit = user.isPremium ? 15 : 3;
      if (user.joinedTeamIds.length >= limit) {
        throw Exception('Team limit reached ($limit teams max)');
      }

      // Find team by invite code
      final teamQuery = await _firestore
          .collection('teams')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .get();

      if (teamQuery.docs.isEmpty) {
        throw Exception('Invalid invite code');
      }

      final teamDoc = teamQuery.docs.first;
      final team = TeamModel.fromFirestore(teamDoc);

      // Check if already a member
      if (team.isMember(userId)) {
        throw Exception('Already a team member');
      }

      // Add user to team
      await teamDoc.reference.update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Add to user's joinedTeamIds
      await _firestore.collection('users').doc(userId).update({
        'joinedTeamIds': FieldValue.arrayUnion([teamDoc.id]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Find team by invite code (for QR validation)
  Future<TeamModel?> findTeamByInviteCode(String inviteCode) async {
    try {
      final teamQuery = await _firestore
          .collection('teams')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .get();

      if (teamQuery.docs.isEmpty) {
        return null;
      }

      return TeamModel.fromFirestore(teamQuery.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Leave team
  Future<void> leaveTeam(String userId, String teamId) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      final team = TeamModel.fromFirestore(teamDoc);

      if (team.isOwner(userId)) {
        throw Exception('Owner cannot leave team. Delete team instead.');
      }

      // CRITICAL: Mark all incomplete assignments as late FIRST
      // Must do this BEFORE removing user from team (for firestore rules)
      final assignmentsSnapshot = await _firestore
          .collection('team_assignments')
          .where('teamId', isEqualTo: teamId)
          .where('assignedToUid', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      if (assignmentsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final assignmentDoc in assignmentsSnapshot.docs) {
          batch.update(assignmentDoc.reference, {
            'status': 'late', // Mark as late/overdue (triggers auto-delete)
            'viewedByMember': true, // Remove badge
            'lateMarkedAt':
                FieldValue.serverTimestamp(), // Track when became late
          });
        }
        await batch.commit();
        print(
          '✅ Marked ${assignmentsSnapshot.docs.length} assignments as late (orphaned)',
        );
      }

      // NOW remove user from team (after assignments updated)
      await teamDoc.reference.update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });

      // Remove from user's joinedTeamIds
      await _firestore.collection('users').doc(userId).update({
        'joinedTeamIds': FieldValue.arrayRemove([teamId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete team (Owner only)
  Future<void> deleteTeam(String userId, String teamId) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      final team = TeamModel.fromFirestore(teamDoc);

      if (!team.isOwner(userId)) {
        throw Exception('Only owner can delete team');
      }

      // Delete team document
      await teamDoc.reference.delete();

      // Delete team analytics data from Firestore (non-critical)
      print('🗑️ Deleting Firestore analytics for team: $teamId');
      try {
        final analyticsSnapshot = await _firestore
            .collection('team_analytics')
            .where('teamId', isEqualTo: teamId)
            .get();

        if (analyticsSnapshot.docs.isNotEmpty) {
          print(
            '📊 Found ${analyticsSnapshot.docs.length} Firestore analytics documents to delete',
          );

          final batch = _firestore.batch();
          for (var doc in analyticsSnapshot.docs) {
            batch.delete(doc.reference);
            print('   Deleting analytics doc: ${doc.id}');
          }
          await batch.commit();
          print('✅ Firestore analytics deleted');
        } else {
          print('⚠️ No Firestore analytics found');
        }
      } catch (e) {
        print('⚠️ Failed to delete Fire store analytics (continuing): $e');
        // Continue with deletion even if Firestore analytics fails
      }

      // Delete team analytics from Appwrite (non-critical)
      print('🗑️ Deleting Appwrite analytics for team: $teamId');
      try {
        final analyticsService = TeamAnalyticsService();
        analyticsService.initialize();
        await analyticsService.deleteTeamAnalytics(teamId);
        print('✅ Appwrite analytics deleted');
      } catch (e) {
        print('⚠️ Failed to delete Appwrite analytics (continuing): $e');
        // Continue with deletion even if Appwrite fails
      }

      // CRITICAL: Delete all team assignments
      // This prevents ghost badges for all members after team deletion
      print('🗑️ Deleting all assignments for team: $teamId');
      try {
        final assignmentsSnapshot = await _firestore
            .collection('team_assignments')
            .where('teamId', isEqualTo: teamId)
            .get();

        if (assignmentsSnapshot.docs.isNotEmpty) {
          print(
            '📊 Found ${assignmentsSnapshot.docs.length} assignments to delete',
          );
          final batch = _firestore.batch();
          for (final doc in assignmentsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          print('✅ All team assignments deleted');
        } else {
          print('⚠️ No assignments found for this team');
        }
      } catch (e) {
        print('⚠️ Failed to delete assignments (continuing): $e');
        // Continue with team deletion even if assignment deletion fails
      }

      // Remove from owner's joinedTeamIds
      await _firestore.collection('users').doc(userId).update({
        'joinedTeamIds': FieldValue.arrayRemove([teamId]),
      });

      // CRITICAL: Remove teamId from ALL members' joinedTeamIds
      // This prevents orphaned teamIds in user documents
      if (team.memberIds.isNotEmpty) {
        print(
          '🧹 Cleaning up joinedTeamIds from ${team.memberIds.length} members',
        );
        final batch = _firestore.batch();

        for (final memberId in team.memberIds) {
          if (memberId != userId) {
            // Skip owner, already handled above
            final memberRef = _firestore.collection('users').doc(memberId);
            batch.update(memberRef, {
              'joinedTeamIds': FieldValue.arrayRemove([teamId]),
            });
          }
        }

        await batch.commit();
        print('✅ Cleaned up joinedTeamIds from all members');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// One-time cleanup: Remove orphaned teamIds from all users
  /// Call this once to fix existing data corruption from before deleteTeam fix
  Future<void> cleanupOrphanedTeamIds() async {
    try {
      print('🧹 Starting cleanup of orphaned teamIds...');

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      int usersFixed = 0;

      for (final userDoc in usersSnapshot.docs) {
        final joinedTeamIds = List<String>.from(
          userDoc.data()['joinedTeamIds'] ?? [],
        );

        if (joinedTeamIds.isEmpty) continue;

        final invalidTeamIds = <String>[];

        // Check each teamId
        for (final teamId in joinedTeamIds) {
          final teamDoc = await _firestore
              .collection('teams')
              .doc(teamId)
              .get();

          if (!teamDoc.exists) {
            // Team doesn't exist
            invalidTeamIds.add(teamId);
            print('   ❌ User ${userDoc.id}: Team $teamId not found');
          } else {
            // Team exists, check membership
            final memberIds = List<String>.from(
              teamDoc.data()?['memberIds'] ?? [],
            );
            if (!memberIds.contains(userDoc.id)) {
              // User not in team's memberIds
              invalidTeamIds.add(teamId);
              print('   ❌ User ${userDoc.id}: Not in team $teamId memberIds');
            }
          }
        }

        // Remove invalid teamIds
        if (invalidTeamIds.isNotEmpty) {
          await userDoc.reference.update({
            'joinedTeamIds': FieldValue.arrayRemove(invalidTeamIds),
          });
          usersFixed++;
          print('   ✅ Fixed user ${userDoc.id}: Removed $invalidTeamIds');
        }
      }

      print('');
      print('✅ Cleanup complete!');
      print('   Total users: $totalUsers');
      print('   Users fixed: $usersFixed');
    } catch (e) {
      print('❌ Cleanup failed: $e');
      rethrow;
    }
  }

  /// Kick member from team (OWNER ONLY)
  Future<void> kickMember(
    String ownerId,
    String teamId,
    String memberId,
  ) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      final team = TeamModel.fromFirestore(teamDoc);

      if (!team.isOwner(ownerId)) {
        throw Exception('OWNER_ONLY');
      }

      if (team.isOwner(memberId)) {
        throw Exception('Cannot kick owner');
      }

      // CRITICAL: Mark all incomplete assignments as late FIRST
      // Must do this BEFORE removing member from team (for firestore rules)
      final assignmentsSnapshot = await _firestore
          .collection('team_assignments')
          .where('teamId', isEqualTo: teamId)
          .where('assignedToUid', isEqualTo: memberId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      if (assignmentsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final assignmentDoc in assignmentsSnapshot.docs) {
          batch.update(assignmentDoc.reference, {
            'status': 'late', // Mark as late/overdue (triggers auto-delete)
            'viewedByMember': true, // Remove badge
            'lateMarkedAt':
                FieldValue.serverTimestamp(), // Track when became late
          });
        }
        await batch.commit();
        print(
          '✅ Marked ${assignmentsSnapshot.docs.length} assignments as late (orphaned)',
        );
      }

      // NOW remove member from team (after assignments updated)
      await teamDoc.reference.update({
        'memberIds': FieldValue.arrayRemove([memberId]),
      });

      // Remove from member's joinedTeamIds
      await _firestore.collection('users').doc(memberId).update({
        'joinedTeamIds': FieldValue.arrayRemove([teamId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get team by ID
  Future<TeamModel?> getTeam(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (!doc.exists) return null;
      return TeamModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting team: $e');
      return null;
    }
  }

  /// Get team stream
  Stream<TeamModel?> getTeamStream(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .snapshots()
        .map((doc) => doc.exists ? TeamModel.fromFirestore(doc) : null);
  }

  /// Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Get my teams stream
  Stream<List<TeamModel>> getMyTeams(List<String> teamIds) {
    if (teamIds.isEmpty) {
      return Stream.value([]);
    }

    // Firestore 'in' query supports up to 10 values.
    // If > 10, we might need multiple queries or client-side filtering.
    // Since Premium limit is 15, we might need to split.
    // For simplicity in this iteration, we'll fetch all teams where user is member.

    return _firestore
        .collection('teams')
        .where(
          'memberIds',
          arrayContains: _firestore.app.options.projectId == 'mock' ? '' : null,
        ) // Hack to get query builder
        .snapshots()
        .map((snapshot) {
          // Client side filter because 'in' limit is 10 and we have 15 max
          // Or we can use where('memberIds', arrayContains: uid)
          return [];
        });
  }

  /// Get teams where user is a member
  Stream<List<TeamModel>> getUserTeams(String uid) {
    return _firestore
        .collection('teams')
        .where('memberIds', arrayContains: uid)
        .where(
          'isHiddenDueToExpiry',
          isEqualTo: false,
        ) // Filter out hidden teams
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList(),
        );
  }

  // ============================================================================
  // TEAM ASSIGNMENTS
  // ============================================================================

  /// Create team assignment (OWNER ONLY)
  Future<String> assignTask(
    String ownerId,
    String teamId,
    String assignedToUid,
    TeamAssignmentModel assignment,
  ) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      final team = TeamModel.fromFirestore(teamDoc);

      // Validate owner
      if (!team.isOwner(ownerId)) {
        throw Exception('OWNER_ONLY');
      }

      // Validate assignee is a member
      if (!team.isMember(assignedToUid)) {
        throw Exception('User is not a team member');
      }

      final docRef = await _firestore
          .collection('team_assignments')
          .add(assignment.toFirestore());

      // Note: Assignment notification is now created in create_team_task_screen.dart
      // using NotificationHistoryService to ensure it appears in notification screen

      return docRef.id; // Return generated assignment ID
    } catch (e) {
      rethrow;
    }
  }

  /// Submit proof of work (photos)
  Future<void> submitTeamProof(
    String assignmentId,
    String photoBeforeBase64,
    String photoAfterBase64,
    String uid,
  ) async {
    try {
      final docRef = _firestore
          .collection('team_assignments')
          .doc(assignmentId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Assignment not found');
      }

      final assignment = TeamAssignmentModel.fromFirestore(doc);

      if (assignment.assignedToUid != uid) {
        throw Exception('Unauthorized: Not your assignment');
      }

      // CRITICAL: Check if user is still a member of the team
      // Users who left or were kicked cannot submit proof
      final teamDoc = await _firestore
          .collection('teams')
          .doc(assignment.teamId)
          .get();

      if (!teamDoc.exists) {
        throw Exception('Team tidak ditemukan');
      }

      final teamData = teamDoc.data()!;
      final memberIds = List<String>.from(teamData['memberIds'] ?? []);

      if (!memberIds.contains(uid)) {
        throw Exception(
          'Anda sudah tidak di team ini. Tidak dapat submit proof.',
        );
      }

      await docRef.update({
        'photoBeforeBase64': photoBeforeBase64,
        'photoAfterBase64': photoAfterBase64,
        'status': 'done',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get team assignments for a user
  Stream<List<TeamAssignmentModel>> getTeamAssignments(String userId) {
    return _firestore
        .collection('team_assignments')
        .where('assignedToUid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeamAssignmentModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get all team assignments (for owner dashboard)
  Stream<List<TeamAssignmentModel>> getAllTeamAssignments(String teamId) {
    return _firestore
        .collection('team_assignments')
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeamAssignmentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ============================================================================
  // AUTO-MAINTENANCE (THE BRAIN)
  // ============================================================================

  /// Run automatic maintenance to clean up old data
  /// RULE 1: Image Pruning (7 days) - Nullify photos in completed team assignments
  /// RULE 2: Task Deletion (7 days) - Delete old completed/overdue tasks
  /// RULE 3: Notification Cleanup (7 days) - Delete old notifications
  Future<MaintenanceResult> runAutoMaintenance(String uid) async {
    int deletedCount = 0;
    int prunedCount = 0;

    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // RULE 1: IMAGE PRUNING (7 DAYS)
      // Query team assignments that are done and older than 7 days
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final imagePruneQuery = await _firestore
          .collection('team_assignments')
          .where('assignedToUid', isEqualTo: uid)
          .where('status', isEqualTo: 'done')
          .where('completedAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      for (var doc in imagePruneQuery.docs) {
        final assignment = TeamAssignmentModel.fromFirestore(doc);
        // Only prune if photos exist
        if (assignment.photoBeforeBase64 != null ||
            assignment.photoAfterBase64 != null) {
          batch.update(doc.reference, {
            'photoBeforeBase64': null,
            'photoAfterBase64': null,
          });
          prunedCount++;
        }
      }

      // RULE 2: TASK DELETION (30 DAYS)
      // Note: We check shouldBeDeleted on each model instance

      // Delete old personal tasks
      final oldPersonalTasks = await _firestore
          .collection('personal_tasks')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in oldPersonalTasks.docs) {
        final task = TaskModel.fromFirestore(doc);
        if (task.shouldBeDeleted) {
          // CASCADE: Delete related notifications BEFORE deleting task
          try {
            await NotificationHistoryService().deleteNotificationsForTask(
              doc.id,
            );
            await NotificationScheduler.cancelTaskReminders(doc.id);
          } catch (e) {
            print('⚠️ Could not delete notifications for task ${doc.id}: $e');
          }

          batch.delete(doc.reference);
          deletedCount++;
          print('🗑️ Auto-deleted personal task: ${task.title}');
        }
      }

      // Delete old team assignments
      final oldTeamAssignments = await _firestore
          .collection('team_assignments')
          .where('assignedToUid', isEqualTo: uid)
          .get();

      for (var doc in oldTeamAssignments.docs) {
        final assignment = TeamAssignmentModel.fromFirestore(doc);
        if (assignment.shouldBeDeleted) {
          // CASCADE: Delete related data BEFORE deleting assignment
          try {
            // Record analytics for incomplete tasks (overdue + not done)
            final now = DateTime.now();
            final isOverdue =
                assignment.dueDateTime != null &&
                now.isAfter(assignment.dueDateTime!);
            if (!assignment.isCompleted && isOverdue) {
              try {
                await TeamAnalyticsService().recordTaskIncomplete(
                  teamId: assignment.teamId,
                  memberId: assignment.assignedToUid,
                  taskId: doc.id,
                );
                print('📊 Recorded incomplete task analytics');
              } catch (e) {
                print('⚠️ Analytics tracking failed: $e');
              }
            }

            // Delete notifications
            await NotificationHistoryService().deleteNotificationsForTask(
              doc.id,
            );
            await NotificationScheduler.cancelTaskReminders(doc.id);

            // Delete Appwrite photos
            await AppwriteService().deleteAllPhotosForTask(doc.id);
            print('🗑️ Deleted Appwrite photos for assignment ${doc.id}');
          } catch (e) {
            print(
              '⚠️ Could not delete cascade data for assignment ${doc.id}: $e',
            );
          }

          batch.delete(doc.reference);
          deletedCount++;
          print('🗑️ Auto-deleted team assignment: ${assignment.title}');
        }
      }

      // RULE 3: NOTIFICATION CLEANUP (7 DAYS)
      // Delete notifications older than 7 days to save storage
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('createdAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      int notifDeletedCount = 0;
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
        notifDeletedCount++;
      }

      // Commit all changes
      await batch.commit();

      print(
        'Maintenance completed: Deleted $deletedCount tasks, $notifDeletedCount notifications, Pruned $prunedCount images',
      );

      // Check and downgrade expired premium users
      await checkExpiredPremium();

      // Check and send premium expiry warnings
      await _checkPremiumExpiryWarnings(uid);

      return MaintenanceResult(
        deletedTasks: deletedCount,
        prunedImages: prunedCount,
      );
    } catch (e) {
      print('Error during maintenance: $e');
      return MaintenanceResult(deletedTasks: 0, prunedImages: 0);
    }
  }

  // ============================================================================
  // ADMIN FUNCTIONS
  // ============================================================================

  /// Search user by email
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first);
    } catch (e) {
      print('Error searching user by email: $e');
      return null;
    }
  }

  /// Search user by tenant ID
  Future<UserModel?> searchUserByTenantId(String tenantId) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('tenantId', isEqualTo: tenantId.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first);
    } catch (e) {
      print('Error searching user by tenant ID: $e');
      return null;
    }
  }

  /// Update user role (admin function)
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      if (newRole != 'free' && newRole != 'premium') {
        throw Exception('Invalid role. Must be "free" or "premium"');
      }

      await _firestore.collection('users').doc(uid).update({'role': newRole});
    } catch (e) {
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Ban user (Admin only)
  Future<void> banUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isBanned': true});
      print('✅ User $uid banned');
    } catch (e) {
      print('❌ Error banning user: $e');
      rethrow;
    }
  }

  /// Unban user (Admin only)
  Future<void> unbanUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isBanned': false});
      print('✅ User $uid unbanned');
    } catch (e) {
      print('❌ Error unbanning user: $e');
      rethrow;
    }
  }

  /// Upgrade user to premium with expiry (Admin only)
  /// @param durationMonths - number of months to add (1, 3, or 12)
  Future<void> upgradeToPremium(String uid, int durationMonths) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromFirestore(userDoc);

      final now = DateTime.now();
      final currentExpiry = user.premiumExpiresAt;

      // Calculate new expiry date
      final DateTime newExpiry;
      if (currentExpiry != null && currentExpiry.isAfter(now)) {
        // Extend from current expiry if still valid
        newExpiry = DateTime(
          currentExpiry.year,
          currentExpiry.month + durationMonths,
          currentExpiry.day,
        );
      } else {
        // Start from now if no valid expiry
        newExpiry = DateTime(now.year, now.month + durationMonths, now.day);
      }

      await _firestore.collection('users').doc(uid).update({
        'role': 'premium',
        'premiumExpiresAt': Timestamp.fromDate(newExpiry),
      });

      print('✅ User $uid upgraded to premium until ${newExpiry.toString()}');
    } catch (e) {
      print('❌ Error upgrading to premium: $e');
      rethrow;
    }
  }

  /// Check and downgrade expired premium users (called in maintenance)
  Future<void> checkExpiredPremium() async {
    try {
      final now = DateTime.now();

      final expiredUsersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'premium')
          .where('premiumExpiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      if (expiredUsersQuery.docs.isEmpty) {
        print('ℹ️ No expired premium users found');
        return;
      }

      print('🔄 Found ${expiredUsersQuery.docs.length} expired premium users');

      // Use downgrade service for each expired user
      final downgradeService = PremiumDowngradeService();
      for (var doc in expiredUsersQuery.docs) {
        await downgradeService.checkAndApplyDowngrade(doc.id);
      }

      print('✅ Processed ${expiredUsersQuery.docs.length} expired users');
    } catch (e) {
      print('❌ Error checking expired premium: $e');
    }
  }

  /// Restore hidden teams when user upgrades to premium
  Future<void> restoreTeamsOnUpgrade(String uid) async {
    await PremiumDowngradeService().restoreOwnedTeams(uid);
  }

  /// Check and send premium expiry warnings
  Future<void> _checkPremiumExpiryWarnings(String uid) async {
    try {
      await PremiumExpiryNotifier().checkAndNotifyExpiry(uid);
    } catch (e) {
      print('❌ Error checking premium expiry warnings: $e');
    }
  }
}
