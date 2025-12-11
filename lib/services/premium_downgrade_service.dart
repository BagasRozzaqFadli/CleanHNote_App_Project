import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service to handle real-time premium downgrade and enforcement
class PremiumDowngradeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and apply premium downgrade if expired
  /// Returns true if user was downgraded
  Future<bool> checkAndApplyDowngrade(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromFirestore(userDoc);

      // Check if premium and expired
      if (user.role == 'premium' &&
          user.premiumExpiresAt != null &&
          user.premiumExpiresAt!.isBefore(DateTime.now())) {
        print('⚡ Premium expired! Downgrading user: $uid');

        // 1. Downgrade user role
        await _firestore.collection('users').doc(uid).update({'role': 'free'});

        // 2. Hide all owned teams (not delete)
        await _hideOwnedTeams(uid);

        // 3. Delete excess personal tasks (keep newest 5)
        await _deleteExcessPersonalTasks(uid);

        // 4. Joined teams exceeding limit are kept (no action needed)

        print('✅ Downgrade completed for user: $uid');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error during downgrade: $e');
      return false;
    }
  }

  /// Hide all teams owned by user (set isHiddenDueToExpiry = true)
  Future<void> _hideOwnedTeams(String uid) async {
    try {
      final ownedTeams = await _firestore
          .collection('teams')
          .where('ownerId', isEqualTo: uid)
          .get();

      if (ownedTeams.docs.isEmpty) {
        print('  ℹ️ No owned teams to hide');
        return;
      }

      print('  🙈 Hiding ${ownedTeams.docs.length} owned teams...');

      final batch = _firestore.batch();
      for (var teamDoc in ownedTeams.docs) {
        batch.update(teamDoc.reference, {'isHiddenDueToExpiry': true});
      }
      await batch.commit();

      print('  ✅ Hidden ${ownedTeams.docs.length} teams');
    } catch (e) {
      print('  ❌ Error hiding teams: $e');
    }
  }

  /// Restore hidden teams when user upgrades back to premium
  Future<void> restoreOwnedTeams(String uid) async {
    try {
      final hiddenTeams = await _firestore
          .collection('teams')
          .where('ownerId', isEqualTo: uid)
          .where('isHiddenDueToExpiry', isEqualTo: true)
          .get();

      if (hiddenTeams.docs.isEmpty) {
        print('  ℹ️ No hidden teams to restore');
        return;
      }

      print('  👁️ Restoring ${hiddenTeams.docs.length} teams...');

      final batch = _firestore.batch();
      for (var teamDoc in hiddenTeams.docs) {
        batch.update(teamDoc.reference, {'isHiddenDueToExpiry': false});
      }
      await batch.commit();

      print('  ✅ Restored ${hiddenTeams.docs.length} teams');
    } catch (e) {
      print('  ❌ Error restoring teams: $e');
    }
  }

  /// Delete personal tasks exceeding free limit (keep newest 5)
  Future<void> _deleteExcessPersonalTasks(String uid) async {
    try {
      // Get all personal tasks ordered by creation date (newest first)
      final allTasks = await _firestore
          .collection('personal_tasks')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      final taskCount = allTasks.docs.length;
      const freeLimit = 5;

      if (taskCount <= freeLimit) {
        print('  ℹ️ Task count ($taskCount) within free limit');
        return;
      }

      final excessCount = taskCount - freeLimit;
      print(
        '  🗑️ Deleting $excessCount oldest tasks (keeping newest $freeLimit)...',
      );

      // Skip first 5 (newest), delete the rest (oldest)
      final tasksToDelete = allTasks.docs.skip(freeLimit).toList();

      final batch = _firestore.batch();
      for (var taskDoc in tasksToDelete) {
        batch.delete(taskDoc.reference);
      }
      await batch.commit();

      print('  ✅ Deleted $excessCount excess tasks');
    } catch (e) {
      print('  ❌ Error deleting excess tasks: $e');
    }
  }

  /// Validate premium access in real-time (for feature gates)
  Future<bool> validatePremiumAccess(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromFirestore(userDoc);

      // If expired, trigger downgrade
      if (user.role == 'premium' &&
          user.premiumExpiresAt != null &&
          user.premiumExpiresAt!.isBefore(DateTime.now())) {
        await checkAndApplyDowngrade(uid);
        return false;
      }

      return user.isPremium;
    } catch (e) {
      print('❌ Error validating premium: $e');
      return false;
    }
  }
}
