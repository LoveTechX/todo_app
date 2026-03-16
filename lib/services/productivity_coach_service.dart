import '../models/focus_session.dart';
import 'task_history_service.dart';

class ProductivityCoachService {
  ProductivityCoachService({required TaskHistoryService historyService})
    : _historyService = historyService;

  final TaskHistoryService _historyService;

  List<FocusSession> _todaySessions = <FocusSession>[];
  int _skippedTasks = 0;
  int _focusScore = 0;
  int _completedTasks = 0;

  Future<void> refreshInputs({
    required int skippedTasks,
    required int focusScore,
    required int completedTasks,
  }) async {
    _todaySessions = await _historyService.getSessionsForDay(DateTime.now());
    _skippedTasks = skippedTasks;
    _focusScore = focusScore;
    _completedTasks = completedTasks;
  }

  String generateDailyAdvice() {
    if (_todaySessions.isEmpty && _completedTasks == 0) {
      return 'Start with one 25 minute focus block to build momentum.';
    }

    final double averageSessionLength = _todaySessions.isEmpty
        ? 0
        : _todaySessions
                  .map((FocusSession session) => session.durationMinutes)
                  .reduce((int a, int b) => a + b) /
              _todaySessions.length;

    final int morningCompletions = _todaySessions
        .where((FocusSession session) => session.endTime.hour < 12)
        .length;
    final int eveningCompletions = _todaySessions
        .where((FocusSession session) => session.endTime.hour >= 18)
        .length;

    if (morningCompletions > eveningCompletions && morningCompletions >= 2) {
      return 'You focus best in the morning. Protect your first 2 hours for deep work.';
    }

    if (averageSessionLength > 35) {
      return 'Break long tasks into 25 minute sessions with short resets in between.';
    }

    if (_focusScore < 20 && _skippedTasks >= 2) {
      return 'Avoid scheduling deep work late evening. Front-load your hardest task earlier.';
    }

    if (_completedTasks >= 3 && _skippedTasks == 0) {
      return 'Great consistency today. Keep batching similar tasks to maintain flow.';
    }

    if (eveningCompletions > morningCompletions) {
      return 'Your completion times trend later in the day. Add a short mid-afternoon reset to protect energy.';
    }

    return 'Plan your next task before each session ends to reduce context-switching.';
  }
}
