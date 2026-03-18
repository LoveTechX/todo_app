import 'package:flutter/foundation.dart';

import '../models/daily_strategy.dart';
import '../models/focus_event.dart';
import '../models/task.dart';
import '../services/behavior_prediction_service.dart';
import '../services/focus_integrity_service.dart';
import '../services/strategy_generator_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({
    required FocusIntegrityService focusIntegrityService,
    required BehaviorPredictionService behaviorPredictionService,
    StrategyGeneratorService? strategyGeneratorService,
  }) : _focusIntegrityService = focusIntegrityService,
       _behaviorPredictionService = behaviorPredictionService,
       _strategyGenerator =
           strategyGeneratorService ?? const StrategyGeneratorService();

  final FocusIntegrityService _focusIntegrityService;
  final BehaviorPredictionService _behaviorPredictionService;
  final StrategyGeneratorService _strategyGenerator;

  List<FocusEvent> _todayFocusEvents = <FocusEvent>[];
  int _focusScore = 0;
  int _skippedTasksToday = 0;
  int _difficultTasksCount = 0;

  int get focusScore => _focusScore;
  List<FocusEvent> get focusEvents =>
      List<FocusEvent>.unmodifiable(_todayFocusEvents);
  int get skippedTasksToday => _skippedTasksToday;
  int get difficultTasksCount => _difficultTasksCount;
  DailyStrategy get todaysStrategy => _strategyGenerator.generateStrategy(
    _focusScore,
    _skippedTasksToday,
    _difficultTasksCount,
  );

  Future<void> loadDailyEvents() async {
    try {
      _todayFocusEvents = await _focusIntegrityService.getEventsForDay(
        DateTime.now(),
      );
      _focusScore = _clampScore(
        _focusIntegrityService.calculateDailyScore(_todayFocusEvents),
      );
      _refreshSkippedSignal();
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('AnalyticsProvider.loadDailyEvents failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> recordCompletion(Task task) async {
    final DateTime? deadline = task.deadline;
    if (deadline != null && !DateTime.now().isAfter(deadline)) {
      _behaviorPredictionService.recordEarlyCompletion(task.id);
    } else {
      _behaviorPredictionService.recordLateCompletion(task.id);
    }

    if (_isTaskCompletedOnTime(task)) {
      recordEvent(
        FocusEvent(
          type: FocusEventType.taskCompletedOnTime,
          timestamp: DateTime.now(),
          scoreImpact: 8,
        ),
      );
    }
  }

  Future<void> recordTaskSkipped(String taskId) async {
    _behaviorPredictionService.recordSkip(taskId);
    recordEvent(
      FocusEvent(
        type: FocusEventType.taskSkipped,
        timestamp: DateTime.now(),
        scoreImpact: -5,
      ),
    );
  }

  void recordFocusSessionCompleted() {
    recordEvent(
      FocusEvent(
        type: FocusEventType.focusSessionCompleted,
        timestamp: DateTime.now(),
        scoreImpact: 10,
      ),
    );
  }

  void recordFocusSessionStoppedEarly() {
    recordEvent(
      FocusEvent(
        type: FocusEventType.focusSessionStoppedEarly,
        timestamp: DateTime.now(),
        scoreImpact: -8,
      ),
    );
  }

  void recordEvent(FocusEvent event) {
    try {
      _focusIntegrityService.recordEvent(event);
      _todayFocusEvents.add(event);
      _focusScore = _clampScore(
        _focusIntegrityService.calculateDailyScore(_todayFocusEvents),
      );
      _refreshSkippedSignal();
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('AnalyticsProvider.recordEvent failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> refreshDifficultTaskSignal(List<Task> tasks) async {
    try {
      final List<Task> remainingTasks = tasks
          .where((Task task) => !task.isCompleted)
          .toList();

      final List<int> difficulties = await Future.wait(
        remainingTasks.map((Task task) async {
          final behavior = await _behaviorPredictionService.getBehavior(
            task.id,
          );
          return _behaviorPredictionService.calculateDifficulty(behavior);
        }),
      );

      _difficultTasksCount = difficulties
          .where((int difficulty) => difficulty > 0)
          .length;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('AnalyticsProvider.refreshDifficultTaskSignal failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _refreshSkippedSignal() {
    _skippedTasksToday = _todayFocusEvents
        .where((FocusEvent event) => event.type == FocusEventType.taskSkipped)
        .length;
  }

  bool _isTaskCompletedOnTime(Task task) {
    final DateTime? deadline = task.deadline;
    if (deadline == null) {
      return false;
    }

    return !DateTime.now().isAfter(deadline);
  }

  /// Ensures focus score never falls below 0.
  int _clampScore(int score) => score < 0 ? 0 : score;
}
