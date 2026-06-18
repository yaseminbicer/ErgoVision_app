class AIAnalysisResult {
  final double postureScore;
  final bool isGoodPosture;
  final double torsoAngle;
  final double neckAngle;
  final double shoulderAngle;

  const AIAnalysisResult({
    required this.postureScore,
    required this.isGoodPosture,
    required this.torsoAngle,
    required this.neckAngle,
    required this.shoulderAngle,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      postureScore: (json['posture_score'] as num).toDouble(),
      isGoodPosture: json['is_good_posture'] as bool,
      torsoAngle: (json['torso_angle'] as num).toDouble(),
      neckAngle: (json['neck_angle'] as num).toDouble(),
      shoulderAngle: (json['shoulder_angle'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posture_score': postureScore,
      'is_good_posture': isGoodPosture,
      'torso_angle': torsoAngle,
      'neck_angle': neckAngle,
      'shoulder_angle': shoulderAngle,
    };
  }
}
