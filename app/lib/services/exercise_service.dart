import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_library_model.dart';
import '../models/exercise_model.dart';

final _supabase = Supabase.instance.client;

class ExerciseService {
  static Future<List<ExerciseLibraryModel>> getAllExercises() async {
    final data = await _supabase.from('exercises').select();
    return (data as List)
        .map((e) => ExerciseLibraryModel.fromMap(e))
        .toList();
  }

  static Future<List<ExerciseLibraryModel>> getExercisesByWarnings(
      List<String> warnings) async {
    if (warnings.isEmpty) return getAllExercises();

    final data = await _supabase.from('exercises').select();
    final all = (data as List)
        .map((e) => ExerciseLibraryModel.fromMap(e))
        .toList();

    return all.where((ex) => ex.matchesWarnings(warnings)).toList();
  }

  static Future<List<ExerciseModel>> autoRecommend({
    required String userId,
    required String sessionId,
    required List<String> activeWarnings,
  }) async {
    if (activeWarnings.isEmpty) return [];

    final library = await getExercisesByWarnings(activeWarnings);
    if (library.isEmpty) return [];

    final rows = library
        .map((ex) => {
              'user_id': userId,
              'session_id': sessionId,
              'exercise_id': ex.id,
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

  static Future<List<ExerciseLibraryModel>> getExercisesForSession(
      String sessionId) async {
    final data = await _supabase
        .from('exercise_recommendations')
        .select('exercises!exercise_id(*)')
        .eq('session_id', sessionId);

    return (data as List)
        .where((r) => r['exercises'] != null)
        .map((r) => ExerciseLibraryModel.fromMap(
              r['exercises'] as Map<String, dynamic>,
            ))
        .toList();
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
}
