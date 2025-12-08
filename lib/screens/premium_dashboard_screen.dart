import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'create_task_screen.dart';
import '../services/notification_history_service.dart';
import '../services/notification_scheduler.dart';
import '../screens/notifications_screen.dart';
import '../screens/my_teams_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/local_time_widget.dart';
import 'personal_task_detail_screen.dart';
import '../providers/team_provider.dart';
import '../widgets/task_limit_card.dart';

/// Premium Plan Dashboard - Unlimited tasks with team features
class PremiumDashboardScreen extends StatefulWidget {
  const PremiumDashboardScreen({super.key});
  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.initialize(user.uid);
      if (taskProvider.maintenanceResult != null && mounted) {
        final result = taskProvider.maintenanceResult!;
        if (result.deletedTasks > 0 || result.prunedImages > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Auto-Maintenance: Deleted ${result.deletedTasks} old tasks, Pruned ${result.prunedImages} images.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          taskProvider.clearMaintenanceResult();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('CleanHNote'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        // Add badge to hamburger menu
        leading: StreamBuilder<int>(
          stream: context.read<TeamProvider>().getCombinedUnviewedCount(
            user.uid,
          ),
          builder: (context, snapshot) {
            final teamBadgeCount = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                if (teamBadgeCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        teamBadgeCount > 9 ? '9+' : '$teamBadgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          StreamBuilder<int>(
            key: ValueKey('badge_$_refreshKey'),
            stream: NotificationHistoryService().getUnshownCount(user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              print(
                '🎯 [Premium Dashboard] Badge StreamBuilder rebuild - count: $unreadCount',
              );
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, user.email),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.indigo[50]!],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger a rebuild
            await Future.delayed(const Duration(milliseconds: 500));
            if (context.mounted) {
              await context.read<TaskProvider>().initialize(user.uid);
              // Force rebuild to refresh notification badge
              if (mounted) {
                setState(() {
                  _refreshKey++;
                  print('🔄 [Premium Refresh] Key updated to: $_refreshKey');
                });
              }
            }
          },
          child: StreamBuilder<List<TaskModel>>(
            stream: context.read<TaskProvider>().getTasks(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data ?? [];
              final totalTasks =
                  tasks.length; // Count ALL tasks including completed

              return Column(
                children: [
                  // Task Limit Indicator Card - Always visible
                  TaskLimitCard(currentCount: totalTasks, isPremium: true),
                  // Tasks List or Empty State
                  Expanded(
                    child: tasks.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) =>
                                _buildTaskCard(context, tasks[index], user.uid),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      // TEMPORARY: Cleanup button - REVERT TO CREATE TASK AFTER CLEANUP!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🧹 Starting cleanup...')),
            );
            await context.read<TeamProvider>().cleanupOrphanedTeamIds();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Cleanup selesai! Cek console untuk detail.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.cleaning_services),
        label: const Text('CLEANUP'),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String? email) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Username in Drawer Header with StreamBuilder
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(context.read<AuthService>().currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String displayName = email ?? '';
              if (snapshot.hasData && snapshot.data != null) {
                final userModel = UserModel.fromFirestore(snapshot.data!);
                displayName = userModel.username;
              }
              return UserAccountsDrawerHeader(
                accountName: Row(
                  children: [
                    Text(displayName),
                    const SizedBox(width: 8),
                    Icon(Icons.star, color: Colors.amber[300], size: 20),
                  ],
                ),
                accountEmail: Text(email ?? ''),
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 40.0,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ),
                ),
                decoration: BoxDecoration(color: Colors.indigo[700]),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const LocalTimeWidget(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Personal Tasks'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.group),
                // Badge for My Teams
                StreamBuilder<int>(
                  stream: context.read<TeamProvider>().getCombinedUnviewedCount(
                    context.read<AuthService>().currentUser!.uid,
                  ),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            title: const Text('My Teams'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTeamsScreen()),
              );
            },
          ),
          const Divider(),
          // Test Notifications Button
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Check Notifications'),
            onTap: () async {
              Navigator.pop(context);
              await NotificationScheduler.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Test notification sent!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await context.read<AuthService>().signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tasks yet!',
                style: TextStyle(fontSize: 24, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTaskScreen(),
                    ),
                  );
                },
                child: const Text('Create Your First Task'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, String uid) {
    final isOverdue =
        task.dueDateTime != null &&
        task.dueDateTime!.isBefore(DateTime.now()) &&
        !task.isCompleted;
    final backgroundColor = task.isCompleted
        ? Colors.green[50]
        : isOverdue
        ? Colors.red[50]
        : Colors.white;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalTaskDetailScreen(task: task),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: task.isCompleted
              ? Colors.green
              : isOverdue
              ? Colors.red
              : Colors.blue,
          child: Icon(
            task.isCompleted
                ? Icons.check_circle
                : isOverdue
                ? Icons.warning
                : Icons.task_alt,
            color: Colors.white,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (task.dueDateTime != null) ...[
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(task.dueDateTime!),
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[700],
                      fontWeight: isOverdue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        tileColor: backgroundColor,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              await context.read<TaskProvider>().deleteTask(task.id, uid);
            } else if (value == 'toggle') {
              // Toggle completion status
              await context.read<TaskProvider>().updateTask(task.id, {
                'isCompleted': !task.isCompleted,
                if (!task.isCompleted) 'completedAt': DateTime.now(),
              }, uid);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(
                task.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
              ),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
