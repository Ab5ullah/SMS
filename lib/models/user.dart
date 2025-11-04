class AppUser {
  final String id;
  final String email;
  final String name;
  final String schoolId;
  final String role; // 'principal' or 'admin'
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.schoolId,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      schoolId: map['schoolId'] ?? '',
      role: map['role'] ?? 'admin',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'schoolId': schoolId,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
