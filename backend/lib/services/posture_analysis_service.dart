import 'dart:typed_data';
import '../models/ai_analysis_result.dart';
import '../models/posture_record_model.dart';
import '../models/exercise_model.dart';
import 'ai_service.dart';
import 'posture_service.dart';
import 'exercise_service.dart';

class PostureAnalysisService {
  /// Frame'i AI'ya gönderir, sonucu Supabase'e kaydeder.
  static Future<PostureRecordModel> analyzeAndSave({
    required Uint8List imageBytes,
    required String sessionId,
    required String userId,
  }) async {
    final AIAnalysisResult result = await AIService.analyzeFrame(imageBytes);

    final PostureRecordModel record = await PostureService.addRecord(
      sessionId: sessionId,
      userId: userId,
      postureScore: result.postureScore,
      isGoodPosture: result.isGoodPosture,
      torsoAngle: result.torsoAngle,
      neckAngle: result.neckAngle,
      shoulderAngle: result.shoulderAngle,
    );

    return record;
  }

  /// Analiz sonucuna göre exercises tablosundan egzersiz seçer ve kaydeder.
  /// Kötü duruş tespit edildiğinde çağrılır.
  static Future<List<ExerciseModel>> recommendExercises({
    required AIAnalysisResult result,
    required String userId,
  }) async {
    return await ExerciseService.autoRecommend(
      userId: userId,
      postureScore: result.postureScore,
      torsoAngle: result.torsoAngle,
      neckAngle: result.neckAngle,
      shoulderAngle: result.shoulderAngle,
    );
  }
}
