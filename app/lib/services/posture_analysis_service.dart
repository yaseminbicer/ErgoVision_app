import '../models/session_model.dart';
import 'session_service.dart';
import 'exercise_service.dart';
import 'auth_service.dart';

class PostureAnalysisService {
  static Future<SessionModel?> startSession() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    return await SessionService.startSession(userId);
  }

  static Future<void> endSession({
    required String sessionId,
    required int durationSeconds,
    required List<String> activeWarnings,
  }) async {
    final userId = AuthService.currentUserId;

    await SessionService.endSession(sessionId, durationSeconds);

    if (userId != null && activeWarnings.isNotEmpty) {
      await ExerciseService.autoRecommend(
        userId: userId,
        sessionId: sessionId,
        activeWarnings: activeWarnings,
      );
    }
  }
}
