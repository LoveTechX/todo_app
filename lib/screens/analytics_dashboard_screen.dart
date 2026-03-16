import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/focus_event.dart';
import '../models/focus_session.dart';
import '../services/focus_integrity_service.dart';
import '../services/task_history_service.dart';
import '../state/analytics_provider.dart';
import '../state/productivity_coach_provider.dart';
import '../state/task_provider.dart';
import '../widgets/focus_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  static const String _analyticsHeroTag = 'analytics-screen-hero';

  final TaskHistoryService _historyService = TaskHistoryService();
  final FocusIntegrityService _integrityService = FocusIntegrityService();

  bool _isLoading = true;
  int _focusMinutesToday = 0;
  int _focusStreakDays = 0;
  int _focusScoreToday = 0;
  List<FocusBarPoint> _weeklyPoints = <FocusBarPoint>[];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final DateTime now = DateTime.now();
    final DateTime weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final DateTime weekEnd = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    final List<FocusSession> todaySessions = await _historyService
        .getSessionsForDay(now);
    final List<FocusSession> weeklySessions = await _historyService
        .getSessionsInRange(start: weekStart, end: weekEnd);
    final List<FocusEvent> todayEvents = await _integrityService
        .getEventsForDay(now);

    final int todayMinutes = todaySessions.fold<int>(
      0,
      (int sum, FocusSession session) => sum + session.durationMinutes,
    );

    final Map<DateTime, int> minutesByDay = <DateTime, int>{};
    for (int i = 0; i < 7; i += 1) {
      final DateTime day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      minutesByDay[day] = 0;
    }

    for (final FocusSession session in weeklySessions) {
      final DateTime key = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      if (minutesByDay.containsKey(key)) {
        minutesByDay[key] = (minutesByDay[key] ?? 0) + session.durationMinutes;
      }
    }

    final List<FocusBarPoint> points = minutesByDay.entries.map((
      MapEntry<DateTime, int> entry,
    ) {
      const List<String> labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return FocusBarPoint(
        label: labels[entry.key.weekday - 1],
        minutes: entry.value,
      );
    }).toList();

    int streak = 0;
    DateTime cursor = DateTime(now.year, now.month, now.day);
    while (true) {
      final int minutes = minutesByDay[cursor] ?? 0;
      if (minutes <= 0) {
        break;
      }
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _focusMinutesToday = todayMinutes;
      _focusStreakDays = streak;
      _focusScoreToday = _integrityService.calculateDailyScore(todayEvents);
      _weeklyPoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TaskProvider taskProvider = context.watch<TaskProvider>();
    final AnalyticsProvider analyticsProvider = context
        .watch<AnalyticsProvider>();
    final ProductivityCoachProvider coachProvider = context
        .watch<ProductivityCoachProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Hero(tag: _analyticsHeroTag, child: Icon(Icons.analytics_outlined)),
            SizedBox(width: 8),
            Text('Analytics Dashboard'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          title: 'Focus Time Today',
                          value: '$_focusMinutesToday min',
                          icon: Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Completed Tasks',
                          value: '${taskProvider.completedCount}',
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          title: 'Focus Streak',
                          value: '$_focusStreakDays days',
                          icon: Icons.local_fire_department,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Focus Score',
                          value: '$_focusScoreToday',
                          icon: Icons.insights,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 280),
                    opacity: _isLoading ? 0.3 : 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Weekly Focus Chart',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            FocusChart(points: _weeklyPoints),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 320),
                    opacity: _isLoading ? 0.3 : 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'AI Productivity Coach',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(coachProvider.todaysAdvice),
                            const SizedBox(height: 8),
                            Text(
                              'Signal: score ${analyticsProvider.focusScore}, skipped ${analyticsProvider.skippedTasksToday}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
