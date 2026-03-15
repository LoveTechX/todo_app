import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/daily_strategy.dart';
import '../models/focus_event.dart';
import '../models/focus_session.dart';
import '../models/schedule_block.dart';
import '../models/task.dart';
import '../services/behavior_prediction_service.dart';
import '../services/focus_engine_service.dart';
import '../services/focus_integrity_service.dart';
import '../services/focus_timer_service.dart';
import '../services/reschedule_service.dart';
import '../services/schedule_planner_service.dart';
import '../services/strategy_generator_service.dart';
import '../services/task_history_service.dart';
import '../services/task_service.dart';

class TodoProvider extends ChangeNotifier {
  TodoProvider({
    required TaskService taskService,
    required FocusTimerService focusTimerService,
    required TaskHistoryService historyService,
    required FocusIntegrityService focusIntegrityService,
    required BehaviorPredictionService behaviorPredictionService,
  }) : _taskService = taskService,
       _focusTimerService = focusTimerService,
       _historyService = historyService,
       _focusIntegrityService = focusIntegrityService,
       _behaviorPredictionService = behaviorPredictionService,
       _planner = SchedulePlannerService(
         historyService: historyService,
         behaviorPredictionService: behaviorPredictionService,
       );

  final TaskService _taskService;
  final FocusEngineService _focusEngine = FocusEngineService();
  final FocusTimerService _focusTimerService;
  final TaskHistoryService _historyService;
  final FocusIntegrityService _focusIntegrityService;
  final BehaviorPredictionService _behaviorPredictionService;
  final StrategyGeneratorService _strategyGenerator =
      const StrategyGeneratorService();
  final RescheduleService _rescheduleService = const RescheduleService();
  final SchedulePlannerService _planner;

  List<Task> _tasks = <Task>[];
  List<FocusEvent> _todayFocusEvents = <FocusEvent>[];
  Task? _activeFocusTask;
  DateTime? _focusStartTime;
  int _availableMinutes = 240;
  int _focusDurationMinutes = 25;
  int _focusScore = 0;
  int _skippedTasksToday = 0;
  int _difficultTasksCount = 0;
  int _remainingSeconds = 25 * 60;
  DateTime? _scheduleAnchorTime;
  Timer? _driftMonitor;
  Timer? _syncMonitor;
  bool _isLoading = false;
  bool _isTimerRunning = false;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  Task? get recommendedTask => _focusEngine.recommendTask(_tasks);
  List<ScheduleBlock> get dailyPlan => _planner.generateDailyPlan(
    _tasks,
    _availableMinutes,
    startTime: _scheduleAnchorTime,
  );
  Task? get activeFocusTask => _activeFocusTask;
  bool get isLoading => _isLoading;
  bool get isFocusing => _activeFocusTask != null && _isTimerRunning;
  int get availableMinutes => _availableMinutes;
  int get focusDurationMinutes => _focusDurationMinutes;
  int get focusScore => _focusScore;
  DailyStrategy get todaysStrategy => _strategyGenerator.generateStrategy(
    _focusScore,
    _skippedTasksToday,
    _difficultTasksCount,
  );
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerRunning => _isTimerRunning;

  String get formattedRemainingTime {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get completedCount =>
      _tasks.where((Task task) => task.isCompleted).length;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _taskService.getTasks();
    _sortTasks();

    await _planner.refreshLearnedDurations(
      _tasks.map((Task t) => t.id).toList(),
    );
    await _planner.refreshBehaviorDifficulties(
      _tasks.map((Task t) => t.id).toList(),
    );
    _todayFocusEvents = await _focusIntegrityService.getEventsForDay(
      DateTime.now(),
    );
    _focusScore = _focusIntegrityService.calculateDailyScore(_todayFocusEvents);
    _refreshSkippedSignal();
    await _refreshDifficultTaskSignal();
    _startDriftMonitor();
    _startSyncMonitor();

    _isLoading = false;
    notifyListeners();
  }

  void checkScheduleDrift() {
    final DateTime now = DateTime.now();
    final List<Task> remainingTasks = _tasks
        .where((Task task) => !task.isCompleted)
        .toList();
    if (remainingTasks.isEmpty) {
      return;
    }

    final List<ScheduleBlock> currentPlan = _planner.generateDailyPlan(
      remainingTasks,
      _availableMinutes,
      startTime: _scheduleAnchorTime,
    );

    final ScheduleBlock? firstTaskBlock = currentPlan
        .cast<ScheduleBlock?>()
        .firstWhere(
          (ScheduleBlock? block) => block?.type == ScheduleBlockTypes.task,
          orElse: () => null,
        );
    if (firstTaskBlock == null) {
      return;
    }

    if (_rescheduleService.shouldReschedule(firstTaskBlock.startTime, now)) {
      _scheduleAnchorTime = now;
      notifyListeners();
    }
  }

  void regenerateTodayPlan() {
    _scheduleAnchorTime = DateTime.now();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    final Task localTask = task.copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _taskService.addTask(localTask);
    _tasks.add(localTask);
    _sortTasks();
    await _refreshDifficultTaskSignal();
    notifyListeners();
  }

  Future<void> toggleTask(Task task) async {
    final Task updated = task.copyWith(
      isCompleted: !task.isCompleted,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _taskService.updateTask(updated);

    if (!task.isCompleted && updated.isCompleted) {
      final DateTime? deadline = task.deadline;
      if (deadline != null && !DateTime.now().isAfter(deadline)) {
        _behaviorPredictionService.recordEarlyCompletion(task.id);
      } else {
        _behaviorPredictionService.recordLateCompletion(task.id);
      }
      await _planner.refreshBehaviorDifficulties(<String>[task.id]);
    }

    if (!task.isCompleted &&
        updated.isCompleted &&
        _isTaskCompletedOnTime(task)) {
      _recordEvent(
        FocusEvent(
          type: FocusEventType.taskCompletedOnTime,
          timestamp: DateTime.now(),
          scoreImpact: 8,
        ),
      );
    }

    final int index = _tasks.indexWhere((Task item) => item.id == task.id);
    if (index == -1) {
      return;
    }

    _tasks[index] = updated;
    _sortTasks();
    await _refreshDifficultTaskSignal();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(Task task) {
    return toggleTask(task);
  }

  Future<void> deleteTask(String id) async {
    final int existingIndex = _tasks.indexWhere((Task task) => task.id == id);
    final Task? toDelete = existingIndex == -1 ? null : _tasks[existingIndex];

    await _taskService.deleteTask(id);
    _tasks.removeWhere((Task task) => task.id == id);

    if (toDelete != null && !toDelete.isCompleted) {
      _behaviorPredictionService.recordSkip(id);
      await _planner.refreshBehaviorDifficulties(<String>[id]);
      _recordEvent(
        FocusEvent(
          type: FocusEventType.taskSkipped,
          timestamp: DateTime.now(),
          scoreImpact: -5,
        ),
      );
    }

    await _refreshDifficultTaskSignal();

    notifyListeners();
  }

  void setAvailableMinutes(int minutes) {
    _availableMinutes = minutes.clamp(0, 24 * 60);
    notifyListeners();
  }

  void startFocus(Task task) {
    if (task.isCompleted) {
      return;
    }

    _activeFocusTask = task;
    _focusStartTime = DateTime.now();
    _remainingSeconds = _focusDurationMinutes * 60;
    _isTimerRunning = true;
    _focusTimerService.start(onTick: _onTimerTick);
    notifyListeners();
  }

  void setFocusDurationMinutes(int minutes) {
    if (_isTimerRunning) {
      return;
    }

    _focusDurationMinutes = minutes;
    _remainingSeconds = _focusDurationMinutes * 60;
    notifyListeners();
  }

  void startFocusTimer() {
    if (_remainingSeconds == 0) {
      _remainingSeconds = _focusDurationMinutes * 60;
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
        _activeFocusTask != null && _remainingSeconds > 0 && _isTimerRunning;

    _isTimerRunning = false;
    _activeFocusTask = null;
    _focusStartTime = null;
    _focusTimerService.stop();
    _remainingSeconds = _focusDurationMinutes * 60;

    if (stoppedEarly) {
      _recordEvent(
        FocusEvent(
          type: FocusEventType.focusSessionStoppedEarly,
          timestamp: DateTime.now(),
          scoreImpact: -8,
        ),
      );
    }

    notifyListeners();
  }

  void _onTimerTick() {
    if (_remainingSeconds <= 0) {
      _isTimerRunning = false;
      _activeFocusTask = null;
      _focusTimerService.stop();
      notifyListeners();
      return;
    }

    _remainingSeconds -= 1;

    if (_remainingSeconds == 0) {
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

      return;
    }

    notifyListeners();
  }

  Future<void> _completeFocusedTask(
    Task task,
    DateTime? sessionStart,
    DateTime sessionEnd,
  ) async {
    if (sessionStart != null) {
      final int durationMinutes = _focusDurationMinutes;
      final FocusSession session = FocusSession(
        taskId: task.id,
        startTime: sessionStart,
        endTime: sessionEnd,
        durationMinutes: durationMinutes,
      );
      await _historyService.saveSession(session);
      await _planner.refreshLearnedDurations(<String>[task.id]);
      _recordEvent(
        FocusEvent(
          type: FocusEventType.focusSessionCompleted,
          timestamp: DateTime.now(),
          scoreImpact: 10,
        ),
      );
      notifyListeners();
    }

    final int index = _tasks.indexWhere((Task item) => item.id == task.id);
    if (index == -1) {
      return;
    }

    final Task currentTask = _tasks[index];
    if (!currentTask.isCompleted) {
      await toggleTask(currentTask);
    }
  }

  void _recordEvent(FocusEvent event) {
    _focusIntegrityService.recordEvent(event);
    _todayFocusEvents.add(event);
    _focusScore = _focusIntegrityService.calculateDailyScore(_todayFocusEvents);
    _refreshSkippedSignal();
    notifyListeners();
  }

  void _refreshSkippedSignal() {
    _skippedTasksToday = _todayFocusEvents
        .where((FocusEvent event) => event.type == FocusEventType.taskSkipped)
        .length;
  }

  Future<void> _refreshDifficultTaskSignal() async {
    int difficult = 0;

    for (final Task task in _tasks.where((Task t) => !t.isCompleted)) {
      final behavior = await _behaviorPredictionService.getBehavior(task.id);
      final int difficulty = _behaviorPredictionService.calculateDifficulty(
        behavior,
      );
      if (difficulty > 0) {
        difficult += 1;
      }
    }

    _difficultTasksCount = difficult;
  }

  bool _isTaskCompletedOnTime(Task task) {
    final DateTime? deadline = task.deadline;
    if (deadline == null) {
      return false;
    }

    return !DateTime.now().isAfter(deadline);
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

  void _startDriftMonitor() {
    _driftMonitor?.cancel();
    _driftMonitor = Timer.periodic(const Duration(minutes: 5), (_) {
      checkScheduleDrift();
    });
  }

  void _startSyncMonitor() {
    _syncMonitor?.cancel();
    _syncMonitor = Timer.periodic(const Duration(minutes: 2), (_) {
      unawaited(_taskService.syncTasks());
    });
  }

  @override
  void dispose() {
    _driftMonitor?.cancel();
    _syncMonitor?.cancel();
    _focusTimerService.dispose();
    super.dispose();
  }
}
