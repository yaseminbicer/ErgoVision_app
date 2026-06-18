class SessionModel {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  SessionModel({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      durationSeconds: map['duration_seconds'] as int?,
    );
  }

  bool get isActive => endedAt == null;
}
