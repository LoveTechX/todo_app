enum FocusEventType {
  focusSessionCompleted,
  taskCompletedOnTime,
  taskSkipped,
  focusSessionStoppedEarly,
}

class FocusEvent {
  const FocusEvent({
    required this.type,
    required this.timestamp,
    required this.scoreImpact,
  });

  final FocusEventType type;
  final DateTime timestamp;
  final int scoreImpact;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'scoreImpact': scoreImpact,
    };
  }

  factory FocusEvent.fromMap(Map<String, dynamic> map) {
    final String typeName =
        map['type'] as String? ?? FocusEventType.focusSessionCompleted.name;

    final FocusEventType parsedType = FocusEventType.values.firstWhere(
      (FocusEventType value) => value.name == typeName,
      orElse: () => FocusEventType.focusSessionCompleted,
    );

    return FocusEvent(
      type: parsedType,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      scoreImpact: map['scoreImpact'] as int? ?? 0,
    );
  }
}
