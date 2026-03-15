import 'package:hive/hive.dart';

import '../models/focus_session.dart';

class TaskHistoryService {
  static const String boxName = 'focus_sessions';

  Box<dynamic> get _box => Hive.box(boxName);

  Future<void> saveSession(FocusSession session) async {
    await _box.add(session.toMap());
  }

  Future<List<FocusSession>> getSessionsForTask(String taskId) async {
    return _box.values
        .map(
          (dynamic raw) =>
              FocusSession.fromMap(Map<String, dynamic>.from(raw as Map)),
        )
        .where((FocusSession s) => s.taskId == taskId)
        .toList();
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
