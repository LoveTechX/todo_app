import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> getTasks() {
    return _repository.getTasks();
  }

  Future<void> addTask(Task task) {
    return _repository.addTask(task);
  }

  Future<void> updateTask(Task task) {
    return _repository.updateTask(task);
  }

  Future<void> deleteTask(String taskId) {
    return _repository.deleteTask(taskId);
  }

  Future<void> syncTasks() {
    return _repository.syncTasks();
  }
}
