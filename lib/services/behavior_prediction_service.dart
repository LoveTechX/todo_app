import 'dart:async';

import 'package:hive/hive.dart';

import '../models/task_behavior.dart';

class BehaviorPredictionService {
  static const String boxName = 'task_behavior';

  Box<dynamic> get _box => Hive.box(boxName);

  void recordSkip(String taskId) {
    final TaskBehavior current = _readBehavior(taskId);
    final TaskBehavior updated = current.copyWith(skips: current.skips + 1);
    unawaited(_box.put(taskId, updated.toMap()));
  }

  void recordEarlyCompletion(String taskId) {
    final TaskBehavior current = _readBehavior(taskId);
    final TaskBehavior updated = current.copyWith(
      earlyCompletions: current.earlyCompletions + 1,
    );
    unawaited(_box.put(taskId, updated.toMap()));
  }

  void recordLateCompletion(String taskId) {
    final TaskBehavior current = _readBehavior(taskId);
    final TaskBehavior updated = current.copyWith(
      lateCompletions: current.lateCompletions + 1,
    );
    unawaited(_box.put(taskId, updated.toMap()));
  }

  int calculateDifficulty(TaskBehavior behavior) {
    final int raw =
        (behavior.skips * 3) +
        (behavior.lateCompletions * 2) -
        behavior.earlyCompletions;
    return raw < 0 ? 0 : raw;
  }

  Future<TaskBehavior> getBehavior(String taskId) async {
    return _readBehavior(taskId);
  }

  TaskBehavior _readBehavior(String taskId) {
    final dynamic raw = _box.get(taskId);
    if (raw is Map) {
      return TaskBehavior.fromMap(Map<String, dynamic>.from(raw));
    }

    return TaskBehavior(
      taskId: taskId,
      skips: 0,
      earlyCompletions: 0,
      lateCompletions: 0,
    );
  }
}
