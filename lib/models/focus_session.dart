class FocusSession {
  const FocusSession({
    required this.taskId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  final String taskId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      taskId: map['taskId'] as String? ?? '',
      startTime:
          DateTime.tryParse(map['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(map['endTime'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] as int? ?? 0,
    );
  }
}
