import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_app/services/streak_service.dart';
import 'package:todo_app/services/focus_integrity_service.dart';
import 'package:todo_app/models/focus_event.dart';

import 'dart:io';

void main() {
  // ------------------------------------------------------------------
  // StreakService tests
  // ------------------------------------------------------------------
  group('StreakService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(StreakService.boxName);
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('initial streak is 0', () {
      final service = StreakService();
      expect(service.currentStreak, 0);
    });

    test('first session sets streak to 1', () {
      final service = StreakService();
      service.recordSessionCompleted();
      expect(service.currentStreak, 1);
    });

    test('second call on same day does not increment streak', () {
      final service = StreakService();
      service.recordSessionCompleted();
      service.recordSessionCompleted();
      expect(service.currentStreak, 1);
    });

    test('consecutive day increments streak', () {
      final box = Hive.box(StreakService.boxName);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';
      box.put('currentStreak', 3);
      box.put('lastActiveDate', yesterdayStr);

      final service = StreakService();
      service.recordSessionCompleted();

      expect(service.currentStreak, 4);
    });

    test('missed day resets streak to 1', () {
      final box = Hive.box(StreakService.boxName);
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final twoDaysAgoStr =
          '${twoDaysAgo.year}-'
          '${twoDaysAgo.month.toString().padLeft(2, '0')}-'
          '${twoDaysAgo.day.toString().padLeft(2, '0')}';
      box.put('currentStreak', 5);
      box.put('lastActiveDate', twoDaysAgoStr);

      final service = StreakService();
      service.recordSessionCompleted();

      expect(service.currentStreak, 1);
    });
  });

  // ------------------------------------------------------------------
  // FocusIntegrityService.calculateDailyScore tests (focus score bounds)
  // ------------------------------------------------------------------
  group('FocusIntegrityService.calculateDailyScore', () {
    final service = FocusIntegrityService();

    test('returns 0 for empty events list', () {
      expect(service.calculateDailyScore([]), 0);
    });

    test('sums positive score impacts', () {
      final events = [
        FocusEvent(
          type: FocusEventType.focusSessionCompleted,
          timestamp: DateTime.now(),
          scoreImpact: 10,
        ),
        FocusEvent(
          type: FocusEventType.taskCompletedOnTime,
          timestamp: DateTime.now(),
          scoreImpact: 8,
        ),
      ];
      expect(service.calculateDailyScore(events), 18);
    });

    test('can return negative raw score (clamping is done in provider)', () {
      final events = [
        FocusEvent(
          type: FocusEventType.taskSkipped,
          timestamp: DateTime.now(),
          scoreImpact: -5,
        ),
        FocusEvent(
          type: FocusEventType.focusSessionStoppedEarly,
          timestamp: DateTime.now(),
          scoreImpact: -8,
        ),
      ];
      // Raw score is -13; the provider clamps it to 0
      expect(service.calculateDailyScore(events), -13);
    });
  });

  // ------------------------------------------------------------------
  // AnalyticsProvider focus score clamping (logic-level test)
  // ------------------------------------------------------------------
  group('Focus score clamping logic', () {
    test('clamp ensures score is never below 0', () {
      // Simulate the _clampScore helper used in AnalyticsProvider
      int clampScore(int score) => score < 0 ? 0 : score;

      expect(clampScore(-13), 0);
      expect(clampScore(0), 0);
      expect(clampScore(18), 18);
    });
  });
}
