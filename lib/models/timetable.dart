class Timetable {
  final String? id;
  final String schoolId;
  final String classId;
  final String className;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String timeSlot; // e.g., "08:00-09:00"
  final String? subjectId;
  final String? subjectName;
  final String? teacherId;
  final String? teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Timetable({
    this.id,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.dayOfWeek,
    required this.timeSlot,
    this.subjectId,
    this.subjectName,
    this.teacherId,
    this.teacherName,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Timetable.fromMap(Map<String, dynamic> map, [String? id]) {
    return Timetable(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      subjectId: map['subjectId'],
      subjectName: map['subjectName'],
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
      'classId': classId,
      'className': className,
      'dayOfWeek': dayOfWeek,
      'timeSlot': timeSlot,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Timetable copyWith({
    String? id,
    String? schoolId,
    String? classId,
    String? className,
    String? dayOfWeek,
    String? timeSlot,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Timetable(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
