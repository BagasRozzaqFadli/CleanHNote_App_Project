import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team_model.dart';
import '../models/team_assignment_model.dart';
import '../models/user_model.dart';
import '../models/notification_history_model.dart';
import '../providers/team_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_history_service.dart';
import '../widgets/task_time_picker.dart';

class CreateTeamTaskScreen extends StatefulWidget {
  final TeamModel team;

  const CreateTeamTaskScreen({super.key, required this.team});

  @override
  State<CreateTeamTaskScreen> createState() => _CreateTeamTaskScreenState();
}

class _CreateTeamTaskScreenState extends State<CreateTeamTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _level = 'Easy';
  String _priority = 'Medium';
  String _category = 'General';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _selectedMemberId;
  bool _isLoading = false;

  final List<String> _levels = ['Easy', 'Hard'];
  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _categories = [
    'General',
    'Cleaning',
    'Maintenance',
    'Organization',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
      return;
    }
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team member')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) throw Exception('User not logged in');

      final assignment = TeamAssignmentModel(
        id: '',
        teamId: widget.team.id,
        assignedToUid: _selectedMemberId!,
        assignedByUid: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        level: _level,
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        dueTime: _dueTime,
        createdAt: DateTime.now(),
      );

      final assignmentId = await context.read<TeamProvider>().assignTask(
        user.uid,
        widget.team.id,
        _selectedMemberId!,
        assignment,
      );

      // Create IMMEDIATE assignment notification
      try {
        await NotificationHistoryService().createNotificationHistory(
          NotificationHistoryModel(
            id: '',
            userId: _selectedMemberId!, // Member receives notification
            taskId: assignmentId,
            taskTitle: assignment.title,
            notificationType: 'assigned', // Special type for assignment
            scheduledFor: DateTime.now(), // Shows immediately
            createdAt: DateTime.now(),
            shown: false,
            teamId: widget.team.id,
            assignmentId: assignmentId,
          ),
        );
        print('✅ Immediate assignment notification created');
      } catch (e) {
        print('⚠️ Failed to create assignment notification: $e');
      }

      // Create notification history entries if date and time are set
      if (_dueDate != null && _dueTime != null) {
        try {
          final dueDateTime = DateTime(
            _dueDate!.year,
            _dueDate!.month,
            _dueDate!.day,
            _dueTime!.hour,
            _dueTime!.minute,
          );

          await NotificationHistoryService().createTaskNotifications(
            userId:
                _selectedMemberId!, // ✅ MEMBER yang ditugaskan (bukan owner!)
            taskId: assignmentId, // ✅ Use the captured assignment ID
            taskTitle: assignment.title,
            dueDateTime: dueDateTime,
            teamId: widget.team.id, // ✅ Team context
            assignmentId: assignmentId, // ✅ Assignment reference
          );
          print('✅ Notification histories created for team task');
        } catch (e) {
          print('⚠️ Failed to create notification histories: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Gradient App Bar
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Assign Team Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[700]!, Colors.purple[600]!],
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Team Name Badge
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.group, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              widget.team.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Level and Priority Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _level,
                            decoration: const InputDecoration(
                              labelText: 'Level',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.bar_chart),
                            ),
                            items: _levels.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() => _level = newValue!);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: _priorities.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() => _priority = newValue!);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _category = newValue!);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date and Time Picker
                    TaskTimePicker(
                      selectedDate: _dueDate,
                      selectedTime: _dueTime,
                      onDateChanged: (date) => setState(() => _dueDate = date),
                      onTimeChanged: (time) => setState(() => _dueTime = time),
                    ),

                    const SizedBox(height: 16),

                    // Member Selection
                    const Text(
                      'Assign To:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Modern Member Selector Card
                    _buildMemberSelector(),

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Assign Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelector() {
    return FutureBuilder<UserModel?>(
      future: _selectedMemberId != null
          ? context.read<TeamProvider>().getUser(_selectedMemberId!)
          : Future.value(null),
      builder: (context, snapshot) {
        final selectedUser = snapshot.data;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade100),
          ),
          child: InkWell(
            onTap: _showMemberSelectionDialog,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedUser != null
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: selectedUser != null
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedUser != null
                              ? selectedUser.username
                              : 'Select Team Member',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedUser != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (selectedUser != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            selectedUser.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMemberSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Member'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search member...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: FutureBuilder<List<UserModel?>>(
                        future: Future.wait(
                          widget.team.memberIds.map(
                            (id) => context.read<TeamProvider>().getUser(id),
                          ),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          var members = (snapshot.data ?? [])
                              .whereType<UserModel>()
                              .toList();

                          if (searchQuery.isNotEmpty) {
                            members = members.where((m) {
                              return m.username
                                      .toLowerCase()
                                      .contains(searchQuery) ||
                                  m.email.toLowerCase().contains(searchQuery);
                            }).toList();
                          }

                          if (members.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No members found'),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: members.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final isSelected =
                                  _selectedMemberId == member.uid;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    member.username.isNotEmpty
                                        ? member.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  member.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(member.email),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedMemberId = member.uid;
                                  });
                                  Navigator.pop(context);
                                },
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
              ],
            );
          },
        );
      },
    );
  }
}
