class SleepSession {
  final int? id;
  final DateTime startTimestamp;
  final DateTime endTimestamp;
  final int? qualityRating; // 1 to 5
  final String? notes;
  final List<String> tags; // e.g. ['Caffeine', 'Workout', 'Reading', 'Meditation']
  final String source; // 'timer' | 'manual'
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepSession({
    this.id,
    required this.startTimestamp,
    required this.endTimestamp,
    this.qualityRating,
    this.notes,
    this.tags = const [],
    this.source = 'manual',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Duration in minutes
  int get durationInMinutes => endTimestamp.difference(startTimestamp).inMinutes;

  /// Duration as a Duration object
  Duration get duration => endTimestamp.difference(startTimestamp);

  /// Checks if session started on one date and ended on another
  bool get isOvernight {
    return startTimestamp.day != endTimestamp.day ||
        startTimestamp.month != endTimestamp.month ||
        startTimestamp.year != endTimestamp.year;
  }

  /// Copies instance with modified values
  SleepSession copyWith({
    int? id,
    DateTime? startTimestamp,
    DateTime? endTimestamp,
    int? qualityRating,
    String? notes,
    List<String>? tags,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepSession(
      id: id ?? this.id,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      qualityRating: qualityRating ?? this.qualityRating,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'start_timestamp': startTimestamp.millisecondsSinceEpoch,
      'end_timestamp': endTimestamp.millisecondsSinceEpoch,
      'quality_rating': qualityRating,
      'notes': notes,
      'tags': tags.join(','),
      'source': source,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Factory from SQLite Map
  factory SleepSession.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'] as String?;
    final parsedTags = rawTags != null
        ? rawTags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    return SleepSession(
      id: map['id'] as int?,
      startTimestamp: DateTime.fromMillisecondsSinceEpoch(map['start_timestamp'] as int),
      endTimestamp: DateTime.fromMillisecondsSinceEpoch(map['end_timestamp'] as int),
      qualityRating: map['quality_rating'] as int?,
      notes: map['notes'] as String?,
      tags: parsedTags,
      source: (map['source'] as String?) ?? 'manual',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert to JSON for Export
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'startTimestamp': startTimestamp.toIso8601String(),
      'endTimestamp': endTimestamp.toIso8601String(),
      'durationMinutes': durationInMinutes,
      'qualityRating': qualityRating,
      'notes': notes,
      'tags': tags,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Overlap checking with another session
  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    return startTimestamp.isBefore(otherEnd) && otherStart.isBefore(endTimestamp);
  }
}
