class FocusRoom {
  const FocusRoom({
    required this.id,
    required this.name,
    required this.participants,
  });

  final String id;
  final String name;
  final List<String> participants;

  factory FocusRoom.fromMap(String id, Map<String, dynamic> map) {
    final List<dynamic> rawParticipants =
        map['participants'] as List<dynamic>? ?? <dynamic>[];

    return FocusRoom(
      id: id,
      name: map['name'] as String? ?? 'Focus Room',
      participants: rawParticipants.map((dynamic item) => '$item').toList(),
    );
  }
}
