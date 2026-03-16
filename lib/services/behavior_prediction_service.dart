import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/task_behavior.dart';

class BehaviorPredictionService {
  static const String boxName = 'task_behavior';

  Box<dynamic> get _box => Hive.box(boxName);

  void recordSkip(String taskId) {
    try {
      final TaskBehavior current = _readBehavior(taskId);
      final TaskBehavior updated = current.copyWith(skips: current.skips + 1);
      unawaited(_box.put(taskId, updated.toMap()));
    } catch (error, stackTrace) {
      debugPrint('BehaviorPredictionService.recordSkip failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void recordEarlyCompletion(String taskId) {
    try {
      final TaskBehavior current = _readBehavior(taskId);
      final TaskBehavior updated = current.copyWith(
        earlyCompletions: current.earlyCompletions + 1,
      );
      unawaited(_box.put(taskId, updated.toMap()));
    } catch (error, stackTrace) {
      debugPrint(
        'BehaviorPredictionService.recordEarlyCompletion failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void recordLateCompletion(String taskId) {
    try {
      final TaskBehavior current = _readBehavior(taskId);
      final TaskBehavior updated = current.copyWith(
        lateCompletions: current.lateCompletions + 1,
      );
      unawaited(_box.put(taskId, updated.toMap()));
    } catch (error, stackTrace) {
      debugPrint(
        'BehaviorPredictionService.recordLateCompletion failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  int calculateDifficulty(TaskBehavior behavior) {
    final int raw =
        (behavior.skips * 3) +
        (behavior.lateCompletions * 2) -
        behavior.earlyCompletions;
    return raw < 0 ? 0 : raw;
  }

  Future<TaskBehavior> getBehavior(String taskId) async {
    try {
      return _readBehavior(taskId);
    } catch (error, stackTrace) {
      debugPrint('BehaviorPredictionService.getBehavior failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return TaskBehavior(
        taskId: taskId,
        skips: 0,
        earlyCompletions: 0,
        lateCompletions: 0,
      );
    }
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
