import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/command.dart';
import '../models/task.dart';
import '../state/todo_provider.dart';
import '../widgets/add_task_sheet.dart';

class CommandPaletteService {
  const CommandPaletteService();

  List<Command> getCommands(BuildContext context) {
    final TodoProvider provider = context.read<TodoProvider>();

    return <Command>[
      Command(
        title: 'Create Task',
        action: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) => const AddTaskSheet(),
          );
        },
      ),
      Command(
        title: 'Start Focus Session',
        action: () {
          final Task? recommended = provider.recommendedTask;
          if (recommended == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No task available to focus on.')),
            );
            return;
          }
          provider.startFocus(recommended);
        },
      ),
      Command(
        title: "Generate Today's Plan",
        action: () {
          provider.regenerateTodayPlan();
        },
      ),
      Command(
        title: 'View Tasks',
        action: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have ${provider.tasks.length} tasks.')),
          );
        },
      ),
    ];
  }
}
