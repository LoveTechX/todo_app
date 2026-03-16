import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/focus_event.dart';
import '../models/focus_session.dart';
import '../models/task.dart';
import 'task_history_service.dart';

enum GlobalSearchResultType { task, focusSession, analytics }

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final GlobalSearchResultType type;
  final String title;
  final String subtitle;
  final String? trailing;
}

class SearchService extends ChangeNotifier {
  SearchService({
    required TaskHistoryService historyService,
    this.debounceDuration = const Duration(milliseconds: 280),
  }) : _historyService = historyService;

  final TaskHistoryService _historyService;
  final Duration debounceDuration;

  Timer? _debounce;
  String _query = '';
  bool _isSearching = false;
  List<Task> _tasks = <Task>[];
  List<FocusEvent> _focusEvents = <FocusEvent>[];
  int _focusScore = 0;
  int _skippedTasksToday = 0;
  int _difficultTasksCount = 0;
  List<GlobalSearchResult> _results = <GlobalSearchResult>[];

  String get query => _query;
  bool get isSearching => _isSearching;
  List<GlobalSearchResult> get results =>
      List<GlobalSearchResult>.unmodifiable(_results);

  void updateSearchContext({
    required List<Task> tasks,
    required List<FocusEvent> focusEvents,
    required int focusScore,
    required int skippedTasksToday,
    required int difficultTasksCount,
  }) {
    _tasks = List<Task>.from(tasks);
    _focusEvents = List<FocusEvent>.from(focusEvents);
    _focusScore = focusScore;
    _skippedTasksToday = skippedTasksToday;
    _difficultTasksCount = difficultTasksCount;

    if (_query.trim().isNotEmpty) {
      _runSearch(_query);
    }
  }

  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _isSearching = false;
      _results = <GlobalSearchResult>[];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounce = Timer(debounceDuration, () {
      _runSearch(value);
    });
  }

  void _runSearch(String rawQuery) {
    final String query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      _isSearching = false;
      _results = <GlobalSearchResult>[];
      notifyListeners();
      return;
    }

    final List<GlobalSearchResult> taskResults = _tasks
        .where((Task task) => _taskMatches(task, query))
        .map(_toTaskResult)
        .toList();

    final Map<String, Task> tasksById = <String, Task>{
      for (final Task task in _tasks) task.id: task,
    };

    final List<FocusSession> sessions = _historyService.getAllSessions();
    final List<GlobalSearchResult> sessionResults = sessions
        .where(
          (FocusSession session) => _sessionMatches(session, tasksById, query),
        )
        .map((FocusSession session) => _toSessionResult(session, tasksById))
        .toList();

    final List<GlobalSearchResult> analyticsResults = <GlobalSearchResult>[];
    analyticsResults.addAll(
      _focusEvents
          .where((FocusEvent event) => _focusEventMatches(event, query))
          .map(_toFocusEventResult),
    );

    if ('focus score'.contains(query) ||
        query.contains(_focusScore.toString()) ||
        query.contains('score')) {
      analyticsResults.add(
        GlobalSearchResult(
          type: GlobalSearchResultType.analytics,
          title: 'Focus Score',
          subtitle: 'Current focus score',
          trailing: _focusScore.toString(),
        ),
      );
    }

    if ('skipped tasks'.contains(query) ||
        query.contains(_skippedTasksToday.toString()) ||
        query.contains('skipped')) {
      analyticsResults.add(
        GlobalSearchResult(
          type: GlobalSearchResultType.analytics,
          title: 'Skipped Tasks Today',
          subtitle: 'Tasks skipped in today\'s analytics window',
          trailing: _skippedTasksToday.toString(),
        ),
      );
    }

    if ('difficult tasks'.contains(query) ||
        query.contains(_difficultTasksCount.toString()) ||
        query.contains('difficult')) {
      analyticsResults.add(
        GlobalSearchResult(
          type: GlobalSearchResultType.analytics,
          title: 'Difficult Task Signal',
          subtitle: 'Remaining tasks with predicted difficulty',
          trailing: _difficultTasksCount.toString(),
        ),
      );
    }

    _results = <GlobalSearchResult>[
      ...taskResults,
      ...sessionResults,
      ...analyticsResults,
    ];
    _isSearching = false;
    notifyListeners();
  }

  bool _taskMatches(Task task, String query) {
    final String priority = task.priority.name;
    final String completion = task.isCompleted
        ? 'completed done'
        : 'active open';

    return task.title.toLowerCase().contains(query) ||
        priority.contains(query) ||
        completion.contains(query);
  }

  bool _sessionMatches(
    FocusSession session,
    Map<String, Task> tasksById,
    String query,
  ) {
    final Task? task = tasksById[session.taskId];
    final String taskTitle = task?.title.toLowerCase() ?? '';
    final String duration = '${session.durationMinutes} min';
    final String dateLabel =
        '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';

    return taskTitle.contains(query) ||
        session.taskId.toLowerCase().contains(query) ||
        duration.contains(query) ||
        dateLabel.contains(query) ||
        'focus session'.contains(query);
  }

  bool _focusEventMatches(FocusEvent event, String query) {
    final String label = _formatEventType(event.type).toLowerCase();
    final String impact = event.scoreImpact.toString();

    return label.contains(query) ||
        impact.contains(query) ||
        'analytics'.contains(query);
  }

  GlobalSearchResult _toTaskResult(Task task) {
    return GlobalSearchResult(
      type: GlobalSearchResultType.task,
      title: task.title,
      subtitle:
          'Task • ${task.priority.name[0].toUpperCase()}${task.priority.name.substring(1)} priority',
      trailing: task.isCompleted ? 'Done' : 'Open',
    );
  }

  GlobalSearchResult _toSessionResult(
    FocusSession session,
    Map<String, Task> tasksById,
  ) {
    final Task? task = tasksById[session.taskId];
    final String taskTitle = task?.title ?? 'Task ${session.taskId}';

    return GlobalSearchResult(
      type: GlobalSearchResultType.focusSession,
      title: taskTitle,
      subtitle:
          'Focus session • ${session.durationMinutes} min • ${_formatDate(session.startTime)}',
      trailing: '${session.durationMinutes}m',
    );
  }

  GlobalSearchResult _toFocusEventResult(FocusEvent event) {
    return GlobalSearchResult(
      type: GlobalSearchResultType.analytics,
      title: _formatEventType(event.type),
      subtitle: 'Analytics event • ${_formatDate(event.timestamp)}',
      trailing: event.scoreImpact > 0
          ? '+${event.scoreImpact}'
          : event.scoreImpact.toString(),
    );
  }

  String _formatEventType(FocusEventType type) {
    switch (type) {
      case FocusEventType.focusSessionCompleted:
        return 'Focus Session Completed';
      case FocusEventType.taskCompletedOnTime:
        return 'Task Completed On Time';
      case FocusEventType.taskSkipped:
        return 'Task Skipped';
      case FocusEventType.focusSessionStoppedEarly:
        return 'Focus Session Stopped Early';
    }
  }

  String _formatDate(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
