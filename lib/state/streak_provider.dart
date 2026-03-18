import 'package:flutter/foundation.dart';

import '../services/streak_service.dart';

/// Exposes the current focus streak to the UI via [ChangeNotifier].
class StreakProvider extends ChangeNotifier {
  StreakProvider({required StreakService streakService})
    : _streakService = streakService;

  final StreakService _streakService;

  /// The number of consecutive days on which at least one focus session
  /// was completed. Resets to 0 when a day is missed.
  int get currentStreak => _streakService.currentStreak;

  /// Call whenever a focus session completes to update the streak.
  void recordSessionCompleted() {
    _streakService.recordSessionCompleted();
    notifyListeners();
  }
}
