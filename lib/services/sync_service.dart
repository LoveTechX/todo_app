import '../data_sources/local_task_source.dart';
import '../data_sources/remote_task_source.dart';
import '../models/task.dart';

class SyncService {
  SyncService({
    required LocalTaskSource localTaskSource,
    required RemoteTaskSource remoteTaskSource,
  }) : _localTaskSource = localTaskSource,
       _remoteTaskSource = remoteTaskSource;

  final LocalTaskSource _localTaskSource;
  final RemoteTaskSource _remoteTaskSource;

  Future<void> syncTasks() async {
    final List<Task> unsynced = await _localTaskSource.getUnsyncedTasks();

    for (final Task task in unsynced) {
      try {
        await _remoteTaskSource.uploadTask(task);
        await _localTaskSource.markAsSynced(task.id);
      } catch (_) {
        // Keep local state untouched when offline or remote is unavailable.
      }
    }
  }
}
