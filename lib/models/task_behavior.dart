class TaskBehavior {
  const TaskBehavior({
    required this.taskId,
    required this.skips,
    required this.earlyCompletions,
    required this.lateCompletions,
  });

  final String taskId;
  final int skips;
  final int earlyCompletions;
  final int lateCompletions;

  TaskBehavior copyWith({
    String? taskId,
    int? skips,
    int? earlyCompletions,
    int? lateCompletions,
  }) {
    return TaskBehavior(
      taskId: taskId ?? this.taskId,
      skips: skips ?? this.skips,
      earlyCompletions: earlyCompletions ?? this.earlyCompletions,
      lateCompletions: lateCompletions ?? this.lateCompletions,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskId': taskId,
      'skips': skips,
      'earlyCompletions': earlyCompletions,
      'lateCompletions': lateCompletions,
    };
  }

  factory TaskBehavior.fromMap(Map<String, dynamic> map) {
    return TaskBehavior(
      taskId: map['taskId'] as String? ?? '',
      skips: map['skips'] as int? ?? 0,
      earlyCompletions: map['earlyCompletions'] as int? ?? 0,
      lateCompletions: map['lateCompletions'] as int? ?? 0,
    );
  }
}
