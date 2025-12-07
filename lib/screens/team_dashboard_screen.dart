import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../features/analytics/screens/team_info_screen.dart';

class TeamDashboardScreen extends StatefulWidget {
  final String teamId;
  const TeamDashboardScreen({super.key, required this.teamId});
  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
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
            length: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.blue[50],
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.vpn_key_rounded,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Invite Code',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      team.inviteCode,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                        letterSpacing: 3,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Material(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: InkWell(
                                              onTap: () => _copyInviteCode(
                                                team.inviteCode,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.copy_rounded,
                                                      color: Colors.green[700],
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Copy',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.green[700],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Material(
                                            color: Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  _showQRCode(team.inviteCode),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_2_rounded,
                                                      color: Colors.purple[700],
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'QR',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.purple[700],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Member View',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Assignments'),
                    Tab(text: 'Members'),
                    Tab(text: 'Team Info'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAssignmentsTab(user.uid, team, isOwner),
                      _buildMembersTab(user.uid, team, isOwner),
                      TeamInfoScreen(teamId: widget.teamId),
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isMemberOwner
                      ? Colors.amber.shade100
                      : Colors.blue.shade100,
                  child: Text(
                    member.username.isNotEmpty
                        ? member.username[0].toUpperCase()
                        : member.email[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMemberOwner
                          ? Colors.amber.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.username.isNotEmpty
                            ? member.username
                            : member.email.split('@')[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${member.email} • ${isMemberOwner ? "Owner" : "Member"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: (isOwner && !isMemberOwner)
                    ? IconButton(
                        icon: const Icon(
                          Icons.person_remove,
                          color: Colors.red,
                        ),
                        onPressed: () => _kickMember(team.id, member.uid),
                        tooltip: 'Remove member',
                      )
                    : (isMemberOwner
                          ? Icon(
                              Icons.star,
                              color: Colors.amber.shade700,
                              size: 20,
                            )
                          : null),
              ),
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
          Navigator.pop(context);
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
          Navigator.pop(context);
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
    final member = await context.read<TeamProvider>().getUser(memberId);
    if (member == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.username.isNotEmpty ? member.username : member.email} from this team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final user = context.read<AuthService>().currentUser;
      await context.read<TeamProvider>().kickMember(
        user!.uid,
        teamId,
        memberId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showQRCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team Invite QR Code'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 220.0,
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

  void _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Code "$code" copied!')),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        beforeImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: beforeImage == null
                        ? const Center(child: Icon(Icons.camera_alt, size: 50))
                        : Image.file(beforeImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('After Photo'),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        afterImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: afterImage == null
                        ? const Center(child: Icon(Icons.camera_alt, size: 50))
                        : Image.file(afterImage!, fit: BoxFit.cover),
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
              onPressed:
                  (beforeImage == null || afterImage == null || isSubmitting)
                  ? null
                  : () async {
                      setState(() {
                        isSubmitting = true;
                      });
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
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proof submitted successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        setState(() {
                          isSubmitting = false;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
