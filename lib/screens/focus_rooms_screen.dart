import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/focus_room.dart';
import '../services/focus_room_service.dart';
import '../state/todo_provider.dart';

class FocusRoomsScreen extends StatefulWidget {
  const FocusRoomsScreen({super.key});

  @override
  State<FocusRoomsScreen> createState() => _FocusRoomsScreenState();
}

class _FocusRoomsScreenState extends State<FocusRoomsScreen> {
  final FocusRoomService _focusRoomService = FocusRoomService();
  String? _joinedRoomId;

  @override
  void dispose() {
    final String? roomId = _joinedRoomId;
    if (roomId != null) {
      _focusRoomService.leaveRoom(roomId);
    }
    super.dispose();
  }

  Future<void> _joinRoom(FocusRoom room) async {
    if (_joinedRoomId != null && _joinedRoomId != room.id) {
      await _focusRoomService.leaveRoom(_joinedRoomId!);
    }

    await _focusRoomService.joinRoom(room.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _joinedRoomId = room.id;
    });

    context.read<TodoProvider>().startFocusTimer();
  }

  Future<void> _leaveRoom(FocusRoom room) async {
    await _focusRoomService.leaveRoom(room.id);
    if (!mounted) {
      return;
    }

    setState(() {
      if (_joinedRoomId == room.id) {
        _joinedRoomId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Rooms')),
      body: StreamBuilder<List<FocusRoom>>(
        stream: _focusRoomService.getRooms(),
        builder:
            (BuildContext context, AsyncSnapshot<List<FocusRoom>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<FocusRoom> rooms = snapshot.data ?? <FocusRoom>[];
              if (rooms.isEmpty) {
                return const Center(
                  child: Text('No active focus rooms right now.'),
                );
              }

              final FocusRoom? joinedRoom = _joinedRoomId == null
                  ? null
                  : rooms.cast<FocusRoom?>().firstWhere(
                      (FocusRoom? room) => room?.id == _joinedRoomId,
                      orElse: () => null,
                    );

              return Column(
                children: <Widget>[
                  if (joinedRoom != null)
                    Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Active Participants',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: joinedRoom.participants
                                  .map(
                                    (String participant) =>
                                        Chip(label: Text(participant)),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (BuildContext context, int index) {
                        final FocusRoom room = rooms[index];
                        final bool isJoined = room.id == _joinedRoomId;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(room.name),
                            subtitle: Text(
                              '${room.participants.length} participants',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  isJoined ? _leaveRoom(room) : _joinRoom(room),
                              child: Text(isJoined ? 'Leave' : 'Join'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }
}
