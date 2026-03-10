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
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final TaskPriority priority;
  final DateTime createdAt;
  final bool isCompleted;

  Task copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
