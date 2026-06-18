import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/posture_record_model.dart';

final _supabase = Supabase.instance.client;

class PostureService {
  // Duruş kaydı ekle
  static Future<PostureRecordModel> addRecord({
    required String sessionId,
    required String userId,
    required double postureScore,
    required bool isGoodPosture,
    required double torsoAngle,
    required double neckAngle,
    required double shoulderAngle,
  }) async {
    final data = await _supabase
        .from('posture_records')
        .insert({
          'session_id': sessionId,
          'user_id': userId,
          'posture_score': postureScore,
          'is_good_posture': isGoodPosture,
          'torso_angle': torsoAngle,
          'neck_angle': neckAngle,
          'shoulder_angle': shoulderAngle,
        })
        .select()
        .single();
    return PostureRecordModel.fromMap(data);
  }

  // Oturumdaki tüm kayıtlar
  static Future<List<PostureRecordModel>> getSessionRecords(
      String sessionId) async {
    final data = await _supabase
        .from('posture_records')
        .select()
        .eq('session_id', sessionId)
        .order('recorded_at', ascending: true);
    return (data as List).map((e) => PostureRecordModel.fromMap(e)).toList();
  }

  // Kullanıcı duruş özeti (son 100 kayıt)
  static Future<PostureSummary> getSummary(String userId) async {
    final data = await _supabase
        .from('posture_records')
        .select('posture_score, is_good_posture')
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(100);

    final records = data as List;
    final total = records.length;
    final goodCount =
        records.where((r) => r['is_good_posture'] == true).length;
    final avgScore = total > 0
        ? records
                .map((r) => (r['posture_score'] as num).toDouble())
                .reduce((a, b) => a + b) /
            total
        : 0.0;

    return PostureSummary(
      totalRecords: total,
      goodPostureCount: goodCount,
      badPostureCount: total - goodCount,
      goodPosturePercentage: total > 0 ? (goodCount / total) * 100 : 0.0,
      averageScore: avgScore,
    );
  }
}
