import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_history_service.dart';
import '../widgets/task_time_picker.dart';

/// Screen to edit existing personal task
class EditPersonalTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditPersonalTaskScreen({super.key, required this.task});

  @override
  State<EditPersonalTaskScreen> createState() => _EditPersonalTaskScreenState();
}

class _EditPersonalTaskScreenState extends State<EditPersonalTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  String? _level;
  String? _priority;
  String? _category;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  // Categories matching create_task_screen.dart EXACTLY
  static const List<String> _validCategories = [
    'General',
    'Cleaning',
    'Maintenance',
    'Organization',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _level = widget.task.level;
    _priority = widget.task.priority;

    // Validate category - if not in valid list, default to 'General'
    if (widget.task.category != null &&
        _validCategories.contains(widget.task.category)) {
      _category = widget.task.category;
    } else {
      _category = 'General';
    }

    _dueDate = widget.task.dueDate;
    _dueTime = widget.task.dueTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
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

              // Level dropdown
              DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                ),
                items: ['Easy', 'Hard']
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _level = value),
              ),
              const SizedBox(height: 16),

              // Priority dropdown
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: ['Low', 'Medium', 'High']
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _priority = value),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _validCategories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),

              // Date and Time Picker
              TaskTimePicker(
                selectedDate: _dueDate,
                selectedTime: _dueTime,
                onDateChanged: (date) {
                  setState(() {
                    _dueDate = date;
                  });
                },
                onTimeChanged: (time) {
                  setState(() {
                    _dueTime = time;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    try {
      // Create update map
      final updates = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'level': _level,
        'dueDate': _dueDate,
        'dueTime': _dueTime != null
            ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'category': _category,
        'priority': _priority,
      };

      await context.read<TaskProvider>().updateTask(
        widget.task.id,
        updates,
        user.uid,
      );

      // Update notification histories if due date/time changed
      if (_dueDate != null && _dueTime != null) {
        try {
          // Delete old notification histories
          await NotificationHistoryService().deleteNotificationsForTask(
            widget.task.id,
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
            userId: user.uid,
            taskId: widget.task.id,
            taskTitle: _titleController.text,
            dueDateTime: dueDateTime,
          );
          print('✅ Notification histories updated for edited task');
        } catch (e) {
          print('⚠️ Failed to update notification histories: $e');
        }
      } else {
        // If no due date/time, delete all notification histories
        await NotificationHistoryService().deleteNotificationsForTask(
          widget.task.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully!')),
        );
        Navigator.pop(context);
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
