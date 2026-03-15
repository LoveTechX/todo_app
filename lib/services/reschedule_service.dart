class RescheduleService {
  const RescheduleService();

  bool shouldReschedule(DateTime plannedStart, DateTime now) {
    final Duration delay = now.difference(plannedStart);
    return delay > const Duration(minutes: 10);
  }
}
