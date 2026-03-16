import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/productivity_coach_service.dart';
import 'analytics_provider.dart';
import 'task_provider.dart';

class ProductivityCoachProvider extends ChangeNotifier {
  ProductivityCoachProvider({
    required ProductivityCoachService coachService,
    required AnalyticsProvider analyticsProvider,
    required TaskProvider taskProvider,
  }) : _coachService = coachService,
       _analyticsProvider = analyticsProvider,
       _taskProvider = taskProvider {
    _analyticsProvider.addListener(_onSignalsChanged);
    _taskProvider.addListener(_onSignalsChanged);
    unawaited(refreshAdvice());
  }

  final ProductivityCoachService _coachService;
  final AnalyticsProvider _analyticsProvider;
  final TaskProvider _taskProvider;

  String _todaysAdvice = 'Gathering your productivity signals...';

  String get todaysAdvice => _todaysAdvice;

  Future<void> refreshAdvice() async {
    await _coachService.refreshInputs(
      skippedTasks: _analyticsProvider.skippedTasksToday,
      focusScore: _analyticsProvider.focusScore,
      completedTasks: _taskProvider.completedCount,
    );

    _todaysAdvice = _coachService.generateDailyAdvice();
    notifyListeners();
  }

  void _onSignalsChanged() {
    unawaited(refreshAdvice());
  }

  @override
  void dispose() {
    _analyticsProvider.removeListener(_onSignalsChanged);
    _taskProvider.removeListener(_onSignalsChanged);
    super.dispose();
  }
}
