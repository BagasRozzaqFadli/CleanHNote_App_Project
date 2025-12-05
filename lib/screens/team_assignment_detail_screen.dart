import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/team_assignment_model.dart';
import '../providers/team_provider.dart';
import '../services/auth_service.dart';
import '../widgets/countdown_badge.dart';

/// Premium detail screen for team assignments
class TeamAssignmentDetailScreen extends StatelessWidget {
  final TeamAssignmentModel assignment;
  final bool isOwner;

  const TeamAssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final isAssignedToMe = user?.uid == assignment.assignedToUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, assignment.teamId),
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
                  colors: assignment.status == 'completed'
                      ? [Colors.green[400]!, Colors.green[600]!]
                      : assignment.status == 'in-progress'
                      ? [Colors.blue[400]!, Colors.blue[600]!]
                      : [Colors.orange[400]!, Colors.orange[600]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        assignment.status == 'completed'
                            ? Icons.check_circle
                            : assignment.status == 'in-progress'
                            ? Icons.play_circle
                            : Icons.pending,
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
                    'Status: ${assignment.status}',
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
                  // Countdown Section
                  if (assignment.timeUntilDeletion != null) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⏱️ Auto-Delete Countdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
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

                  // Assignment Info
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
                  const SizedBox(height: 16),

                  // Photo Proof Section (for assigned member)
                  if (isAssignedToMe && assignment.status != 'completed')
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📸 Submit Proof',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload before & after photos to complete this task',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement photo upload
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Photo upload feature coming soon!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Upload Photos'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[700],
                                foregroundColor: Colors.white,
                              ),
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
      bottomNavigationBar: isAssignedToMe && assignment.status != 'completed'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _markInProgress(context),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    assignment.status == 'in-progress'
                        ? 'Already In Progress'
                        : 'Start Working',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: assignment.status == 'in-progress'
                        ? Colors.grey
                        : Colors.blue[700],
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

  Future<void> _markInProgress(BuildContext context) async {
    if (assignment.status == 'in-progress') return;

    try {
      await context.read<TeamProvider>().updateAssignmentStatus(
        assignment.teamId,
        assignment.id,
        'in-progress',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated to In Progress!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: const Text('Are you sure you want to delete this assignment?'),
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
        // TODO: Implement delete assignment
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete feature coming soon!')),
        );
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
