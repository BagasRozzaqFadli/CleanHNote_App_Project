import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/premium_downgrade_service.dart';
import '../services/premium_expiry_notifier.dart';

/// Provider for personal task management with auto-maintenance
class TaskProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  MaintenanceResult? _maintenanceResult;
  bool _isInitialized = false;
  DateTime? _lastMaintenanceTime;

  // Run maintenance once per hour (reduced from 24 hours for premium expiry)
  static const _maintenanceInterval = Duration(hours: 1);

  MaintenanceResult? get maintenanceResult => _maintenanceResult;
  bool get isInitialized => _isInitialized;

  /// Initialize provider and run auto-maintenance if needed
  /// Maintenance runs once per day to clean up stale data
  Future<void> initialize(String uid) async {
    final now = DateTime.now();

    // Check if maintenance should run (first time or 24+ hours since last run)
    final shouldRunMaintenance =
        _lastMaintenanceTime == null ||
        now.difference(_lastMaintenanceTime!) >= _maintenanceInterval;

    if (!shouldRunMaintenance) {
      _isInitialized = true;
      return;
    }

    try {
      print('🧹 Running auto-maintenance (last run: $_lastMaintenanceTime)...');

      // Check for premium downgrade first
      final downgradeService = PremiumDowngradeService();
      await downgradeService.checkAndApplyDowngrade(uid);

      // Check for premium expiry warnings
      final expiryNotifier = PremiumExpiryNotifier();
      await expiryNotifier.checkAndNotifyExpiry(uid);

      // Run regular maintenance
      _maintenanceResult = await _dbService.runAutoMaintenance(uid);
      _lastMaintenanceTime = now;
      print('✅ Maintenance result: $_maintenanceResult');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('❌ Error during maintenance: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Create personal task with free plan limit enforcement
  Future<String> createTask(TaskModel task, String uid) async {
    try {
      final taskId = await _dbService.createPersonalTask(task, uid);
      notifyListeners();
      return taskId;
    } catch (e) {
      rethrow;
    }
  }

  /// Update task
  Future<void> updateTask(
    String taskId,
    Map<String, dynamic> updates,
    String uid,
  ) async {
    try {
      await _dbService.updatePersonalTask(taskId, updates, uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId, String uid) async {
    try {
      await _dbService.deletePersonalTask(taskId, uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get tasks stream
  Stream<List<TaskModel>> getTasks(String uid) {
    return _dbService.getPersonalTasks(uid);
  }

  /// Mark task as complete
  Future<void> completeTask(String taskId, String uid) async {
    try {
      await _dbService.updatePersonalTask(taskId, {
        'isCompleted': true,
        'completedAt': DateTime.now(),
      }, uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Clear maintenance result (after showing notification)
  void clearMaintenanceResult() {
    _maintenanceResult = null;
    notifyListeners();
  }
}
