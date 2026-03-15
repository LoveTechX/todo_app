import '../models/schedule_block.dart';
import '../models/task.dart';
import 'behavior_prediction_service.dart';
import 'energy_profile_service.dart';
import 'focus_engine_service.dart';
import 'task_history_service.dart';

class SchedulePlannerService {
  SchedulePlannerService({
    FocusEngineService? focusEngine,
    DateTime Function()? nowProvider,
    TaskHistoryService? historyService,
    BehaviorPredictionService? behaviorPredictionService,
    EnergyProfileService? energyProfile,
  }) : _focusEngine = focusEngine ?? FocusEngineService(),
       _nowProvider = nowProvider ?? DateTime.now,
       _historyService = historyService,
       _behaviorPredictionService = behaviorPredictionService,
       _energyProfile = energyProfile ?? const EnergyProfileService();

  static const int _breakMinutes = 5;
  static const int _defaultTaskMinutes = 25;

  final FocusEngineService _focusEngine;
  final DateTime Function() _nowProvider;
  final TaskHistoryService? _historyService;
  final BehaviorPredictionService? _behaviorPredictionService;
  final EnergyProfileService _energyProfile;
  final Map<String, int> _learnedDurations = <String, int>{};
  final Map<String, int> _behaviorDifficulties = <String, int>{};

  Future<void> refreshLearnedDurations(List<String> taskIds) async {
    if (_historyService == null) {
      return;
    }

    for (final String id in taskIds) {
      final List sessions = await _historyService.getSessionsForTask(id);
      if (sessions.isNotEmpty) {
        final double avg = _historyService.calculateAverageDuration(
          sessions.cast(),
        );
        _learnedDurations[id] = avg.round().clamp(1, 480);
      }
    }
  }

  Future<void> refreshBehaviorDifficulties(List<String> taskIds) async {
    if (_behaviorPredictionService == null) {
      return;
    }

    for (final String id in taskIds) {
      final behavior = await _behaviorPredictionService.getBehavior(id);
      _behaviorDifficulties[id] = _behaviorPredictionService
          .calculateDifficulty(behavior);
    }
  }

  List<ScheduleBlock> generateDailyPlan(
    List<Task> tasks,
    int availableMinutes, {
    DateTime? startTime,
  }) {
    final List<Task> candidates = tasks
        .where((Task task) => !task.isCompleted)
        .toList();

    final CognitiveLoad preferred = _energyProfile.preferredLoadForTime(
      _nowProvider(),
    );

    final List<Task> matching = candidates
        .where((Task t) => t.cognitiveLoad == preferred)
        .toList();
    final List<Task> remaining = candidates
        .where((Task t) => t.cognitiveLoad != preferred)
        .toList();

    // Order each partition by focus score independently, then concatenate.
    // This means matching-load tasks are always scheduled first, but within
    // each group priority / deadline / age / duration are still respected.
    final List<Task> orderedTasks = <Task>[
      ..._orderByBehaviorAndFocus(matching),
      ..._orderByBehaviorAndFocus(remaining),
    ];

    final List<ScheduleBlock> plan = <ScheduleBlock>[];

    final int planLimitMinutes = availableMinutes.clamp(0, 24 * 60);
    int plannedMinutes = 0;
    DateTime cursor = startTime ?? _nowProvider();

    for (final Task task in orderedTasks) {
      final int remainingMinutes = planLimitMinutes - plannedMinutes;
      if (remainingMinutes <= 0) {
        break;
      }

      final int taskMinutes = _taskDurationMinutes(task);
      if (taskMinutes > remainingMinutes) {
        continue;
      }

      final DateTime taskEnd = cursor.add(Duration(minutes: taskMinutes));
      plan.add(
        ScheduleBlock(
          startTime: cursor,
          endTime: taskEnd,
          task: task,
          type: ScheduleBlockTypes.task,
        ),
      );
      plannedMinutes += taskMinutes;
      cursor = taskEnd;

      final int breakRemaining = planLimitMinutes - plannedMinutes;
      if (breakRemaining <= 0) {
        break;
      }

      final int breakMinutes = _breakMinutes <= breakRemaining
          ? _breakMinutes
          : breakRemaining;
      final DateTime breakEnd = cursor.add(Duration(minutes: breakMinutes));
      plan.add(
        ScheduleBlock(
          startTime: cursor,
          endTime: breakEnd,
          type: ScheduleBlockTypes.breakTime,
        ),
      );
      plannedMinutes += breakMinutes;
      cursor = breakEnd;
    }

    return plan;
  }

  List<Task> _orderByFocusScore(List<Task> tasks) {
    final List<Task> remaining = List<Task>.from(tasks);
    final List<Task> ordered = <Task>[];

    while (remaining.isNotEmpty) {
      final Task? next = _focusEngine.recommendTask(remaining);
      if (next == null) {
        break;
      }

      ordered.add(next);
      remaining.removeWhere((Task task) => task.id == next.id);
    }

    return ordered;
  }

  List<Task> _orderByBehaviorAndFocus(List<Task> tasks) {
    final List<Task> focusOrdered = _orderByFocusScore(tasks);
    final Map<String, int> focusIndex = <String, int>{
      for (int i = 0; i < focusOrdered.length; i++) focusOrdered[i].id: i,
    };

    final List<Task> reordered = List<Task>.from(focusOrdered);
    reordered.sort((Task a, Task b) {
      final int difficultyCompare = _difficultyForTask(
        b,
      ).compareTo(_difficultyForTask(a));
      if (difficultyCompare != 0) {
        return difficultyCompare;
      }

      return (focusIndex[a.id] ?? 0).compareTo(focusIndex[b.id] ?? 0);
    });

    return reordered;
  }

  int _difficultyForTask(Task task) {
    return _behaviorDifficulties[task.id] ?? 0;
  }

  int _taskDurationMinutes(Task task) {
    if (_learnedDurations.containsKey(task.id)) {
      return _learnedDurations[task.id]!;
    }

    final int? estimated = task.estimatedDurationMinutes;
    if (estimated == null || estimated <= 0) {
      return _defaultTaskMinutes;
    }

    return estimated;
  }
}
