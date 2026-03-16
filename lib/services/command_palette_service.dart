import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/command.dart';
import '../models/task.dart';
import '../screens/analytics_dashboard_screen.dart';
import '../screens/focus_rooms_screen.dart';
import '../state/focus_provider.dart';
import '../state/planner_provider.dart';
import '../state/task_provider.dart';
import '../widgets/add_task_sheet.dart';

class CommandPaletteService {
  const CommandPaletteService();

  List<Command> getCommands(BuildContext context) {
    final TaskProvider taskProvider = context.read<TaskProvider>();
    final FocusProvider focusProvider = context.read<FocusProvider>();
    final PlannerProvider plannerProvider = context.read<PlannerProvider>();

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
        title: 'Start Focus',
        action: () {
          final Task? recommended = taskProvider.recommendedTask;
          if (recommended == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No task available to focus on.')),
            );
            return;
          }
          focusProvider.startFocus(recommended);
        },
      ),
      Command(
        title: 'Open Analytics',
        action: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AnalyticsDashboardScreen(),
            ),
          );
        },
      ),
      Command(
        title: 'Join Focus Room',
        action: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FocusRoomsScreen()),
          );
        },
      ),
      Command(
        title: 'Generate Daily Plan',
        action: () {
          plannerProvider.regenerateTodayPlan();
        },
      ),
    ];
  }
}
