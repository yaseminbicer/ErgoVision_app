class ExerciseLibraryModel {
  final String id;
  final String title;
  final String imagePath;
  final String youtubeUrl;
  final List<String> warningKeys;

  const ExerciseLibraryModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.youtubeUrl,
    required this.warningKeys,
  });

  factory ExerciseLibraryModel.fromMap(Map<String, dynamic> map) {
    return ExerciseLibraryModel(
      id: map['id'] as String,
      title: map['title'] as String,
      imagePath: map['image_path'] as String,
      youtubeUrl: map['youtube_url'] as String,
      warningKeys: List<String>.from(map['warning_keys'] as List? ?? []),
    );
  }

  bool matchesWarnings(List<String> activeWarnings) {
    if (warningKeys.isEmpty) return true;
    return warningKeys.any((k) => activeWarnings.contains(k));
  }
}
