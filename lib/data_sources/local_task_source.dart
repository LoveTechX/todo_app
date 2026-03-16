import 'package:hive/hive.dart';

import '../models/task.dart';
import '../services/error_service.dart';

class LocalTaskSource {
  final ErrorService _errorService = ErrorService.instance;
  final Box<Map> _box = Hive.box<Map>('tasks');

  Future<List<Task>> getTasks() async {
    try {
      return _box.values
          .map(
            (Map rawTask) => Task.fromMap(Map<String, dynamic>.from(rawTask)),
          )
          .toList(growable: true);
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.getTasks',
        operation: 'load your tasks',
      );
      return <Task>[];
    }
  }

  Future<List<Task>> getTasksForUser(String userId) async {
    final List<Task> all = await getTasks();
    return all
        .where((Task task) => task.userId == userId || task.userId.isEmpty)
        .toList(growable: true);
  }

  Future<void> addTask(Task task) async {
    try {
      await _box.put(task.id, task.toMap());
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.addTask',
        operation: 'save a task',
      );
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _box.put(task.id, task.toMap());
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.updateTask',
        operation: 'update a task',
      );
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _box.delete(taskId);
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.deleteTask',
        operation: 'delete a task',
      );
      rethrow;
    }
  }

  Future<List<Task>> getUnsyncedTasks() async {
    try {
      final List<Task> all = await getTasks();
      return all.where((Task task) => !task.isSynced).toList();
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.getUnsyncedTasks',
        operation: 'check sync state',
      );
      return <Task>[];
    }
  }

  Future<List<Task>> getUnsyncedTasksForUser(String userId) async {
    try {
      final List<Task> all = await getTasksForUser(userId);
      return all.where((Task task) => !task.isSynced).toList();
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.getUnsyncedTasksForUser',
        operation: 'check sync state',
      );
      return <Task>[];
    }
  }

  Future<void> upsertTasks(List<Task> tasks) async {
    try {
      for (final Task task in tasks) {
        await _box.put(task.id, task.toMap());
      }
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.upsertTasks',
        operation: 'save synchronized tasks',
      );
      rethrow;
    }
  }

  Future<void> markAsSynced(String taskId) async {
    try {
      final Map? raw = _box.get(taskId);
      if (raw == null) {
        return;
      }

      final Task task = Task.fromMap(Map<String, dynamic>.from(raw));
      final Task synced = task.copyWith(
        isSynced: true,
        updatedAt: DateTime.now(),
      );
      await _box.put(taskId, synced.toMap());
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'LocalTaskSource.markAsSynced',
        operation: 'mark a task as synced',
      );
      rethrow;
    }
  }
}
