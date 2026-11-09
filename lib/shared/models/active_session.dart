class ActiveSession {
  final int id;
  final DateTime startTimestamp;
  final String? notes;
  final DateTime createdAt;

  ActiveSession({
    this.id = 1,
    required this.startTimestamp,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Elapsed duration calculated strictly from the stored startTimestamp
  Duration get elapsedDuration => DateTime.now().difference(startTimestamp);

  int get elapsedMinutes => elapsedDuration.inMinutes;

  /// Check if the session appears abandoned (e.g. running for > 24 hours)
  bool get isStale => elapsedDuration.inHours >= 24;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'start_timestamp': startTimestamp.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ActiveSession.fromMap(Map<String, dynamic> map) {
    return ActiveSession(
      id: (map['id'] as int?) ?? 1,
      startTimestamp: DateTime.fromMillisecondsSinceEpoch(map['start_timestamp'] as int),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

