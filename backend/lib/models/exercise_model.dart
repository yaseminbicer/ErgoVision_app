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
      id: map['id'],
      userId: map['user_id'],
      exerciseName: map['exercise_name'],
      description: map['description'] ?? '',
      recommendedAt: DateTime.parse(map['recommended_at']),
    );
  }
}
