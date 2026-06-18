class ExerciseModel {
  final String id;
  final String userId;
  final String exerciseName;
  final String description;
  final DateTime recommendedAt;

  ExerciseModel({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.description,
    required this.recommendedAt,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      exerciseName: map['exercise_name'] as String,
      description: map['description'] as String? ?? '',
      recommendedAt: DateTime.parse(map['recommended_at'] as String),
    );
  }
}
