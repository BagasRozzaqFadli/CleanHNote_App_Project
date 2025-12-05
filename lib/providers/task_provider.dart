import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

/// Provider for personal task management with auto-maintenance
class TaskProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  MaintenanceResult? _maintenanceResult;
  bool _isInitialized = false;

  MaintenanceResult? get maintenanceResult => _maintenanceResult;
  bool get isInitialized => _isInitialized;

  /// Initialize provider and run auto-maintenance
  Future<void> initialize(String uid) async {
    if (_isInitialized) return;

    try {
      print('Running auto-maintenance...');
      _maintenanceResult = await _dbService.runAutoMaintenance(uid);
      print('Maintenance result: $_maintenanceResult');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error during initialization: $e');
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
