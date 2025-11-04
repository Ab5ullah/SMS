class Attendance {
  final String? id;
  final String schoolId;
  final String studentId;
  final String className;
  final String section;
  final DateTime date;
  final String status; // 'present', 'absent', 'leave'
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Attendance({
    this.id,
    required this.schoolId,
    required this.studentId,
    required this.className,
    required this.section,
    required this.date,
    required this.status,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Attendance.fromMap(Map<String, dynamic> map, [String? id]) {
    return Attendance(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      studentId: map['studentId'] ?? '',
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      status: map['status'] ?? 'absent',
      remarks: map['remarks'],
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
      'studentId': studentId,
      'className': className,
      'section': section,
      'date': date.toIso8601String(),
      'status': status,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Attendance copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? className,
    String? section,
    DateTime? date,
    String? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Attendance(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      className: className ?? this.className,
      section: section ?? this.section,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
