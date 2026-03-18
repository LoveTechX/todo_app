import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../screens/analytics_dashboard_screen.dart';
import '../screens/focus_rooms_screen.dart';
import '../services/command_palette_service.dart';
import '../services/search_service.dart';
import '../services/sync_service.dart';
import '../services/task_history_service.dart';
import '../state/analytics_provider.dart';
import '../state/focus_provider.dart';
import '../state/planner_provider.dart';
import '../state/streak_provider.dart';
import '../state/task_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/command_palette.dart';
import '../widgets/daily_plan_timeline.dart';
import '../widgets/focus_timer_card.dart';
import '../widgets/global_search_bar.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/task_item.dart';

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.syncService});

  final SyncService syncService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SearchService _searchService;
  late final TaskHistoryService _taskHistoryService;

  static const CommandPaletteService _commandPaletteService =
      CommandPaletteService();

  static const String _analyticsHeroTag = 'analytics-screen-hero';
  static const String _focusRoomsHeroTag = 'focus-rooms-screen-hero';

  @override
  void initState() {
    super.initState();
    _taskHistoryService = TaskHistoryService();
    _searchService = SearchService(historyService: _taskHistoryService);
  }

  @override
  void dispose() {
    _searchService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TaskProvider taskProvider = context.watch<TaskProvider>();
    final PlannerProvider plannerProvider = context.watch<PlannerProvider>();
    final AnalyticsProvider analyticsProvider = context
        .watch<AnalyticsProvider>();
    final FocusProvider focusProvider = context.watch<FocusProvider>();
    final StreakProvider streakProvider = context.watch<StreakProvider>();
    final Task? recommendedTask = taskProvider.recommendedTask;

    _searchService.updateSearchContext(
      tasks: taskProvider.tasks,
      focusEvents: analyticsProvider.focusEvents,
      focusScore: analyticsProvider.focusScore,
      skippedTasksToday: analyticsProvider.skippedTasksToday,
      difficultTasksCount: analyticsProvider.difficultTasksCount,
    );

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
                SyncStatusIndicator(syncService: widget.syncService),
                IconButton(
                  tooltip: 'Analytics Dashboard',
                  onPressed: () {
                    Navigator.of(context).push(
                      _buildSlideFadeRoute<void>(
                        const AnalyticsDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Hero(
                    tag: _analyticsHeroTag,
                    child: Icon(Icons.analytics_outlined),
                  ),
                ),
                IconButton(
                  tooltip: 'Focus Rooms',
                  onPressed: () {
                    Navigator.of(context).push(
                      _buildSlideFadeRoute<void>(const FocusRoomsScreen()),
                    );
                  },
                  icon: const Hero(
                    tag: _focusRoomsHeroTag,
                    child: Icon(Icons.groups),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Builder(
                builder: (BuildContext context) {
                  if (taskProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: <Widget>[
                        if (streakProvider.currentStreak > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: <Widget>[
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${streakProvider.currentStreak} ${streakProvider.currentStreak == 1 ? 'Day' : 'Days'} Streak',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        FocusTimerCard(
                          remainingSecondsListenable:
                              focusProvider.remainingSecondsNotifier,
                          durationMinutes: focusProvider.focusDurationMinutes,
                          isRunning: focusProvider.isTimerRunning,
                          onDurationChanged:
                              focusProvider.setFocusDurationMinutes,
                          onStartPause: focusProvider.isTimerRunning
                              ? focusProvider.pauseFocusTimer
                              : focusProvider.startFocusTimer,
                          onReset: focusProvider.resetFocusTimer,
                        ),
                        GlobalSearchBar(searchService: _searchService),
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
                                          'Focus Score: ${analyticsProvider.focusScore}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (recommendedTask != null) ...<Widget>[
                                    Text(
                                      'Start with ${focusProvider.focusDurationMinutes} min on ${recommendedTask.title}',
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
                                          focusProvider.isFocusing &&
                                              focusProvider
                                                      .activeFocusTask
                                                      ?.id ==
                                                  recommendedTask.id
                                          ? null
                                          : () => context
                                                .read<FocusProvider>()
                                                .startFocus(recommendedTask),
                                      child: const Text('Start Focus'),
                                    ),
                                  ] else ...<Widget>[
                                    const Text('Start a 15 min warm-up session'),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<FocusProvider>()
                                            .setFocusDurationMinutes(15);
                                        context
                                            .read<FocusProvider>()
                                            .startFocusTimer();
                                      },
                                      child: const Text('Start Warm-up'),
                                    ),
                                  ],
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
                                  Text(
                                    analyticsProvider.todaysStrategy.message,
                                  ),
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
                                label: Text(
                                  '${plannerProvider.availableMinutes} min',
                                ),
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
                                '${taskProvider.completedCount}/${taskProvider.tasks.length} done',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (taskProvider.tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: <Widget>[
                                  const Text(
                                    'Start your first focus session 🚀',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add a task to get personalized suggestions',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddTaskSheet(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('+ Add First Task'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: taskProvider.tasks.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Task task = taskProvider.tasks[index];
                              return TaskItem(
                                task: task,
                                animationIndex: index,
                                onDelete: () =>
                                    taskProvider.deleteTask(task.id),
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

  PageRoute<T> _buildSlideFadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return page;
          },
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            final Animation<Offset> slide =
                Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
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
    final PlannerProvider provider = context.read<PlannerProvider>();
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

    if (!context.mounted) {
      return;
    }

    if (selectedMinutes != null) {
      context.read<PlannerProvider>().setAvailableMinutes(selectedMinutes);
    }
  }
}
