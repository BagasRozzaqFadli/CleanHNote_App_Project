import 'package:flutter/material.dart';
import '../models/team_assignment_model.dart';
import '../screens/team_task_detail_screen.dart';
import '../services/image_helper.dart';
import '../services/appwrite_service.dart';

class AssignmentCard extends StatefulWidget {
  final TeamAssignmentModel task;
  final bool isOwner;
  final String currentUid;
  final Function(TeamAssignmentModel) onSubmitProof;

  const AssignmentCard({
    super.key,
    required this.task,
    required this.isOwner,
    required this.currentUid,
    required this.onSubmitProof,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> {
  bool _isExpanded = false;

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamTaskDetailScreen(assignment: widget.task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this task needs a badge
    final showBadge = widget.isOwner
        ? widget.task.needsOwnerReview
        : widget.task.needsMemberReview;

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (widget.task.isCompleted) {
      if (widget.task.wasCompletedLate) {
        // Completed late
        statusColor = Colors.orange;
        statusIcon = Icons.done_outline;
        statusLabel = 'Completed Late';
      } else {
        // Completed on time
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Completed';
      }
    } else {
      // Not completed
      final now = DateTime.now();
      final isOverdue =
          widget.task.dueDateTime != null &&
          now.isAfter(widget.task.dueDateTime!);

      if (isOverdue) {
        // Overdue and not done
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusLabel = 'Overdue';
      } else {
        // Pending
        statusColor = Colors.blue;
        statusIcon = Icons.pending_actions;
        statusLabel = 'Pending';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header Row (Clickable for Navigation)
          InkWell(
            onTap: _navigateToDetail,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Status Icon with Badge
                  Stack(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      // Red badge for unviewed tasks
                      if (showBadge)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Title & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: statusColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            if (showBadge) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.isOwner ? 'Review' : 'New',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Button (The only trigger for expansion)
                  IconButton(
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        if (widget.task.description != null) ...[
                          Text(
                            widget.task.description!,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          'Priority: ${widget.task.priority} | Level: ${widget.task.level}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Proof Section
                        if (widget.task.isCompleted) ...[
                          const Text(
                            'Proof of Work:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<Map<String, String?>>(
                            future: AppwriteService().getBothPhotos(
                              widget.task.id,
                            ),
                            builder: (context, snapshot) {
                              // Get photos from Appwrite or fallback to Firestore
                              final beforePhoto =
                                  snapshot.hasData &&
                                      snapshot.data!['before'] != null
                                  ? snapshot.data!['before']
                                  : widget.task.photoBeforeBase64;
                              final afterPhoto =
                                  snapshot.hasData &&
                                      snapshot.data!['after'] != null
                                  ? snapshot.data!['after']
                                  : widget.task.photoAfterBase64;

                              return Row(
                                children: [
                                  _buildProofThumbnail('Before', beforePhoto),
                                  const SizedBox(width: 8),
                                  _buildProofThumbnail('After', afterPhoto),
                                ],
                              );
                            },
                          ),
                        ] else if (!widget.isOwner &&
                            widget.task.assignedToUid == widget.currentUid) ...[
                          ElevatedButton.icon(
                            onPressed: () => widget.onSubmitProof(widget.task),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Submit Proof (Complete)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _navigateToDetail,
                          child: const Text('View Full Details'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProofThumbnail(String label, String? base64) {
    if (base64 == null) return const SizedBox.shrink();
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                ImageHelper.decodeBase64(base64)!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
