import 'package:hive/hive.dart';

/// Tracks daily focus streak using a Hive box named "streak".
///
/// A streak is incremented when at least one focus session is completed in a
/// day. Missing a day resets the streak to 0. Multiple sessions on the same
/// day do not increment the streak more than once.
class StreakService {
  static const String boxName = 'streak';

  static const String _currentStreakKey = 'currentStreak';
  static const String _lastActiveDateKey = 'lastActiveDate';

  Box get _box => Hive.box(boxName);

  /// Current streak count. Defaults to 0 when no sessions have been recorded.
  int get currentStreak => (_box.get(_currentStreakKey) as int?) ?? 0;

  String? get _lastActiveDate => _box.get(_lastActiveDateKey) as String?;

  String _toDateString(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Records a completed focus session and updates the streak accordingly.
  ///
  /// - Same day: no-op (streak already counted today).
  /// - Next day: increment streak.
  /// - Gap of 2+ days: reset streak to 1.
  void recordSessionCompleted() {
    final String today = _toDateString(DateTime.now());
    final String? last = _lastActiveDate;

    if (last == today) {
      return;
    }

    final int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final DateTime lastDate = DateTime.parse(last);
      final DateTime todayMidnight = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final DateTime lastMidnight = DateTime(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );
      final int daysDiff = todayMidnight.difference(lastMidnight).inDays;
      newStreak = daysDiff == 1 ? currentStreak + 1 : 1;
    }

    _box.put(_currentStreakKey, newStreak);
    _box.put(_lastActiveDateKey, today);
  }
}
