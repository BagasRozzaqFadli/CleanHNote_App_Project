import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_assignment_model.dart';
import '../services/auth_service.dart';
import '../providers/team_provider.dart';
import '../widgets/countdown_badge.dart';
import 'edit_team_task_screen.dart';

/// Detail screen for team assignments with full operations
class TeamTaskDetailScreen extends StatelessWidget {
  final TeamAssignmentModel assignment;

  const TeamTaskDetailScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        assignment.dueDateTime != null &&
        assignment.dueDateTime!.isBefore(DateTime.now()) &&
        !assignment.isCompleted;
    final isFuture =
        assignment.dueDateTime != null &&
        assignment.dueDateTime!.isAfter(DateTime.now());
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Assignment Details'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          // Check if user is team owner (can edit/delete)
          FutureBuilder(
            future: _getTeamOwnerId(context),
            builder: (context, AsyncSnapshot<String?> snapshot) {
              final isOwner = snapshot.data == user?.uid;

              if (!isOwner) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _deleteAssignment(context);
                  } else if (value == 'edit') {
                    _editAssignment(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit Task', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Task',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
                  colors: assignment.isCompleted
                      ? [Colors.green[400]!, Colors.green[600]!]
                      : isOverdue
                      ? [Colors.red[400]!, Colors.red[600]!]
                      : [Colors.indigo[400]!, Colors.indigo[600]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        assignment.isCompleted
                            ? Icons.check_circle
                            : isOverdue
                            ? Icons.warning
                            : Icons.groups,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          assignment.title,
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
                    assignment.isCompleted
                        ? 'Completed'
                        : isOverdue
                        ? 'Overdue!'
                        : assignment.status == 'in_progress'
                        ? 'In Progress'
                        : 'Pending',
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
                  if (assignment.timeUntilDeletion != null || isFuture) ...[
                    if (assignment.timeUntilDeletion != null) ...[
                      Card(
                        elevation: 0,
                        color: Colors.red[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red[100]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_off_outlined,
                                    color: Colors.red[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Auto-Deletion Active',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This task will be permanently deleted in ${assignment.timeUntilDeletion!.inDays} days because it was completed late.',
                                style: TextStyle(color: Colors.red[900]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                                assignment.dueDateTime!.difference(
                                  DateTime.now(),
                                ),
                                Colors.indigo,
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Countdown to deletion
                            if (assignment.timeUntilDeletion != null)
                              CountdownBadge(
                                timeUntilDeletion: assignment.timeUntilDeletion,
                                countdownText: assignment.deletionCountdownText,
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
                          if (assignment.description != null &&
                              assignment.description!.isNotEmpty) ...[
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              assignment.description!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildInfoRow(
                            'Level',
                            assignment.level ?? 'Easy',
                            Icons.trending_up,
                          ),
                          _buildInfoRow(
                            'Priority',
                            assignment.priority ?? 'Medium',
                            Icons.flag,
                          ),
                          _buildInfoRow(
                            'Category',
                            assignment.category ?? 'General',
                            Icons.category,
                          ),
                          if (assignment.dueDate != null)
                            _buildInfoRow(
                              'Due Date',
                              DateFormat(
                                'EEEE, MMM d, yyyy',
                              ).format(assignment.dueDate!),
                              Icons.calendar_today,
                            ),
                          if (assignment.dueTime != null)
                            _buildInfoRow(
                              'Due Time',
                              assignment.dueTime!.format(context),
                              Icons.access_time,
                            ),
                          _buildInfoRow(
                            'Created',
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(assignment.createdAt),
                            Icons.add_circle_outline,
                          ),
                          if (assignment.completedAt != null)
                            _buildInfoRow(
                              'Completed',
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(assignment.completedAt!),
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
      bottomNavigationBar: !assignment.isCompleted
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _completeAssignment(context, user?.uid ?? ''),
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
          Icon(icon, size: 20, color: Colors.indigo[600]),
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

  Future<void> _completeAssignment(BuildContext context, String uid) async {
    // Team assignments require proof photos to complete
    // Show message directing user to submit proof instead
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Team assignments require proof photos. Please submit before/after photos to complete this assignment.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<String?> _getTeamOwnerId(BuildContext context) async {
    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(assignment.teamId)
          .get();

      if (teamDoc.exists) {
        return teamDoc.data()?['ownerId'];
      }
    } catch (e) {
      // Ignore error, just return null
    }
    return null;
  }

  Future<void> _deleteAssignment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'Are you sure you want to delete this team task? This action cannot be undone.',
        ),
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
        await context.read<TeamProvider>().deleteTeamAssignment(assignment.id);

        if (context.mounted) {
          Navigator.pop(context); // Go back to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Task deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editAssignment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTeamTaskScreen(assignment: assignment),
      ),
    );
  }
}
