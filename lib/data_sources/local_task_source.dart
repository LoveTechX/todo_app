import 'package:hive/hive.dart';

import '../models/task.dart';

class LocalTaskSource {
  final Box<dynamic> _box = Hive.box('tasks');

  Future<List<Task>> getTasks() async {
    return _box.values
        .map(
          (dynamic rawTask) =>
              Task.fromMap(Map<String, dynamic>.from(rawTask as Map)),
        )
        .toList();
  }

  Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _box.delete(taskId);
  }

  Future<List<Task>> getUnsyncedTasks() async {
    final List<Task> all = await getTasks();
    return all.where((Task task) => !task.isSynced).toList();
  }

  Future<void> markAsSynced(String taskId) async {
    final dynamic raw = _box.get(taskId);
    if (raw is! Map) {
      return;
    }

    final Task task = Task.fromMap(Map<String, dynamic>.from(raw));
    final Task synced = task.copyWith(
      isSynced: true,
      updatedAt: DateTime.now(),
    );
    await _box.put(taskId, synced.toMap());
  }
}
