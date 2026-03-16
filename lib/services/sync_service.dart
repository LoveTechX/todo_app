import 'package:flutter/foundation.dart';

import '../data_sources/local_task_source.dart';
import '../data_sources/remote_task_source.dart';
import '../models/task.dart';
import 'auth_service.dart';

enum SyncStatus { synced, syncing, offline }

class SyncService extends ChangeNotifier {
  SyncService({
    required LocalTaskSource localTaskSource,
    required RemoteTaskSource remoteTaskSource,
    required AuthService authService,
  }) : _localTaskSource = localTaskSource,
       _remoteTaskSource = remoteTaskSource,
       _authService = authService;

  final LocalTaskSource _localTaskSource;
  final RemoteTaskSource _remoteTaskSource;
  final AuthService _authService;
  SyncStatus _status = SyncStatus.synced;

  SyncStatus get status => _status;

  void _setStatus(SyncStatus value) {
    if (_status == value) {
      return;
    }
    _status = value;
    notifyListeners();
  }

  Future<void> syncTasks() async {
    _setStatus(SyncStatus.syncing);

    try {
      final String? userId = _authService.getCurrentUser()?.uid;
      if (userId == null || userId.isEmpty) {
        _setStatus(SyncStatus.synced);
        return;
      }

      final List<Task> unsynced = await _localTaskSource
          .getUnsyncedTasksForUser(userId);

      bool hadSyncFailures = false;

      await Future.wait(
        unsynced.map((Task task) async {
          try {
            final Task normalized = task.userId.isEmpty
                ? task.copyWith(userId: userId)
                : task;
            if (normalized.userId != task.userId) {
              await _localTaskSource.updateTask(normalized);
            }

            await _remoteTaskSource.uploadTask(normalized);
            await _localTaskSource.markAsSynced(normalized.id);
          } catch (error, stackTrace) {
            // Keep local state untouched when offline or remote is unavailable.
            hadSyncFailures = true;
            debugPrint('SyncService sync failed for task ${task.id}: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }),
      );

      final List<Task> remoteTasks = await _remoteTaskSource.fetchTasks(userId);
      await _localTaskSource.upsertTasks(
        remoteTasks.map((Task task) => task.copyWith(isSynced: true)).toList(),
      );

      _setStatus(hadSyncFailures ? SyncStatus.offline : SyncStatus.synced);
    } catch (error, stackTrace) {
      _setStatus(SyncStatus.offline);
      debugPrint('SyncService.syncTasks failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
