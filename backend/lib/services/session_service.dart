import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';

final _supabase = Supabase.instance.client;

class SessionService {
  // Yeni oturum başlat
  static Future<SessionModel> startSession(String userId) async {
    final data = await _supabase
        .from('sessions')
        .insert({'user_id': userId})
        .select()
        .single();
    return SessionModel.fromMap(data);
  }

  // Oturumu bitir
  static Future<SessionModel> endSession(
      String sessionId, int durationSeconds) async {
    final data = await _supabase
        .from('sessions')
        .update({
          'ended_at': DateTime.now().toIso8601String(),
          'duration_seconds': durationSeconds,
        })
        .eq('id', sessionId)
        .select()
        .single();
    return SessionModel.fromMap(data);
  }

  // Kullanıcının tüm oturumlarını getir
  static Future<List<SessionModel>> getUserSessions(String userId) async {
    final data = await _supabase
        .from('sessions')
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false);
    return (data as List).map((e) => SessionModel.fromMap(e)).toList();
  }
}
