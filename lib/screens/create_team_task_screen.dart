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

                    // Member List
                    ...widget.team.memberIds.map((memberId) {
                      return FutureBuilder<UserModel?>(
                        future: context.read<TeamProvider>().getUser(memberId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final member = snapshot.data!;
                          final isSelected = _selectedMemberId == memberId;

                          return Card(
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.blue[50] : null,
                            child: RadioListTile<String>(
                              value: memberId,
                              groupValue: _selectedMemberId,
                              onChanged: (value) {
                                setState(() => _selectedMemberId = value);
                              },
                              title: Text(
                                member.username,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(member.email),
                              secondary: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Colors.blue[700]
                                    : Colors.grey[400],
                                child: Text(
                                  member.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),

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
}
