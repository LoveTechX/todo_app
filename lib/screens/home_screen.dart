import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../screens/focus_rooms_screen.dart';
import '../services/command_palette_service.dart';
import '../state/todo_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/command_palette.dart';
import '../widgets/daily_plan_timeline.dart';
import '../widgets/focus_timer_card.dart';
import '../widgets/task_item.dart';

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const CommandPaletteService _commandPaletteService =
      CommandPaletteService();

  @override
  Widget build(BuildContext context) {
    final TodoProvider provider = context.watch<TodoProvider>();
    final Task? recommendedTask = provider.recommendedTask;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _OpenCommandPaletteIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _OpenCommandPaletteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
            onInvoke: (_) {
              _showCommandPalette(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Layered Todo'),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Focus Rooms',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FocusRoomsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.groups),
                ),
              ],
            ),
            body: SafeArea(
              child: Builder(
                builder: (BuildContext context) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
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
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Recommended Focus',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(Icons.bolt, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Focus Score: ${provider.focusScore}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (recommendedTask != null) ...<Widget>[
                                    Text(
                                      recommendedTask.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Priority: ${recommendedTask.priority.name[0].toUpperCase()}${recommendedTask.priority.name.substring(1)}',
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed:
                                          provider.isFocusing &&
                                              provider.activeFocusTask?.id ==
                                                  recommendedTask.id
                                          ? null
                                          : () => context
                                                .read<TodoProvider>()
                                                .startFocus(recommendedTask),
                                      child: const Text('Start Focus'),
                                    ),
                                  ] else
                                    const Text('No tasks available'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Today's Strategy",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(provider.todaysStrategy.message),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: <Widget>[
                              Text(
                                "Today's Plan",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () =>
                                    _showAvailableMinutesDialog(context),
                                icon: const Icon(Icons.schedule),
                                label: Text('${provider.availableMinutes} min'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const DailyPlanTimeline(),
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
                        if (provider.tasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No tasks yet. Add one to get started.',
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: provider.tasks.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Task task = provider.tasks[index];
                              return TaskItem(
                                task: task,
                                onDelete: () => provider.deleteTask(task.id),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddTaskSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Task'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCommandPalette(BuildContext context) async {
    final commands = _commandPaletteService.getCommands(context);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => CommandPalette(commands: commands),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const AddTaskSheet(),
    );
  }

  Future<void> _showAvailableMinutesDialog(BuildContext context) async {
    final TodoProvider provider = context.read<TodoProvider>();
    final TextEditingController controller = TextEditingController(
      text: provider.availableMinutes.toString(),
    );

    final int? selectedMinutes = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How much time do you have?'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Available minutes'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? value = int.tryParse(controller.text.trim());
                Navigator.of(context).pop(value);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (selectedMinutes != null) {
      context.read<TodoProvider>().setAvailableMinutes(selectedMinutes);
    }
  }
}
