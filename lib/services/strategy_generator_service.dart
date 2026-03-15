import '../models/daily_strategy.dart';

class StrategyGeneratorService {
  const StrategyGeneratorService();

  DailyStrategy generateStrategy(
    int focusScore,
    int skippedTasks,
    int difficultTasks,
  ) {
    if (focusScore < 50) {
      return const DailyStrategy(
        message: 'Start with a short focus session to build momentum.',
      );
    }

    if (skippedTasks > 2) {
      return const DailyStrategy(
        message: 'Complete difficult tasks earlier in the day.',
      );
    }

    if (difficultTasks > 0) {
      return const DailyStrategy(
        message: 'Start with your hardest task today.',
      );
    }

    return const DailyStrategy(
      message: 'Maintain your current focus rhythm today.',
    );
  }
}
