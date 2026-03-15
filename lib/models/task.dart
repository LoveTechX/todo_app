enum CognitiveLoad { deep, medium, light }

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  int get weight {
    switch (this) {
      case TaskPriority.low:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.high:
        return 3;
    }
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.cognitiveLoad = CognitiveLoad.medium,
    this.deadline,
    this.estimatedDurationMinutes,
    this.isSynced = false,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final TaskPriority priority;
  final CognitiveLoad cognitiveLoad;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deadline;
  final int? estimatedDurationMinutes;
  final bool isSynced;
  final bool isCompleted;

  Task copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    CognitiveLoad? cognitiveLoad,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    int? estimatedDurationMinutes,
    bool? isSynced,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      cognitiveLoad: cognitiveLoad ?? this.cognitiveLoad,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isSynced: isSynced ?? this.isSynced,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'priority': priority.name,
      'cognitiveLoad': cognitiveLoad.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isSynced': isSynced,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final String priorityName =
        map['priority'] as String? ?? TaskPriority.medium.name;
    final TaskPriority parsedPriority = TaskPriority.values.firstWhere(
      (TaskPriority value) => value.name == priorityName,
      orElse: () => TaskPriority.medium,
    );

    final String createdAtRaw = map['createdAt'] as String? ?? '';
    final String updatedAtRaw = map['updatedAt'] as String? ?? createdAtRaw;
    final String? deadlineRaw = map['deadline'] as String?;
    final dynamic estimatedDurationRaw = map['estimatedDurationMinutes'];

    final String cognitiveLoadName =
        map['cognitiveLoad'] as String? ?? CognitiveLoad.medium.name;
    final CognitiveLoad parsedCognitiveLoad = CognitiveLoad.values.firstWhere(
      (CognitiveLoad v) => v.name == cognitiveLoadName,
      orElse: () => CognitiveLoad.medium,
    );

    return Task(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      priority: parsedPriority,
      cognitiveLoad: parsedCognitiveLoad,
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(updatedAtRaw) ??
          DateTime.tryParse(createdAtRaw) ??
          DateTime.now(),
      deadline: deadlineRaw != null ? DateTime.tryParse(deadlineRaw) : null,
      estimatedDurationMinutes: estimatedDurationRaw is int
          ? estimatedDurationRaw
          : int.tryParse('${estimatedDurationRaw ?? ''}'),
      isSynced: map['isSynced'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
