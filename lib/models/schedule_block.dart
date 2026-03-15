import 'task.dart';

class ScheduleBlockTypes {
  ScheduleBlockTypes._();

  static const String task = 'task';
  static const String breakTime = 'break';
}

class ScheduleBlock {
  const ScheduleBlock({
    required this.startTime,
    required this.endTime,
    required this.type,
    this.task,
  });

  final DateTime startTime;
  final DateTime endTime;
  final Task? task;
  final String type;
}
