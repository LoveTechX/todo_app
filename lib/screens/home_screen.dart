import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../state/todo_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/focus_timer_card.dart';
import '../widgets/task_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layered Todo')),
      body: Consumer<TodoProvider>(
        builder: (BuildContext context, TodoProvider provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: <Widget>[
              FocusTimerCard(
                formattedTime: provider.formattedRemainingTime,
                durationMinutes: provider.focusDurationMinutes,
                isRunning: provider.isTimerRunning,
                onDurationChanged: provider.setFocusDurationMinutes,
                onStartPause: provider.isTimerRunning
                    ? provider.pauseFocusTimer
                    : provider.startFocusTimer,
                onReset: provider.resetFocusTimer,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${provider.completedCount}/${provider.tasks.length} done',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: provider.tasks.isEmpty
                    ? const Center(
                        child: Text('No tasks yet. Add one to get started.'),
                      )
                    : ListView.builder(
                        itemCount: provider.tasks.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Task task = provider.tasks[index];
                          return TaskItem(
                            task: task,
                            onToggle: () => provider.toggleTaskCompletion(task),
                            onDelete: () => provider.deleteTask(task.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddTaskSheet(
          onAddTask: (String title, TaskPriority priority) {
            context.read<TodoProvider>().addTask(title, priority);
          },
        );
      },
    );
  }
}
