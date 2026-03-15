import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/focus_room.dart';

class FocusRoomService {
  FocusRoomService({FirebaseFirestore? firestore, String? userId})
    : _firestore = firestore,
      _userId = userId ?? const Uuid().v4();

  final FirebaseFirestore? _firestore;
  final String _userId;

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

  CollectionReference<Map<String, dynamic>>? get _roomsCollection {
    final FirebaseFirestore? firestore = _safeFirestore;
    if (firestore == null) {
      return null;
    }

    return firestore.collection('focus_rooms');
  }

  Stream<List<FocusRoom>> getRooms() {
    final CollectionReference<Map<String, dynamic>>? rooms = _roomsCollection;
    if (rooms == null) {
      return Stream<List<FocusRoom>>.value(<FocusRoom>[]);
    }

    return rooms.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                FocusRoom.fromMap(doc.id, doc.data()),
          )
          .toList();
    });
  }

  Future<void> joinRoom(String roomId) async {
    final CollectionReference<Map<String, dynamic>>? rooms = _roomsCollection;
    if (rooms == null) {
      return;
    }

    await rooms.doc(roomId).set(<String, dynamic>{
      'participants': FieldValue.arrayUnion(<String>[_userId]),
    }, SetOptions(merge: true));
  }

  Future<void> leaveRoom(String roomId) async {
    final CollectionReference<Map<String, dynamic>>? rooms = _roomsCollection;
    if (rooms == null) {
      return;
    }

    await rooms.doc(roomId).set(<String, dynamic>{
      'participants': FieldValue.arrayRemove(<String>[_userId]),
    }, SetOptions(merge: true));
  }
}
