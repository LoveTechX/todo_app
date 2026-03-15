import '../models/task.dart';

class TaskService {
  final List<Task> _tasks = <Task>[];

  Future<List<Task>> fetchTasks() async {
    return List<Task>.from(_tasks);
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
  }

  Future<void> updateTask(Task task) async {
    final int index = _tasks.indexWhere((Task item) => item.id == task.id);
    if (index == -1) {
      return;
    }

    _tasks[index] = task;
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((Task task) => task.id == id);
  }
}
