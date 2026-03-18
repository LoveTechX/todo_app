import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/focus_room.dart';
import '../state/focus_provider.dart';
import '../state/focus_rooms_provider.dart';

class FocusRoomsScreen extends StatefulWidget {
  const FocusRoomsScreen({super.key});

  @override
  State<FocusRoomsScreen> createState() => _FocusRoomsScreenState();
}

class _FocusRoomsScreenState extends State<FocusRoomsScreen> {
  static const String _focusRoomsHeroTag = 'focus-rooms-screen-hero';

  final TextEditingController _nameController = TextEditingController();

  Future<void> _joinRoom(FocusRoom room) async {
    await context.read<FocusRoomsProvider>().joinRoom(room.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined ${room.name}')),
    );
    context.read<FocusProvider>().startFocusTimer();
  }

  Future<void> _leaveRoom(FocusRoom room) async {
    await context.read<FocusRoomsProvider>().leaveRoom(room.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Left ${room.name}')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showCreateRoomDialog(BuildContext context) async {
    _nameController.clear();
    final int? duration = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController durationController = TextEditingController(
          text: '25',
        );
        return AlertDialog(
          title: const Text('Create Focus Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Room name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int parsedDuration =
                    int.tryParse(durationController.text.trim()) ?? 25;
                Navigator.of(dialogContext).pop(parsedDuration);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || duration == null) {
      return;
    }

    await context.read<FocusRoomsProvider>().createRoom(
      name: _nameController.text,
      durationMinutes: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FocusRoomsProvider roomsProvider = context
        .watch<FocusRoomsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Hero(tag: _focusRoomsHeroTag, child: Icon(Icons.groups)),
            SizedBox(width: 8),
            Text('Focus Rooms'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Create room',
            onPressed: () => _showCreateRoomDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          if (roomsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<FocusRoom> rooms = roomsProvider.rooms;
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No active focus rooms right now.'),
            );
          }

          final FocusRoom? joinedRoom = roomsProvider.joinedRoom;

          return Column(
            children: <Widget>[
              if (joinedRoom != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'You are in ${joinedRoom.name}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: 1,
                            child: Text(
                              '🟢 ${joinedRoom.activeUsers.length} focusing now • ${joinedRoom.durationMinutes} min',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (roomsProvider.errorMessage != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      roomsProvider.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (BuildContext context, int index) {
                    final FocusRoom room = rooms[index];
                    final bool isJoined = roomsProvider.isUserInRoom(room.id);
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(
                        milliseconds: 220 + (index * 30).clamp(0, 300),
                      ),
                      curve: Curves.easeOutCubic,
                      builder:
                          (BuildContext context, double value, Widget? child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 14),
                                child: child,
                              ),
                            );
                          },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isJoined ? 0.12 : 0.06,
                              ),
                              blurRadius: isJoined ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(room.name),
                          subtitle: Text(
                            '🟢 ${room.activeUsers.length} focusing now • ${room.durationMinutes} min',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                isJoined ? _leaveRoom(room) : _joinRoom(room),
                            child: Text(isJoined ? 'Leave' : 'Join'),
                          ),
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
