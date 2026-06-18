/// AI modelinin bir kamera frame'ini analiz etmesi sonucunda döndürdüğü veriyi temsil eder.
/// AIService tarafından üretilir, PostureAnalysisService tarafından tüketilir.
class AIAnalysisResult {
  final double postureScore;
  final bool isGoodPosture;
  final double torsoAngle;
  final double neckAngle;
  final double shoulderAngle;

  AIAnalysisResult({
    required this.postureScore,
    required this.isGoodPosture,
    required this.torsoAngle,
    required this.neckAngle,
    required this.shoulderAngle,
  });

  /// AI API'sinin döndürdüğü JSON'u Dart nesnesine dönüştürür.
  /// Beklenen format:
  /// {
  ///   "posture_score": 72.5,
  ///   "is_good_posture": true,
  ///   "torso_angle": 165.0,
  ///   "neck_angle": 158.0,
  ///   "shoulder_angle": 162.0
  /// }
  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      postureScore: (json['posture_score'] as num).toDouble(),
      isGoodPosture: json['is_good_posture'] as bool,
      torsoAngle: (json['torso_angle'] as num).toDouble(),
      neckAngle: (json['neck_angle'] as num).toDouble(),
      shoulderAngle: (json['shoulder_angle'] as num).toDouble(),
    );
  }
}
