import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team_assignment_model.dart';
import '../providers/team_provider.dart';
import '../services/notification_history_service.dart';
import '../widgets/task_time_picker.dart';

class EditTeamTaskScreen extends StatefulWidget {
  final TeamAssignmentModel assignment;

  const EditTeamTaskScreen({super.key, required this.assignment});

  @override
  State<EditTeamTaskScreen> createState() => _EditTeamTaskScreenState();
}

class _EditTeamTaskScreenState extends State<EditTeamTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late String _level;
  late String _priority;
  late String _category;
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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _descriptionController = TextEditingController(
      text: widget.assignment.description,
    );
    _level = widget.assignment.level ?? 'Easy';
    _priority = widget.assignment.priority ?? 'Medium';
    _category = widget.assignment.category ?? 'General';
    _dueDate = widget.assignment.dueDate;
    _dueTime = widget.assignment.dueTime; // Already TimeOfDay

    _selectedMemberId = widget.assignment.assignedToUid;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'level': _level,
        'priority': _priority,
        'category': _category,
        'dueDate': _dueDate,
        'dueTime': _dueTime != null
            ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
            : null,
      };

      // If member changed, update assignedToUid (handling this might require re-notification logic, for now simple update)
      if (_selectedMemberId != null &&
          _selectedMemberId != widget.assignment.assignedToUid) {
        updates['assignedToUid'] = _selectedMemberId!;
      }

      await context.read<TeamProvider>().updateTeamAssignment(
        widget.assignment.id,
        updates,
      );

      // Update notification histories if due date/time changed
      if (_dueDate != null && _dueTime != null) {
        try {
          // Delete old notification histories
          await NotificationHistoryService().deleteNotificationsForTask(
            widget.assignment.id,
          );

          // Create new notification histories with updated time
          final dueDateTime = DateTime(
            _dueDate!.year,
            _dueDate!.month,
            _dueDate!.day,
            _dueTime!.hour,
            _dueTime!.minute,
          );

          await NotificationHistoryService().createTaskNotifications(
            userId: widget.assignment.assignedToUid, // ✅ Member yang ditugaskan
            taskId: widget.assignment.id,
            taskTitle: _titleController.text.trim(),
            dueDateTime: dueDateTime,
          );
          print('✅ Notification histories updated for edited team task');
        } catch (e) {
          print('⚠️ Failed to update notification histories: $e');
        }
      } else {
        // If no due date/time, delete all notification histories
        await NotificationHistoryService().deleteNotificationsForTask(
          widget.assignment.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully!')),
        );
        Navigator.pop(context); // Close edit screen
        Navigator.pop(
          context,
        ); // Close detail screen (optional, or refresh? Detail screen usually rebuilds if using Stream or simple pop)
        // Ideally detail screen should refresh. If we popped detail screen, we go back to dashboard.
        // Actually, let's just pop Edit screen. The Detail screen might need to be notified or rely on Stream.
        // TeamTaskDetailScreen takes `assignment` as final field, so it won't auto-update unless parent rebuilds or we pass a Stream.
        // For simplicity, let's pop twice to dashboard or rely on user to go back.
        // Better UX: Pop Edit, and let Detail screen reflect changes? Detail screen is stateless and takes Model.
        // So popping Edit won't update Detail screen unless we use Stream or setState.
        // Let's pop back to Dashboard to ensure fresh data.
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
      appBar: AppBar(
        title: const Text('Edit Team Task'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
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
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
