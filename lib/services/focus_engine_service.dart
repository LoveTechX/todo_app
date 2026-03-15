import '../models/task.dart';

class FocusEngineService {
  FocusEngineService({DateTime Function()? nowProvider})
    : _nowProvider = nowProvider ?? DateTime.now;

  final DateTime Function() _nowProvider;

  Task? recommendTask(List<Task> tasks) {
    final List<Task> candidates = tasks
        .where((Task task) => !task.isCompleted)
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((Task a, Task b) {
      final int scoreCompare = _score(b).compareTo(_score(a));
      if (scoreCompare != 0) {
        return scoreCompare;
      }

      final DateTime aDeadline = a.deadline ?? DateTime(9999);
      final DateTime bDeadline = b.deadline ?? DateTime(9999);
      final int deadlineCompare = aDeadline.compareTo(bDeadline);
      if (deadlineCompare != 0) {
        return deadlineCompare;
      }

      final int priorityCompare = _priorityScore(
        b,
      ).compareTo(_priorityScore(a));
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return candidates.first;
  }

  int _score(Task task) {
    return _priorityScore(task) +
        _deadlineUrgencyScore(task) +
        _ageScore(task) +
        _estimatedDurationScore(task);
  }

  int _priorityScore(Task task) {
    switch (task.priority.name) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'normal':
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  int _deadlineUrgencyScore(Task task) {
    final DateTime? deadline = task.deadline;
    if (deadline == null) {
      return 0;
    }

    final Duration untilDeadline = deadline.difference(_nowProvider());

    if (untilDeadline.isNegative) {
      return 3;
    }
    if (untilDeadline < const Duration(days: 1)) {
      return 3;
    }
    if (untilDeadline < const Duration(days: 3)) {
      return 2;
    }
    if (untilDeadline < const Duration(days: 7)) {
      return 1;
    }

    return 0;
  }

  int _ageScore(Task task) {
    final Duration age = _nowProvider().difference(task.createdAt);
    if (age.isNegative) {
      return 0;
    }

    return age.inDays;
  }

  int _estimatedDurationScore(Task task) {
    final int? minutes = task.estimatedDurationMinutes;
    if (minutes == null || minutes <= 0) {
      return 0;
    }

    if (minutes <= 30) {
      return 2;
    }
    if (minutes <= 90) {
      return 1;
    }

    return 0;
  }
}
