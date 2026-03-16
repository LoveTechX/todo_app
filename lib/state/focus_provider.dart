import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/focus_session.dart';
import '../models/task.dart';
import '../services/focus_timer_service.dart';
import '../services/task_history_service.dart';
import 'analytics_provider.dart';
import 'planner_provider.dart';
import 'task_provider.dart';

class FocusProvider extends ChangeNotifier {
  FocusProvider({
    required FocusTimerService focusTimerService,
    required TaskHistoryService historyService,
    required TaskProvider taskProvider,
    required PlannerProvider plannerProvider,
    required AnalyticsProvider analyticsProvider,
  }) : _focusTimerService = focusTimerService,
       _historyService = historyService,
       _taskProvider = taskProvider,
       _plannerProvider = plannerProvider,
       _analyticsProvider = analyticsProvider {
    remainingSecondsNotifier = ValueNotifier<int>(_focusDurationMinutes * 60);
  }

  final FocusTimerService _focusTimerService;
  final TaskHistoryService _historyService;
  final TaskProvider _taskProvider;
  final PlannerProvider _plannerProvider;
  final AnalyticsProvider _analyticsProvider;

  late final ValueNotifier<int> remainingSecondsNotifier;

  Task? _activeFocusTask;
  DateTime? _focusStartTime;
  int _focusDurationMinutes = 25;
  bool _isTimerRunning = false;

  Task? get activeFocusTask => _activeFocusTask;
  int get focusDurationMinutes => _focusDurationMinutes;
  bool get isTimerRunning => _isTimerRunning;
  bool get isFocusing => _activeFocusTask != null && _isTimerRunning;

  int get remainingSeconds => remainingSecondsNotifier.value;

  String get formattedRemainingTime {
    final int minutes = remainingSeconds ~/ 60;
    final int seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startFocus(Task task) {
    if (task.isCompleted) {
      return;
    }

    _activeFocusTask = task;
    _focusStartTime = DateTime.now();
    remainingSecondsNotifier.value = _focusDurationMinutes * 60;
    _isTimerRunning = true;
    _focusTimerService.start(onTick: _onTimerTick);
    notifyListeners();
  }

  void setFocusDurationMinutes(int minutes) {
    if (_isTimerRunning) {
      return;
    }

    _focusDurationMinutes = minutes;
    remainingSecondsNotifier.value = _focusDurationMinutes * 60;
    notifyListeners();
  }

  void startFocusTimer() {
    if (remainingSeconds == 0) {
      remainingSecondsNotifier.value = _focusDurationMinutes * 60;
    }

    _isTimerRunning = true;
    _focusTimerService.start(onTick: _onTimerTick);
    notifyListeners();
  }

  void pauseFocusTimer() {
    _isTimerRunning = false;
    _focusTimerService.stop();
    notifyListeners();
  }

  void resetFocusTimer() {
    final bool stoppedEarly =
        _activeFocusTask != null && remainingSeconds > 0 && _isTimerRunning;

    _isTimerRunning = false;
    _activeFocusTask = null;
    _focusStartTime = null;
    _focusTimerService.stop();
    remainingSecondsNotifier.value = _focusDurationMinutes * 60;

    if (stoppedEarly) {
      _analyticsProvider.recordFocusSessionStoppedEarly();
    }

    notifyListeners();
  }

  void _onTimerTick() {
    if (remainingSeconds <= 0) {
      _isTimerRunning = false;
      _activeFocusTask = null;
      _focusTimerService.stop();
      notifyListeners();
      return;
    }

    remainingSecondsNotifier.value = remainingSeconds - 1;

    if (remainingSeconds == 0) {
      final Task? completedTask = _activeFocusTask;
      final DateTime? sessionStart = _focusStartTime;
      final DateTime sessionEnd = DateTime.now();
      _isTimerRunning = false;
      _activeFocusTask = null;
      _focusStartTime = null;
      _focusTimerService.stop();
      notifyListeners();

      if (completedTask != null) {
        unawaited(
          _completeFocusedTask(completedTask, sessionStart, sessionEnd),
        );
      }
    }
  }

  Future<void> _completeFocusedTask(
    Task task,
    DateTime? sessionStart,
    DateTime sessionEnd,
  ) async {
    if (sessionStart != null) {
      final FocusSession session = FocusSession(
        taskId: task.id,
        startTime: sessionStart,
        endTime: sessionEnd,
        durationMinutes: _focusDurationMinutes,
      );

      try {
        await _historyService.saveSession(session);
        await _plannerProvider.refreshLearnedDurationsForTaskIds(<String>[
          task.id,
        ]);
        _analyticsProvider.recordFocusSessionCompleted();
      } catch (error, stackTrace) {
        debugPrint('FocusProvider._completeFocusedTask failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final Task? currentTask = _taskProvider.tasks.cast<Task?>().firstWhere(
      (Task? item) => item?.id == task.id,
      orElse: () => null,
    );

    if (currentTask != null && !currentTask.isCompleted) {
      await _taskProvider.toggleTask(currentTask);
    }
  }

  @override
  void dispose() {
    _focusTimerService.dispose();
    remainingSecondsNotifier.dispose();
    super.dispose();
  }
}
