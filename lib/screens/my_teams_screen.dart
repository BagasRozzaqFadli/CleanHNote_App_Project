import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../providers/team_provider.dart';
import '../services/auth_service.dart';
import 'team_dashboard_screen.dart';
import 'qr_scanner_screen.dart';
import 'create_team_screen.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  final _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: context.read<TeamProvider>().getUserStream(user.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final fullUser = userSnapshot.data;
          if (fullUser == null) {
            return const Center(child: Text('User not found'));
          }

          return Column(
            children: [
              // Team Limit Info
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Joined Teams: ${fullUser.joinedTeamIds.length} / ${fullUser.isPremium ? 15 : 3}',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Teams List
              Expanded(
                child: StreamBuilder<List<TeamModel>>(
                  stream: context.read<TeamProvider>().getUserTeams(user.uid),
                  builder: (context, teamSnapshot) {
                    if (teamSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teams = teamSnapshot.data ?? [];

                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You haven\'t joined any teams yet.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final isOwner = team.isOwner(user.uid);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isOwner
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                              child: Icon(
                                isOwner ? Icons.star : Icons.group,
                                color: isOwner
                                    ? Colors.green[800]
                                    : Colors.blue[800],
                              ),
                            ),
                            title: Text(
                              team.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${team.memberIds.length} members'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TeamDashboardScreen(teamId: team.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<UserModel?>(
        stream: context.read<TeamProvider>().getUserStream(user.uid),
        builder: (context, snapshot) {
          final fullUser = snapshot.data;
          // Show FAB if user is loaded
          if (fullUser == null) return const SizedBox.shrink();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Create Team Button (Premium Only)
              if (fullUser.isPremium)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FloatingActionButton.extended(
                    heroTag: 'create',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTeamScreen(),
                        ),
                      );
                    },
                    label: const Text('Create Team'),
                    icon: const Icon(Icons.add_business),
                    backgroundColor: Colors.green,
                  ),
                ),

              // Join Team Button (Everyone)
              FloatingActionButton.extended(
                heroTag: 'join',
                onPressed: () => _showJoinDialog(context, user.uid),
                label: const Text('Join Team'),
                icon: const Icon(Icons.group_add),
                backgroundColor: Colors.blue[600],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showJoinDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter Invite Code',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _joinCodeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _joinTeam(uid);
                },
                child: const Text('Join Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinTeam(String uid) async {
    if (_joinCodeController.text.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<TeamProvider>().joinTeam(
        uid,
        _joinCodeController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined team!')),
        );
        _joinCodeController.clear();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
