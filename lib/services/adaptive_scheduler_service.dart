import '../models/focus_session.dart';
import '../models/schedule_block.dart';
import '../models/task.dart';

class AdaptiveSchedulerService {
  static const int _defaultTaskMinutes = 25;
  static const int _breakMinutes = 5;

  final Map<String, int> _predictedDurations = <String, int>{};
  final Map<String, int> _skipSignals = <String, int>{};

  DateTime _planningNow = DateTime.now();
  CognitiveLoad _preferredLoad = CognitiveLoad.medium;

  int _morningSessionCount = 0;
  int _morningSessionMinutes = 0;
  int _nonMorningSessionCount = 0;
  int _nonMorningSessionMinutes = 0;

  void learnFromSession(FocusSession session) {
    final int actualDuration = session.durationMinutes.clamp(1, 480);
    final int plannedDuration =
        _predictedDurations[session.taskId] ?? _defaultTaskMinutes;

    int nextPrediction;
    if (actualDuration > plannedDuration) {
      // If actual exceeds planned, bias upward immediately.
      nextPrediction = ((plannedDuration * 0.3) + (actualDuration * 0.7))
          .round();
    } else {
      nextPrediction = ((plannedDuration * 0.6) + (actualDuration * 0.4))
          .round();
    }

    _predictedDurations[session.taskId] = nextPrediction.clamp(1, 480);

    final bool morning = session.endTime.hour < 12;
    if (morning) {
      _morningSessionCount += 1;
      _morningSessionMinutes += actualDuration;
    } else {
      _nonMorningSessionCount += 1;
      _nonMorningSessionMinutes += actualDuration;
    }
  }

  int predictTaskDuration(String taskId) {
    return _predictedDurations[taskId] ?? _defaultTaskMinutes;
  }

  void seedTaskEstimate(String taskId, int minutes) {
    if (minutes <= 0) {
      return;
    }

    _predictedDurations.putIfAbsent(taskId, () => minutes.clamp(1, 480));
  }

  void updateTaskSkipSignals(Map<String, int> skipSignals) {
    _skipSignals
      ..clear()
      ..addAll(skipSignals);
  }

  void setPlanningContext({
    required DateTime now,
    required CognitiveLoad preferredLoad,
  }) {
    _planningNow = now;
    _preferredLoad = preferredLoad;
  }

  List<ScheduleBlock> optimizePlan(List<Task> tasks, int availableMinutes) {
    final List<Task> candidates = tasks
        .where((Task task) => !task.isCompleted)
        .toList();

    candidates.sort((Task a, Task b) {
      final int scoreCompare = _taskScore(b).compareTo(_taskScore(a));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    final int planLimitMinutes = availableMinutes.clamp(0, 24 * 60);
    final List<ScheduleBlock> plan = <ScheduleBlock>[];

    int plannedMinutes = 0;
    DateTime cursor = _planningNow;

    for (final Task task in candidates) {
      final int remainingMinutes = planLimitMinutes - plannedMinutes;
      if (remainingMinutes <= 0) {
        break;
      }

      final int duration = _durationForTask(task);
      if (duration > remainingMinutes) {
        continue;
      }

      final DateTime taskEnd = cursor.add(Duration(minutes: duration));
      plan.add(
        ScheduleBlock(
          startTime: cursor,
          endTime: taskEnd,
          task: task,
          type: ScheduleBlockTypes.task,
        ),
      );
      plannedMinutes += duration;
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

  int _durationForTask(Task task) {
    final int predicted = _predictedDurations[task.id] ?? 0;
    if (predicted > 0) {
      return predicted;
    }

    final int? estimated = task.estimatedDurationMinutes;
    if (estimated == null || estimated <= 0) {
      return _defaultTaskMinutes;
    }

    return estimated;
  }

  int _taskScore(Task task) {
    int score = task.priority.weight * 100;

    final int skipSignal = _skipSignals[task.id] ?? 0;
    score += skipSignal * 18;

    if (task.cognitiveLoad == _preferredLoad) {
      score += 30;
    }

    if (_focusesBetterInMorning && _planningNow.hour < 12) {
      if (task.cognitiveLoad == CognitiveLoad.deep) {
        score += 60;
      }
    }

    return score;
  }

  bool get _focusesBetterInMorning {
    final int morningMinutes = _morningSessionMinutes;
    final int nonMorningMinutes = _nonMorningSessionMinutes;

    if (_morningSessionCount == 0) {
      return false;
    }

    if (_nonMorningSessionCount == 0) {
      return true;
    }

    final double morningAverage = morningMinutes / _morningSessionCount;
    final double nonMorningAverage =
        nonMorningMinutes / _nonMorningSessionCount;
    return morningAverage >= nonMorningAverage;
  }
}
