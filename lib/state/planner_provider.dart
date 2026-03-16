import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/schedule_block.dart';
import '../models/task.dart';
import '../services/reschedule_service.dart';
import '../services/schedule_planner_service.dart';
import 'task_provider.dart';

class PlannerProvider extends ChangeNotifier {
  PlannerProvider({
    required TaskProvider taskProvider,
    required SchedulePlannerService plannerService,
    RescheduleService? rescheduleService,
    bool enableDriftMonitor = true,
  }) : _taskProvider = taskProvider,
       _plannerService = plannerService,
       _rescheduleService = rescheduleService ?? const RescheduleService(),
       _enableDriftMonitor = enableDriftMonitor {
    _taskProvider.addListener(_onTasksChanged);
  }

  final TaskProvider _taskProvider;
  final SchedulePlannerService _plannerService;
  final RescheduleService _rescheduleService;
  final bool _enableDriftMonitor;

  int _availableMinutes = 240;
  DateTime? _scheduleAnchorTime;
  Timer? _driftMonitor;

  List<ScheduleBlock> get dailyPlan => _plannerService.generateDailyPlan(
    _taskProvider.tasks,
    _availableMinutes,
    startTime: _scheduleAnchorTime,
  );
  int get availableMinutes => _availableMinutes;
  DateTime? get scheduleAnchorTime => _scheduleAnchorTime;

  Future<void> initialize() async {
    if (_enableDriftMonitor) {
      _startDriftMonitor();
    }
  }

  void setAvailableMinutes(int minutes) {
    _availableMinutes = minutes.clamp(0, 24 * 60);
    notifyListeners();
  }

  void regenerateTodayPlan() {
    _scheduleAnchorTime = DateTime.now();
    notifyListeners();
  }

  void checkScheduleDrift() {
    final DateTime now = DateTime.now();
    final List<Task> remainingTasks = _taskProvider.tasks
        .where((Task task) => !task.isCompleted)
        .toList();
    if (remainingTasks.isEmpty) {
      return;
    }

    final List<ScheduleBlock> currentPlan = _plannerService.generateDailyPlan(
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

  Future<void> refreshLearnedDurationsForTaskIds(List<String> taskIds) async {
    try {
      await _plannerService.refreshLearnedDurations(taskIds);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('PlannerProvider.refreshLearnedDurations failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> refreshBehaviorDifficultiesForTaskIds(
    List<String> taskIds,
  ) async {
    try {
      await _plannerService.refreshBehaviorDifficulties(taskIds);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('PlannerProvider.refreshBehaviorDifficulties failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _onTasksChanged() {
    notifyListeners();
  }

  void _startDriftMonitor() {
    _driftMonitor?.cancel();
    _driftMonitor = Timer.periodic(const Duration(minutes: 5), (_) {
      checkScheduleDrift();
    });
  }

  @override
  void dispose() {
    _driftMonitor?.cancel();
    _taskProvider.removeListener(_onTasksChanged);
    super.dispose();
  }
}
