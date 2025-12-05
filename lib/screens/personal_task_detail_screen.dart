import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/auth_service.dart';
import '../widgets/countdown_badge.dart';
import 'edit_personal_task_screen.dart';

/// Detail screen for personal tasks with full CRUD operations
class PersonalTaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const PersonalTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isFuture =
        task.dueDateTime != null && task.dueDateTime!.isAfter(DateTime.now());
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPersonalTaskScreen(task: task),
                ),
              );
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, user?.uid ?? ''),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: task.isCompleted
                      ? [Colors.green[400]!, Colors.green[600]!]
                      : isOverdue
                      ? [Colors.red[400]!, Colors.red[600]!]
                      : [Colors.blue[400]!, Colors.blue[600]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : isOverdue
                            ? Icons.warning
                            : Icons.pending_actions,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.isCompleted
                        ? 'Completed'
                        : isOverdue
                        ? 'Overdue!'
                        : 'In Progress',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown Badges Section
                  if (task.timeUntilDeletion != null || isFuture) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⏱️ Countdowns',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Countdown to start
                            if (isFuture) ...[
                              _buildCountdownItem(
                                context,
                                'Time until task starts',
                                task.dueDateTime!.difference(DateTime.now()),
                                Colors.blue,
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Countdown to deletion
                            if (task.timeUntilDeletion != null)
                              CountdownBadge(
                                timeUntilDeletion: task.timeUntilDeletion,
                                countdownText: task.deletionCountdownText,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Task Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          if (task.description != null &&
                              task.description!.isNotEmpty) ...[
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.description!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildInfoRow(
                            'Level',
                            task.level ?? 'Easy',
                            Icons.trending_up,
                          ),
                          _buildInfoRow(
                            'Priority',
                            task.priority ?? 'Medium',
                            Icons.flag,
                          ),
                          _buildInfoRow(
                            'Category',
                            task.category ?? 'General',
                            Icons.category,
                          ),
                          if (task.dueDate != null)
                            _buildInfoRow(
                              'Due Date',
                              DateFormat(
                                'EEEE, MMM d, yyyy',
                              ).format(task.dueDate!),
                              Icons.calendar_today,
                            ),
                          if (task.dueTime != null)
                            _buildInfoRow(
                              'Due Time',
                              task.dueTime!.format(context),
                              Icons.access_time,
                            ),
                          _buildInfoRow(
                            'Created',
                            DateFormat('MMM d, yyyy').format(task.createdAt),
                            Icons.add_circle_outline,
                          ),
                          if (task.completedAt != null)
                            _buildInfoRow(
                              'Completed',
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(task.completedAt!),
                              Icons.check_circle_outline,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !task.isCompleted
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _completeTask(context, user?.uid ?? ''),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownItem(
    BuildContext context,
    String label,
    Duration duration,
    Color color,
  ) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  days > 0
                      ? '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}'
                      : hours > 0
                      ? '$hours hour${hours == 1 ? '' : 's'}, $minutes min'
                      : '$minutes minute${minutes == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTask(BuildContext context, String uid) async {
    try {
      await context.read<TaskProvider>().completeTask(task.id, uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked as complete!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TaskProvider>().deleteTask(task.id, uid);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Task deleted')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
