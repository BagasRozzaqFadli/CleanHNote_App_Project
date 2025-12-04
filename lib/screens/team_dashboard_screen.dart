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
                  onPressed: () => _showAssignTaskDialog(team),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text('Status: ${task.status}'),
                        trailing: task.isCompleted
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.pending, color: Colors.orange),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (task.description != null)
                                  Text('Description: ${task.description}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Priority: ${task.priority} | Level: ${task.level}',
                                ),
                                const SizedBox(height: 16),
                                if (task.isCompleted) ...[
                                  const Text(
                                    'Proof of Work:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (task.photoBeforeBase64 != null)
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text('Before'),
                                              _buildProofImage(
                                                task.photoBeforeBase64!,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (task.photoAfterBase64 != null)
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text('After'),
                                              _buildProofImage(
                                                task.photoAfterBase64!,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ] else if (!isOwner &&
                                    task.assignedToUid == uid) ...[
                                  ElevatedButton(
                                    onPressed: () =>
                                        _showSubmitProofDialog(task),
                                    child: const Text(
                                      'Submit Proof (Complete Task)',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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

  void _showAssignTaskDialog(TeamModel team) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedMemberId;
    String level = 'Easy';
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  items: ['Easy', 'Hard']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => level = v!,
                  decoration: const InputDecoration(labelText: 'Level'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: ['Low', 'Medium', 'High']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => priority = v!,
                  decoration: const InputDecoration(labelText: 'Priority'),
                ),
                const SizedBox(height: 16),
                const Text('Assign To:'),
                SizedBox(
                  height: 100,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: team.memberIds.length,
                    itemBuilder: (context, index) {
                      final memberId = team.memberIds[index];
                      // Allow assigning to self or others
                      return FutureBuilder<UserModel?>(
                        future: context.read<TeamProvider>().getUser(memberId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final member = snapshot.data!;
                          return RadioListTile<String>(
                            title: Text(member.email),
                            value: memberId,
                            groupValue: selectedMemberId,
                            onChanged: (v) =>
                                setState(() => selectedMemberId = v),
                          );
                        },
                      );
                    },
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
              onPressed: () async {
                if (selectedMemberId == null || titleController.text.isEmpty) {
                  return;
                }
                try {
                  final user = context.read<AuthService>().currentUser;
                  final assignment = TeamAssignmentModel(
                    id: '',
                    teamId: team.id,
                    assignedToUid: selectedMemberId!,
                    assignedByUid: user!.uid,
                    title: titleController.text,
                    description: descController.text,
                    level: level,
                    priority: priority,
                    createdAt: DateTime.now(),
                  );
                  await context.read<TeamProvider>().assignTask(
                    user.uid,
                    team.id,
                    selectedMemberId!,
                    assignment,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task Assigned')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
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
                        final beforeBase64 =
                            await ImageHelper.compressAndConvert(beforeImage!);
                        final afterBase64 =
                            await ImageHelper.compressAndConvert(afterImage!);

                        if (beforeBase64 == null || afterBase64 == null) {
                          throw Exception('Image compression failed');
                        }

                        final user = context.read<AuthService>().currentUser;
                        await context.read<TeamProvider>().submitProof(
                          task.id,
                          beforeBase64,
                          afterBase64,
                          user!.uid,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proof Submitted!')),
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

  Widget _buildProofImage(String base64String) {
    final bytes = ImageHelper.decodeBase64(base64String);
    if (bytes == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
    return Image.memory(bytes, height: 100, fit: BoxFit.cover);
  }
}
