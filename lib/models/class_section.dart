class SubjectAssignment {
  final String subjectName;
  final String? teacherId;
  final String? teacherName;

  SubjectAssignment({
    required this.subjectName,
    this.teacherId,
    this.teacherName,
  });

  factory SubjectAssignment.fromMap(Map<String, dynamic> map) {
    return SubjectAssignment(
      subjectName: map['subjectName'] ?? '',
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
    };
  }

  SubjectAssignment copyWith({
    String? subjectName,
    String? teacherId,
    String? teacherName,
  }) {
    return SubjectAssignment(
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}

class ClassSection {
  final String? id;
  final String schoolId;
  final String className;
  final String section;
  final String? classTeacherId;
  final int capacity;
  final List<SubjectAssignment> subjects;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  ClassSection({
    this.id,
    required this.schoolId,
    required this.className,
    required this.section,
    this.classTeacherId,
    required this.capacity,
    this.subjects = const [],
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory ClassSection.fromMap(Map<String, dynamic> map, [String? id]) {
    return ClassSection(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      classTeacherId: map['classTeacherId'],
      capacity: map['capacity'] ?? 30,
      subjects: map['subjects'] != null
          ? (map['subjects'] as List)
              .map((subject) => SubjectAssignment.fromMap(subject))
              .toList()
          : [],
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
      'className': className,
      'section': section,
      'classTeacherId': classTeacherId,
      'capacity': capacity,
      'subjects': subjects.map((subject) => subject.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  String get displayName => '$className-$section';

  ClassSection copyWith({
    String? id,
    String? schoolId,
    String? className,
    String? section,
    String? classTeacherId,
    int? capacity,
    List<SubjectAssignment>? subjects,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return ClassSection(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      className: className ?? this.className,
      section: section ?? this.section,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      capacity: capacity ?? this.capacity,
      subjects: subjects ?? this.subjects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
