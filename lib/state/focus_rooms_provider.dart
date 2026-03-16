import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/focus_room.dart';
import '../services/focus_room_service.dart';

class FocusRoomsProvider extends ChangeNotifier {
  FocusRoomsProvider({required FocusRoomService focusRoomService})
    : _focusRoomService = focusRoomService {
    _roomsSubscription = _focusRoomService.roomsStream.listen((
      List<FocusRoom> rooms,
    ) {
      _rooms = rooms;
      _isLoading = false;
      notifyListeners();
    });

    _rooms = _focusRoomService.getActiveRooms();
    _isLoading = false;
  }

  final FocusRoomService _focusRoomService;

  List<FocusRoom> _rooms = <FocusRoom>[];
  StreamSubscription<List<FocusRoom>>? _roomsSubscription;
  String? _joinedRoomId;
  bool _isLoading = true;
  String? _errorMessage;

  List<FocusRoom> get rooms => List<FocusRoom>.unmodifiable(_rooms);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get joinedRoomId => _joinedRoomId;

  FocusRoom? get joinedRoom {
    final String? joinedId = _joinedRoomId;
    if (joinedId == null) {
      return null;
    }

    return _rooms.cast<FocusRoom?>().firstWhere(
      (FocusRoom? room) => room?.id == joinedId,
      orElse: () => null,
    );
  }

  bool isUserInRoom(String roomId) {
    return _joinedRoomId == roomId;
  }

  Future<void> refreshRooms() async {
    _rooms = _focusRoomService.getActiveRooms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createRoom({
    required String name,
    int durationMinutes = 25,
  }) async {
    _errorMessage = null;
    try {
      final FocusRoom room = await _focusRoomService.createRoom(
        name: name,
        durationMinutes: durationMinutes,
      );
      _joinedRoomId = room.id;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Unable to create room.';
      notifyListeners();
    }
  }

  Future<void> joinRoom(String roomId) async {
    _errorMessage = null;
    try {
      if (_joinedRoomId != null && _joinedRoomId != roomId) {
        await _focusRoomService.leaveRoom(_joinedRoomId!);
      }

      await _focusRoomService.joinRoom(roomId);
      _joinedRoomId = roomId;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Unable to join room.';
      notifyListeners();
    }
  }

  Future<void> leaveRoom(String roomId) async {
    _errorMessage = null;
    try {
      await _focusRoomService.leaveRoom(roomId);
      if (_joinedRoomId == roomId) {
        _joinedRoomId = null;
      }
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Unable to leave room.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final String? joinedId = _joinedRoomId;
    if (joinedId != null) {
      unawaited(_focusRoomService.leaveRoom(joinedId));
    }
    _roomsSubscription?.cancel();
    super.dispose();
  }
}
