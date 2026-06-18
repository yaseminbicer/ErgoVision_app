import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_library_model.dart';
import '../models/exercise_model.dart';

final _supabase = Supabase.instance.client;

class ExerciseService {
  /// exercises kataloğundan tüm egzersizleri getirir.
  static Future<List<ExerciseLibraryModel>> getAllExercises() async {
    final data = await _supabase.from('exercises').select();
    return (data as List)
        .map((e) => ExerciseLibraryModel.fromMap(e))
        .toList();
  }

  /// Aktif uyarılara göre egzersizleri filtreler.
  /// warning_keys boş olan egzersizler (genel) her zaman dahil edilir.
  static Future<List<ExerciseLibraryModel>> getExercisesByWarnings(
      List<String> warnings) async {
    if (warnings.isEmpty) return getAllExercises();

    final data = await _supabase.from('exercises').select();
    final all = (data as List)
        .map((e) => ExerciseLibraryModel.fromMap(e))
        .toList();

    return all.where((ex) => ex.matchesWarnings(warnings)).toList();
  }

  /// Duruş analiz sonucuna göre exercises tablosundan uygun egzersizleri seçer
  /// ve exercise_recommendations tablosuna kaydeder.
  static Future<List<ExerciseModel>> autoRecommend({
    required String userId,
    required double postureScore,
    required double torsoAngle,
    required double neckAngle,
    required double shoulderAngle,
  }) async {
    final warnings = <String>[];

    if (torsoAngle < 160 || postureScore < 70) warnings.add('Slouching Detected');
    if (shoulderAngle < 160) warnings.add('Uneven Shoulders');

    if (warnings.isEmpty) return [];

    final library = await getExercisesByWarnings(warnings);
    if (library.isEmpty) return [];

    final rows = library
        .map((ex) => {
              'user_id': userId,
              'exercise_name': ex.title,
              'description': ex.youtubeUrl,
            })
        .toList();

    final data = await _supabase
        .from('exercise_recommendations')
        .insert(rows)
        .select();

    return (data as List).map((e) => ExerciseModel.fromMap(e)).toList();
  }

  static Future<List<ExerciseModel>> getUserRecommendations(
      String userId) async {
    final data = await _supabase
        .from('exercise_recommendations')
        .select()
        .eq('user_id', userId)
        .order('recommended_at', ascending: false);
    return (data as List).map((e) => ExerciseModel.fromMap(e)).toList();
  }

  static Future<void> deleteRecommendation(String id) async {
    await _supabase.from('exercise_recommendations').delete().eq('id', id);
  }
}
