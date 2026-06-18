class UserModel {
  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
