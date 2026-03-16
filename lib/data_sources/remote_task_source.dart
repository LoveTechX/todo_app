import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';
import '../services/error_service.dart';

class RemoteTaskSource {
  RemoteTaskSource({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final ErrorService _errorService = ErrorService.instance;

  FirebaseFirestore? get _safeFirestore {
    if (_firestore != null) {
      return _firestore;
    }

    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>> _tasksForUser(
    FirebaseFirestore firestore,
    String userId,
  ) => firestore.collection('users').doc(userId).collection('tasks');

  Future<void> uploadTask(Task task) async {
    try {
      final FirebaseFirestore? firestore = _safeFirestore;
      if (firestore == null) {
        throw StateError('Firestore unavailable');
      }

      if (task.userId.isEmpty) {
        throw StateError('Task userId is required for remote sync');
      }

      await _tasksForUser(
        firestore,
        task.userId,
      ).doc(task.id).set(task.toMap(), SetOptions(merge: true));
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'RemoteTaskSource.uploadTask',
        operation: 'sync your tasks',
        isNetworkRelated: true,
      );
      rethrow;
    }
  }

  Future<List<Task>> fetchTasks(String userId) async {
    try {
      final FirebaseFirestore? firestore = _safeFirestore;
      if (firestore == null) {
        throw StateError('Firestore unavailable');
      }

      if (userId.isEmpty) {
        return <Task>[];
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await _tasksForUser(
        firestore,
        userId,
      ).get();
      return snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = data['id'] ?? doc.id;
        data['userId'] = data['userId'] ?? userId;
        return Task.fromMap(data);
      }).toList();
    } catch (error, stackTrace) {
      _errorService.handleException(
        error,
        stackTrace,
        context: 'RemoteTaskSource.fetchTasks',
        operation: 'load synced tasks',
        isNetworkRelated: true,
      );
      rethrow;
    }
  }
}
