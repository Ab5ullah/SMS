class Subject {
  final String? id;
  final String schoolId;
  final String name;
  final String shortCode;
  final String? teacherId;
  final String? teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Subject({
    this.id,
    required this.schoolId,
    required this.name,
    required this.shortCode,
    this.teacherId,
    this.teacherName,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Subject.fromMap(Map<String, dynamic> map, [String? id]) {
    return Subject(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      shortCode: map['shortCode'] ?? '',
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      synced: map['synced'] == 1 || map['synced'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'schoolId': schoolId,
      'name': name,
      'shortCode': shortCode,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Subject copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? shortCode,
    String? teacherId,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Subject(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
