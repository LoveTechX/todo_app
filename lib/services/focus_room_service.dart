import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/focus_room.dart';

class FocusRoomService {
  FocusRoomService({String? userId}) : _userId = userId ?? const Uuid().v4() {
    _seedDefaultRooms();
    _emitRooms();
  }

  final String _userId;
  final Uuid _uuid = const Uuid();
  final Map<String, FocusRoom> _roomsById = <String, FocusRoom>{};
  final StreamController<List<FocusRoom>> _roomsController =
      StreamController<List<FocusRoom>>.broadcast();

  String get currentUserId => _userId;
  Stream<List<FocusRoom>> get roomsStream => _roomsController.stream;

  Future<FocusRoom> createRoom({
    required String name,
    int durationMinutes = 25,
  }) async {
    final DateTime now = DateTime.now();
    final FocusRoom room = FocusRoom(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Focus Room' : name.trim(),
      activeUsers: <String>[_userId],
      startTime: now,
      durationMinutes: durationMinutes,
    );

    _roomsById[room.id] = room;
    _emitRooms();
    return room;
  }

  Future<void> joinRoom(String roomId) async {
    final FocusRoom? room = _roomsById[roomId];
    if (room == null) {
      return;
    }

    if (room.activeUsers.contains(_userId)) {
      return;
    }

    _roomsById[roomId] = room.copyWith(
      activeUsers: <String>[...room.activeUsers, _userId],
    );
    _emitRooms();
  }

  Future<void> leaveRoom(String roomId) async {
    final FocusRoom? room = _roomsById[roomId];
    if (room == null) {
      return;
    }

    final List<String> updatedUsers = room.activeUsers
        .where((String id) => id != _userId)
        .toList();

    if (updatedUsers.isEmpty) {
      _roomsById.remove(roomId);
    } else {
      _roomsById[roomId] = room.copyWith(activeUsers: updatedUsers);
    }

    _emitRooms();
  }

  List<FocusRoom> getActiveRooms() {
    final List<FocusRoom> rooms = _roomsById.values.toList()
      ..sort((FocusRoom a, FocusRoom b) => b.startTime.compareTo(a.startTime));
    return List<FocusRoom>.unmodifiable(rooms);
  }

  void dispose() {
    _roomsController.close();
  }

  void _emitRooms() {
    if (_roomsController.isClosed) {
      return;
    }

    _roomsController.add(getActiveRooms());
  }

  void _seedDefaultRooms() {
    final DateTime now = DateTime.now();
    final List<FocusRoom> seedRooms = <FocusRoom>[
      FocusRoom(
        id: _uuid.v4(),
        name: 'Morning Deep Work',
        activeUsers: <String>['designer_01', 'dev_02'],
        startTime: now.subtract(const Duration(minutes: 12)),
        durationMinutes: 45,
      ),
      FocusRoom(
        id: _uuid.v4(),
        name: 'Inbox Zero Sprint',
        activeUsers: <String>['pm_07'],
        startTime: now.subtract(const Duration(minutes: 5)),
        durationMinutes: 25,
      ),
    ];

    for (final FocusRoom room in seedRooms) {
      _roomsById[room.id] = room;
    }
  }
}
