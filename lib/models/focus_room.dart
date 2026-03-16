class FocusRoom {
  const FocusRoom({
    required this.id,
    required this.name,
    required this.activeUsers,
    required this.startTime,
    required this.durationMinutes,
  });

  final String id;
  final String name;
  final List<String> activeUsers;
  final DateTime startTime;
  final int durationMinutes;

  FocusRoom copyWith({
    String? id,
    String? name,
    List<String>? activeUsers,
    DateTime? startTime,
    int? durationMinutes,
  }) {
    return FocusRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      activeUsers: activeUsers ?? this.activeUsers,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'activeUsers': activeUsers,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory FocusRoom.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawUsers =
        map['activeUsers'] as List<dynamic>? ??
        map['participants'] as List<dynamic>? ??
        <dynamic>[];

    return FocusRoom(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Focus Room',
      activeUsers: rawUsers.map((dynamic item) => '$item').toList(),
      startTime:
          DateTime.tryParse(map['startTime'] as String? ?? '') ??
          DateTime.now(),
      durationMinutes: map['durationMinutes'] as int? ?? 25,
    );
  }
}
