import 'package:hive/hive.dart';

import '../models/focus_event.dart';

class FocusIntegrityService {
  static const String boxName = 'focus_events';

  Box<dynamic> get _box => Hive.box(boxName);

  void recordEvent(FocusEvent event) {
    _box.add(event.toMap());
  }

  int calculateDailyScore(List<FocusEvent> events) {
    return events.fold<int>(
      0,
      (int sum, FocusEvent event) => sum + event.scoreImpact,
    );
  }

  Future<List<FocusEvent>> getEventsForDay(DateTime day) async {
    return _box.values
        .map(
          (dynamic raw) =>
              FocusEvent.fromMap(Map<String, dynamic>.from(raw as Map)),
        )
        .where((FocusEvent event) => _isSameDay(event.timestamp, day))
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
