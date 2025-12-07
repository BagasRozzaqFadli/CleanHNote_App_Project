import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/team_model.dart';
import '../models/team_assignment_model.dart';
import '../models/user_model.dart';
import '../providers/team_provider.dart';
import '../services/auth_service.dart';
import '../services/image_helper.dart';

import 'create_team_task_screen.dart';
import '../widgets/assignment_card_widget.dart';

class TeamDashboardScreen extends StatefulWidget {
  final String teamId;

  const TeamDashboardScreen({super.key, required this.teamId});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  // Removed _isLoading as it was unused in the new logic

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<TeamModel?>(
      stream: context.read<TeamProvider>().getTeamStream(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final team = snapshot.data!;
        final isOwner = team.isOwner(user.uid);

        return Scaffold(
          appBar: AppBar(
            title: Text(team.name),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'leave') {
                    _confirmLeaveTeam(user.uid);
                  } else if (value == 'delete') {
                    _confirmDeleteTeam(user.uid);
                  }
                },
                itemBuilder: (context) => [
                  if (!isOwner)
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Leave Team',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  if (isOwner)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Team',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.blue[50],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (isOwner)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Invite Code: ${team.inviteCode}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code),
                              onPressed: () => _showQRCode(team.inviteCode),
                            ),
                          ],
                        ),
                      if (!isOwner)
                        Text(
                          'Member View',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Assignments'),
                    Tab(text: 'Members'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAssignmentsTab(user.uid, team, isOwner),
                      _buildMembersTab(user.uid, team, isOwner),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab(String uid, TeamModel team, bool isOwner) {
    // Owner sees all, Member sees only theirs
    final stream = isOwner
        ? context.read<TeamProvider>().getAllAssignments(team.id)
        : context.read<TeamProvider>().getMyAssignments(uid);

    return StreamBuilder<List<TeamAssignmentModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = snapshot.data ?? [];

        // Filter assignments for this specific team if using getMyAssignments (which returns all user's assignments)
        final teamAssignments = isOwner
            ? assignments
            : assignments.where((a) => a.teamId == team.id).toList();

        return Column(
          children: [
            if (isOwner)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTeamTaskScreen(team: team),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Assign New Task'),
                ),
              ),
            if (teamAssignments.isEmpty)
              const Expanded(child: Center(child: Text('No assignments yet')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: teamAssignments.length,
                  itemBuilder: (context, index) {
                    final task = teamAssignments[index];
                    return AssignmentCard(
                      task: task,
                      isOwner: isOwner,
                      currentUid: uid,
                      onSubmitProof: _showSubmitProofDialog,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMembersTab(String currentUid, TeamModel team, bool isOwner) {
    return ListView.builder(
      itemCount: team.memberIds.length,
      itemBuilder: (context, index) {
        final memberId = team.memberIds[index];
        return FutureBuilder<UserModel?>(
          future: context.read<TeamProvider>().getUser(memberId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListTile(title: Text('Loading...'));
            }
            final member = snapshot.data!;
            final isMe = member.uid == currentUid;
            final isMemberOwner = team.isOwner(member.uid);

            return ListTile(
              leading: CircleAvatar(child: Text(member.email[0].toUpperCase())),
              title: Text(member.email + (isMe ? ' (You)' : '')),
              subtitle: Text(isMemberOwner ? 'Owner' : 'Member'),
              trailing: (isOwner && !isMemberOwner)
                  ? IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: () => _kickMember(team.id, member.uid),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  // Actions

  Future<void> _confirmLeaveTeam(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<TeamProvider>().leaveTeam(uid, widget.teamId);
        if (mounted) {
          Navigator.pop(context); // Go back to MyTeams
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left team successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _confirmDeleteTeam(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text(
          'Are you sure you want to DELETE this team? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<TeamProvider>().deleteTeam(uid, widget.teamId);
        if (mounted) {
          Navigator.pop(context); // Go back to MyTeams
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _kickMember(String teamId, String memberId) async {
    try {
      final user = context.read<AuthService>().currentUser;
      await context.read<TeamProvider>().kickMember(
        user!.uid,
        teamId,
        memberId,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member kicked')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showQRCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubmitProofDialog(TeamAssignmentModel task) {
    File? beforeImage;
    File? afterImage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Submit Proof'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Before Photo'),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (picked != null) {
                      setState(() => beforeImage = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: beforeImage != null
                        ? Image.file(beforeImage!, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('After Photo'),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (picked != null) {
                      setState(() => afterImage = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: afterImage != null
                        ? Image.file(afterImage!, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (beforeImage == null || afterImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Both photos required')),
                        );
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        // Upload photos to Appwrite Documents
                        final beforeDocId =
                            await ImageHelper.uploadPhotoToAppwrite(
                              file: beforeImage!,
                              teamTaskId: task.id,
                              photoType: 'before',
                            );
                        final afterDocId =
                            await ImageHelper.uploadPhotoToAppwrite(
                              file: afterImage!,
                              teamTaskId: task.id,
                              photoType: 'after',
                            );

                        if (beforeDocId == null || afterDocId == null) {
                          throw Exception(
                            'Failed to upload photos to Appwrite',
                          );
                        }

                        // Mark task as complete (photos already in Appwrite)
                        final user = context.read<AuthService>().currentUser;
                        await context.read<TeamProvider>().submitProof(
                          task.id,
                          user!.uid,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Proof submitted to Appwrite!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        setState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
