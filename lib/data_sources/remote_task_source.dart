import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class RemoteTaskSource {
  RemoteTaskSource({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

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

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _safeFirestore!.collection('tasks');

  Future<void> uploadTask(Task task) async {
    if (_safeFirestore == null) {
      throw StateError('Firestore unavailable');
    }

    await _tasks.doc(task.id).set(task.toMap(), SetOptions(merge: true));
  }

  Future<List<Task>> fetchTasks() async {
    if (_safeFirestore == null) {
      throw StateError('Firestore unavailable');
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _tasks.get();
    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return Task.fromMap(data);
    }).toList();
  }
}
