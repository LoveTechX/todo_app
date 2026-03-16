import '../models/schedule_block.dart';
import '../models/focus_session.dart';
import '../models/task.dart';
import 'adaptive_scheduler_service.dart';
import 'behavior_prediction_service.dart';
import 'energy_profile_service.dart';
import 'task_history_service.dart';

class SchedulePlannerService {
  SchedulePlannerService({
    DateTime Function()? nowProvider,
    TaskHistoryService? historyService,
    BehaviorPredictionService? behaviorPredictionService,
    EnergyProfileService? energyProfile,
    AdaptiveSchedulerService? adaptiveScheduler,
  }) : _nowProvider = nowProvider ?? DateTime.now,
       _historyService = historyService,
       _behaviorPredictionService = behaviorPredictionService,
       _energyProfile = energyProfile ?? const EnergyProfileService(),
       _adaptiveScheduler = adaptiveScheduler ?? AdaptiveSchedulerService();

  static const int _defaultTaskMinutes = 25;

  final DateTime Function() _nowProvider;
  final TaskHistoryService? _historyService;
  final BehaviorPredictionService? _behaviorPredictionService;
  final EnergyProfileService _energyProfile;
  final AdaptiveSchedulerService _adaptiveScheduler;
  final Map<String, int> _learnedDurations = <String, int>{};
  final Map<String, int> _behaviorDifficulties = <String, int>{};

  Future<void> refreshLearnedDurations(List<String> taskIds) async {
    if (_historyService == null) {
      return;
    }

    final List<MapEntry<String, List>> entries = await Future.wait(
      taskIds.map((String id) async {
        final List sessions = await _historyService.getSessionsForTask(id);
        return MapEntry<String, List>(id, sessions);
      }),
    );

    for (final MapEntry<String, List> entry in entries) {
      final List sessions = entry.value;
      if (sessions.isNotEmpty) {
        final List<FocusSession> typedSessions = sessions.cast<FocusSession>();
        for (final FocusSession session in typedSessions) {
          _adaptiveScheduler.learnFromSession(session);
        }

        final double avg = _historyService.calculateAverageDuration(
          typedSessions,
        );
        final int learned = avg.round().clamp(1, 480);
        _learnedDurations[entry.key] = learned;
        _adaptiveScheduler.seedTaskEstimate(entry.key, learned);
      }
    }
  }

  Future<void> refreshBehaviorDifficulties(List<String> taskIds) async {
    if (_behaviorPredictionService == null) {
      return;
    }

    final List<MapEntry<String, int>> entries = await Future.wait(
      taskIds.map((String id) async {
        final behavior = await _behaviorPredictionService.getBehavior(id);
        final int difficulty = _behaviorPredictionService.calculateDifficulty(
          behavior,
        );
        return MapEntry<String, int>(id, difficulty);
      }),
    );

    for (final MapEntry<String, int> entry in entries) {
      _behaviorDifficulties[entry.key] = entry.value;
    }

    _adaptiveScheduler.updateTaskSkipSignals(_behaviorDifficulties);
  }

  List<ScheduleBlock> generateDailyPlan(
    List<Task> tasks,
    int availableMinutes, {
    DateTime? startTime,
  }) {
    final DateTime planStart = startTime ?? _nowProvider();
    final CognitiveLoad preferred = _energyProfile.preferredLoadForTime(
      planStart,
    );

    for (final Task task in tasks) {
      final int learned = _taskDurationMinutes(task);
      _adaptiveScheduler.seedTaskEstimate(task.id, learned);
    }

    _adaptiveScheduler
      ..setPlanningContext(now: planStart, preferredLoad: preferred)
      ..updateTaskSkipSignals(_behaviorDifficulties);

    return _adaptiveScheduler.optimizePlan(tasks, availableMinutes);
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
