import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/focus_event.dart';

class FocusIntegrityService {
  static const String boxName = 'focus_events';

  Box<dynamic> get _box => Hive.box(boxName);

  void recordEvent(FocusEvent event) {
    try {
      _box.add(event.toMap());
    } catch (error, stackTrace) {
      debugPrint('FocusIntegrityService.recordEvent failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  int calculateDailyScore(List<FocusEvent> events) {
    return events.fold<int>(
      0,
      (int sum, FocusEvent event) => sum + event.scoreImpact,
    );
  }

  Future<List<FocusEvent>> getEventsForDay(DateTime day) async {
    try {
      return _box.values
          .map(
            (dynamic raw) =>
                FocusEvent.fromMap(Map<String, dynamic>.from(raw as Map)),
          )
          .where((FocusEvent event) => _isSameDay(event.timestamp, day))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('FocusIntegrityService.getEventsForDay failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <FocusEvent>[];
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
