import '../models/task.dart';

class EnergyProfileService {
  const EnergyProfileService();

  /// Returns the preferred cognitive load for a given time of day.
  /// - Before 11:00 → deep work
  /// - Before 16:00 → medium work
  /// - 16:00 onwards → light work
  CognitiveLoad preferredLoadForTime(DateTime now) {
    final int hour = now.hour;
    if (hour < 11) {
      return CognitiveLoad.deep;
    }
    if (hour < 16) {
      return CognitiveLoad.medium;
    }
    return CognitiveLoad.light;
  }
}
