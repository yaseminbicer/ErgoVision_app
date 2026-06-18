import '../models/session_model.dart';
import 'session_service.dart';
import 'exercise_service.dart';
import 'auth_service.dart';

class PostureAnalysisService {
  /// Tracking ekranı başladığında Supabase'de bir oturum açar.
  /// Kullanıcı giriş yapmamışsa null döner.
  static Future<SessionModel?> startSession() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    return await SessionService.startSession(userId);
  }

  /// Tracking ekranı kapandığında oturumu sonlandırır ve
  /// aktif uyarılara göre egzersiz önerisi kaydeder.
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
        activeWarnings: activeWarnings,
      );
    }
  }
}
