import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/focus_engine_service.dart';
import '../services/task_service.dart';
import 'analytics_provider.dart';
import 'planner_provider.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required TaskService taskService,
    bool enableSyncMonitor = true,
  }) : _taskService = taskService,
       _enableSyncMonitor = enableSyncMonitor;

  static const Duration _syncInterval = Duration(minutes: 2);
  static const Duration _syncRetryBaseDelay = Duration(seconds: 10);
  static const int _maxSyncRetryAttempts = 3;

  final TaskService _taskService;
  final bool _enableSyncMonitor;
  final FocusEngineService _focusEngine = FocusEngineService();

  List<Task> _tasks = <Task>[];
  bool _isLoading = false;
  Timer? _syncMonitor;
  bool _isSyncInProgress = false;
  int _syncRetryAttempts = 0;
  DateTime? _nextSyncAllowedAt;

  PlannerProvider? _plannerProvider;
  AnalyticsProvider? _analyticsProvider;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  int get completedCount =>
      _tasks.where((Task task) => task.isCompleted).length;
  Task? get recommendedTask => _focusEngine.recommendTask(_tasks);

  void attachDependencies({
    required PlannerProvider plannerProvider,
    required AnalyticsProvider analyticsProvider,
  }) {
    _plannerProvider = plannerProvider;
    _analyticsProvider = analyticsProvider;
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasks();
      _sortTasks();

      await Future.wait(<Future<void>>[
        _plannerProvider?.refreshLearnedDurationsForTaskIds(
              _tasks.map((Task task) => task.id).toList(),
            ) ??
            Future<void>.value(),
        _plannerProvider?.refreshBehaviorDifficultiesForTaskIds(
              _tasks.map((Task task) => task.id).toList(),
            ) ??
            Future<void>.value(),
        _analyticsProvider?.loadDailyEvents() ?? Future<void>.value(),
        _analyticsProvider?.refreshDifficultTaskSignal(_tasks) ??
            Future<void>.value(),
      ]);

      if (_enableSyncMonitor) {
        _startSyncMonitor();
      }
    } catch (error, stackTrace) {
      debugPrint('TaskProvider.loadTasks failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _tasks = <Task>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    final Task localTask = task.copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    try {
      await _taskService.addTask(localTask);
      _tasks.add(localTask);
      _sortTasks();

      await Future.wait(<Future<void>>[
        _plannerProvider?.refreshBehaviorDifficultiesForTaskIds(<String>[
              task.id,
            ]) ??
            Future<void>.value(),
        _analyticsProvider?.refreshDifficultTaskSignal(_tasks) ??
            Future<void>.value(),
      ]);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('TaskProvider.addTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> toggleTask(Task task) async {
    final Task updated = task.copyWith(
      isCompleted: !task.isCompleted,
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    try {
      await _taskService.updateTask(updated);

      final int index = _tasks.indexWhere((Task item) => item.id == task.id);
      if (index == -1) {
        return;
      }

      _tasks[index] = updated;
      _sortTasks();

      if (!task.isCompleted && updated.isCompleted) {
        await Future.wait(<Future<void>>[
          _analyticsProvider?.recordCompletion(task) ?? Future<void>.value(),
          _plannerProvider?.refreshBehaviorDifficultiesForTaskIds(<String>[
                task.id,
              ]) ??
              Future<void>.value(),
        ]);
      }

      await _analyticsProvider?.refreshDifficultTaskSignal(_tasks);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('TaskProvider.toggleTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> toggleTaskCompletion(Task task) {
    return toggleTask(task);
  }

  Future<void> deleteTask(String id) async {
    final int existingIndex = _tasks.indexWhere((Task task) => task.id == id);
    final Task? toDelete = existingIndex == -1 ? null : _tasks[existingIndex];

    try {
      await _taskService.deleteTask(id);
      _tasks.removeWhere((Task task) => task.id == id);

      if (toDelete != null && !toDelete.isCompleted) {
        await Future.wait(<Future<void>>[
          _analyticsProvider?.recordTaskSkipped(id) ?? Future<void>.value(),
          _plannerProvider?.refreshBehaviorDifficultiesForTaskIds(<String>[
                id,
              ]) ??
              Future<void>.value(),
        ]);
      }

      await _analyticsProvider?.refreshDifficultTaskSignal(_tasks);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('TaskProvider.deleteTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _sortTasks() {
    _tasks.sort((Task a, Task b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      if (a.priority.weight != b.priority.weight) {
        return b.priority.weight.compareTo(a.priority.weight);
      }

      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _startSyncMonitor() {
    _syncMonitor?.cancel();
    _syncMonitor = Timer.periodic(_syncInterval, (_) {
      unawaited(_safeSyncTasks());
    });
  }

  Future<void> _safeSyncTasks() async {
    final DateTime now = DateTime.now();
    if (_isSyncInProgress) {
      return;
    }

    if (_nextSyncAllowedAt != null && now.isBefore(_nextSyncAllowedAt!)) {
      return;
    }

    _isSyncInProgress = true;
    try {
      await _taskService.syncTasks();
      _syncRetryAttempts = 0;
      _nextSyncAllowedAt = null;
    } catch (error, stackTrace) {
      debugPrint('TaskProvider sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_syncRetryAttempts < _maxSyncRetryAttempts) {
        _syncRetryAttempts += 1;
        _nextSyncAllowedAt = now.add(
          Duration(seconds: _syncRetryBaseDelay.inSeconds * _syncRetryAttempts),
        );
      } else {
        // Stop aggressive retries; periodic monitor will try again on next cycle.
        _syncRetryAttempts = 0;
        _nextSyncAllowedAt = now.add(_syncInterval);
      }
    } finally {
      _isSyncInProgress = false;
    }
  }

  @override
  void dispose() {
    _syncMonitor?.cancel();
    super.dispose();
  }
}
