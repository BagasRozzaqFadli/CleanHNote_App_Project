import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';
import '../screens/my_teams_screen.dart';

/// Free Plan Dashboard - Limited to 5 active tasks
class FreeDashboardScreen extends StatefulWidget {
  const FreeDashboardScreen({super.key});

  @override
  State<FreeDashboardScreen> createState() => _FreeDashboardScreenState();
}

class _FreeDashboardScreenState extends State<FreeDashboardScreen> {
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
        title: const Text('CleanHNote - Free Plan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
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
      body: Column(
        children: [
          // Upgrade Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.deepOrange[600]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Unlock unlimited tasks & team features',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact admin to upgrade to Premium'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                  ),
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
          // Tasks List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, const Color(0xFFE3F2FD)],
                ),
              ),
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
                  final activeTasks = tasks.where((t) => !t.isCompleted).length;

                  if (tasks.isEmpty) {
                    return _buildEmptyState(context, activeTasks);
                  }

                  return Column(
                    children: [
                      // Task Limit Indicator
                      if (activeTasks >= 3)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: activeTasks >= 5
                                ? Colors.red[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: activeTasks >= 5
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                activeTasks >= 5 ? Icons.block : Icons.warning,
                                color: activeTasks >= 5
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  activeTasks >= 5
                                      ? 'Task limit reached! Complete or delete tasks to add more.'
                                      : 'You have $activeTasks/5 active tasks',
                                  style: TextStyle(
                                    color: activeTasks >= 5
                                        ? Colors.red[900]
                                        : Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
          );
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String? email) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Free Plan'),
            accountEmail: Text(email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (email ?? 'U')[0].toUpperCase(),
                style: TextStyle(fontSize: 40.0, color: Colors.blue[600]),
              ),
            ),
            decoration: BoxDecoration(color: Colors.blue[600]),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Personal Tasks'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.group),
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int activeTasks) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (activeTasks < 5)
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTaskScreen(),
                ),
              ),
              child: const Text('Create Your First Task'),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, String uid) {
    final isOverdue = task.isOverdue;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: task.isCompleted
              ? Colors.green[100]
              : isOverdue
              ? Colors.red[100]
              : Colors.blue[100],
          child: Icon(
            task.isCompleted
                ? Icons.check
                : isOverdue
                ? Icons.warning
                : Icons.work,
            color: task.isCompleted
                ? Colors.green
                : isOverdue
                ? Colors.red
                : Colors.blue,
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
                _buildTag(
                  task.level ?? 'Easy',
                  Colors.purple[100]!,
                  Colors.purple[800]!,
                ),
                const SizedBox(width: 8),
                _buildTag(
                  task.priority ?? 'Medium',
                  Colors.orange[100]!,
                  Colors.orange[800]!,
                ),
                const SizedBox(width: 8),
                if (task.dueDate != null)
                  Text(
                    DateFormat('MMM d').format(task.dueDate!),
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!task.isCompleted)
              const PopupMenuItem(
                value: 'complete',
                child: Text('Mark Complete'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) async {
            if (value == 'complete') {
              await context.read<TaskProvider>().completeTask(task.id, uid);
            } else if (value == 'delete') {
              await context.read<TaskProvider>().deleteTask(task.id, uid);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
