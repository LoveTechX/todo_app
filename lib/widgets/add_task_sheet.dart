import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../state/todo_provider.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String trimmed = _titleController.text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final Task task = Task(
      id: const Uuid().v4(),
      title: trimmed,
      priority: _selectedPriority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      isCompleted: false,
    );

    final TodoProvider provider = context.read<TodoProvider>();
    await provider.addTask(task);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Add Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Task name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            value: _selectedPriority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: TaskPriority.values
                .map(
                  (TaskPriority priority) => DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Text(priority.label),
                  ),
                )
                .toList(),
            onChanged: (TaskPriority? value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedPriority = value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add_task),
              label: const Text('Create Task'),
            ),
          ),
        ],
      ),
    );
  }
}
