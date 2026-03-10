import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/focus_timer_service.dart';
import '../services/task_service.dart';

class TodoProvider extends ChangeNotifier {
  TodoProvider({
    required TaskService taskService,
    required FocusTimerService focusTimerService,
  }) : _taskService = taskService,
       _focusTimerService = focusTimerService;

  final TaskService _taskService;
  final FocusTimerService _focusTimerService;

  List<Task> _tasks = <Task>[];
  int _focusDurationMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isLoading = false;
  bool _isTimerRunning = false;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  int get focusDurationMinutes => _focusDurationMinutes;
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

    _tasks = await _taskService.fetchTasks();
    _sortTasks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(String title, TaskPriority priority) async {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final Task task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: trimmed,
      priority: priority,
      createdAt: DateTime.now(),
    );

    await _taskService.addTask(task);
    _tasks.add(task);
    _sortTasks();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final Task updated = task.copyWith(isCompleted: !task.isCompleted);
    await _taskService.updateTask(updated);

    final int index = _tasks.indexWhere((Task item) => item.id == task.id);
    if (index == -1) {
      return;
    }

    _tasks[index] = updated;
    _sortTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _taskService.deleteTask(id);
    _tasks.removeWhere((Task task) => task.id == id);
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
    _isTimerRunning = false;
    _focusTimerService.stop();
    _remainingSeconds = _focusDurationMinutes * 60;
    notifyListeners();
  }

  void _onTimerTick() {
    if (_remainingSeconds <= 0) {
      _isTimerRunning = false;
      _focusTimerService.stop();
      notifyListeners();
      return;
    }

    _remainingSeconds -= 1;

    if (_remainingSeconds == 0) {
      _isTimerRunning = false;
      _focusTimerService.stop();
    }

    notifyListeners();
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

  @override
  void dispose() {
    _focusTimerService.dispose();
    super.dispose();
  }
}
