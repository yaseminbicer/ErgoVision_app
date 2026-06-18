class PostureSessionSummary {
  final int ergonomicSeconds;
  final int nonErgonomicSeconds;
  final List<String> finalWarnings;

  const PostureSessionSummary({
    required this.ergonomicSeconds,
    required this.nonErgonomicSeconds,
    this.finalWarnings = const [],
  });

  int get totalSeconds => ergonomicSeconds + nonErgonomicSeconds;

  double get ergonomicMinutes => ergonomicSeconds / 60;

  double get nonErgonomicMinutes => nonErgonomicSeconds / 60;

  double get ergonomicPercentage {
    if (totalSeconds == 0) return 0;
    return ergonomicSeconds / totalSeconds * 100;
  }

  double get nonErgonomicPercentage {
    if (totalSeconds == 0) return 0;
    return nonErgonomicSeconds / totalSeconds * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'ergonomic_seconds': ergonomicSeconds,
      'non_ergonomic_seconds': nonErgonomicSeconds,
      'total_seconds': totalSeconds,
      'ergonomic_percentage': ergonomicPercentage,
      'non_ergonomic_percentage': nonErgonomicPercentage,
    };
  }

  factory PostureSessionSummary.fromJson(Map<String, dynamic> json) {
    return PostureSessionSummary(
      ergonomicSeconds: json['ergonomic_seconds'] as int,
      nonErgonomicSeconds: json['non_ergonomic_seconds'] as int,
    );
  }
}
