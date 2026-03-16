import '../models/task.dart';
import '../data_sources/local_task_source.dart';
import '../data_sources/remote_task_source.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
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
    required this.authService,
  });

  final LocalTaskSource localSource;
  final RemoteTaskSource remoteSource;
  final SyncService syncService;
  final AuthService authService;
  final ErrorService _errorService = ErrorService.instance;

  @override
  Future<List<Task>> getTasks() async {
    try {
      final String? userId = authService.getCurrentUser()?.uid;
      if (userId == null || userId.isEmpty) {
        return <Task>[];
      }

      final List<Task> localTasks = await localSource.getTasksForUser(userId);

      try {
        final List<Task> remoteTasks = await remoteSource.fetchTasks(userId);
        final List<Task> merged = _mergeTasks(
          local: localTasks,
          remote: remoteTasks,
          userId: userId,
        );
        await localSource.upsertTasks(merged);
        return merged;
      } catch (error, stackTrace) {
        _errorService.handleException(
          error,
          stackTrace,
          context: 'TaskRepository.getTasks.remoteFallback',
          operation: 'load cloud tasks',
          isNetworkRelated: true,
        );
        return localTasks;
      }
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'TaskRepository.getTasks',
        operation: 'load your tasks',
      );
      rethrow;
    }
  }

  @override
  Future<void> addTask(Task task) async {
    try {
      final String? userId = authService.getCurrentUser()?.uid;
      final Task normalized = task.copyWith(
        userId: task.userId.isEmpty ? (userId ?? task.userId) : task.userId,
      );
      await localSource.addTask(normalized);
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'TaskRepository.addTask',
        operation: 'create the task',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      final String? userId = authService.getCurrentUser()?.uid;
      final Task normalized = task.copyWith(
        userId: task.userId.isEmpty ? (userId ?? task.userId) : task.userId,
      );
      await localSource.updateTask(normalized);
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'TaskRepository.updateTask',
        operation: 'update the task',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await localSource.deleteTask(taskId);
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'TaskRepository.deleteTask',
        operation: 'delete the task',
      );
      rethrow;
    }
  }

  @override
  Future<void> syncTasks() async {
    try {
      await syncService.syncTasks();
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'TaskRepository.syncTasks',
        operation: 'sync your tasks',
        isNetworkRelated: true,
      );
      rethrow;
    }
  }

  List<Task> _mergeTasks({
    required List<Task> local,
    required List<Task> remote,
    required String userId,
  }) {
    final Map<String, Task> mergedById = <String, Task>{};

    for (final Task task in local) {
      final Task normalized = task.userId.isEmpty
          ? task.copyWith(userId: userId)
          : task;
      mergedById[normalized.id] = normalized;
    }

    for (final Task remoteTask in remote) {
      final Task normalized = remoteTask.copyWith(
        userId: remoteTask.userId.isEmpty ? userId : remoteTask.userId,
        isSynced: true,
      );

      final Task? existing = mergedById[normalized.id];
      if (existing == null ||
          normalized.updatedAt.isAfter(existing.updatedAt)) {
        mergedById[normalized.id] = normalized;
      }
    }

    return mergedById.values.toList(growable: true);
  }
}
