import '../models/task.dart';
import '../data_sources/local_task_source.dart';
import '../data_sources/remote_task_source.dart';
import '../services/sync_service.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();

  Future<void> addTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> deleteTask(String taskId);

  Future<void> syncTasks();
}

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required this.localSource,
    required this.remoteSource,
    required this.syncService,
  });

  final LocalTaskSource localSource;
  final RemoteTaskSource remoteSource;
  final SyncService syncService;

  @override
  Future<List<Task>> getTasks() {
    return localSource.getTasks();
  }

  @override
  Future<void> addTask(Task task) {
    return localSource.addTask(task);
  }

  @override
  Future<void> updateTask(Task task) {
    return localSource.updateTask(task);
  }

  @override
  Future<void> deleteTask(String taskId) {
    return localSource.deleteTask(taskId);
  }

  @override
  Future<void> syncTasks() {
    return syncService.syncTasks();
  }
}
