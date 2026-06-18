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
      id: map['id'],
      userId: map['user_id'],
      startedAt: DateTime.parse(map['started_at']),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at']) : null,
      durationSeconds: map['duration_seconds'],
    );
  }

  bool get isActive => endedAt == null;

  String get formattedDuration {
    if (durationSeconds == null) return '-';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes}dk ${seconds}sn';
  }
}
