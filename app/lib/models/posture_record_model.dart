class PostureRecordModel {
  final String id;
  final String sessionId;
  final String userId;
  final double postureScore;
  final bool isGoodPosture;
  final double torsoAngle;
  final double neckAngle;
  final double shoulderAngle;
  final DateTime recordedAt;

  PostureRecordModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.postureScore,
    required this.isGoodPosture,
    required this.torsoAngle,
    required this.neckAngle,
    required this.shoulderAngle,
    required this.recordedAt,
  });

  factory PostureRecordModel.fromMap(Map<String, dynamic> map) {
    return PostureRecordModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      userId: map['user_id'] as String,
      postureScore: (map['posture_score'] as num).toDouble(),
      isGoodPosture: map['is_good_posture'] as bool,
      torsoAngle: (map['torso_angle'] as num).toDouble(),
      neckAngle: (map['neck_angle'] as num).toDouble(),
      shoulderAngle: (map['shoulder_angle'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }
}

class PostureSummary {
  final int totalRecords;
  final int goodPostureCount;
  final int badPostureCount;
  final double goodPosturePercentage;
  final double averageScore;

  PostureSummary({
    required this.totalRecords,
    required this.goodPostureCount,
    required this.badPostureCount,
    required this.goodPosturePercentage,
    required this.averageScore,
  });
}
