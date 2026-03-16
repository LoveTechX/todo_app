import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/focus_session.dart';

class TaskHistoryService {
  static const String boxName = 'focus_sessions';

  Box<dynamic> get _box => Hive.box(boxName);

  List<FocusSession> getAllSessions() {
    try {
      return _box.values
          .map(
            (dynamic raw) =>
                FocusSession.fromMap(Map<String, dynamic>.from(raw as Map)),
          )
          .toList();
    } catch (error, stackTrace) {
      debugPrint('TaskHistoryService.getAllSessions failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <FocusSession>[];
    }
  }

  Future<void> saveSession(FocusSession session) async {
    try {
      await _box.add(session.toMap());
    } catch (error, stackTrace) {
      debugPrint('TaskHistoryService.saveSession failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<FocusSession>> getSessionsForTask(String taskId) async {
    try {
      return getAllSessions()
          .where((FocusSession session) => session.taskId == taskId)
          .toList();
    } catch (error, stackTrace) {
      debugPrint('TaskHistoryService.getSessionsForTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <FocusSession>[];
    }
  }

  Future<List<FocusSession>> getSessionsForDay(DateTime day) async {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    return getSessionsInRange(start: start, end: end);
  }

  Future<List<FocusSession>> getSessionsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return getAllSessions()
          .where(
            (FocusSession session) =>
                !session.startTime.isBefore(start) &&
                session.startTime.isBefore(end),
          )
          .toList();
    } catch (error, stackTrace) {
      debugPrint('TaskHistoryService.getSessionsInRange failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <FocusSession>[];
    }
  }

  double calculateAverageDuration(List<FocusSession> sessions) {
    if (sessions.isEmpty) {
      return 0;
    }

    final int total = sessions.fold<int>(
      0,
      (int sum, FocusSession s) => sum + s.durationMinutes,
    );
    return total / sessions.length;
  }
}
