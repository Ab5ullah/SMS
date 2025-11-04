class Exam {
  final String? id;
  final String schoolId;
  final String name;
  final String className;
  final String section;
  final String subject;
  final DateTime examDate;
  final int totalMarks;
  final int passingMarks;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Exam({
    this.id,
    required this.schoolId,
    required this.name,
    required this.className,
    required this.section,
    required this.subject,
    required this.examDate,
    required this.totalMarks,
    required this.passingMarks,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Exam.fromMap(Map<String, dynamic> map, [String? id]) {
    return Exam(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      subject: map['subject'] ?? '',
      examDate: map['examDate'] != null
          ? DateTime.parse(map['examDate'])
          : DateTime.now(),
      totalMarks: map['totalMarks'] ?? 100,
      passingMarks: map['passingMarks'] ?? 40,
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
      'name': name,
      'className': className,
      'section': section,
      'subject': subject,
      'examDate': examDate.toIso8601String(),
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Exam copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? className,
    String? section,
    String? subject,
    DateTime? examDate,
    int? totalMarks,
    int? passingMarks,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Exam(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      className: className ?? this.className,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

class ExamResult {
  final String? id;
  final String schoolId;
  final String examId;
  final String studentId;
  final String studentName;
  final double marksObtained;
  final String grade;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  ExamResult({
    this.id,
    required this.schoolId,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.marksObtained,
    required this.grade,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory ExamResult.fromMap(Map<String, dynamic> map, [String? id]) {
    return ExamResult(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      examId: map['examId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      marksObtained: (map['marksObtained'] ?? 0).toDouble(),
      grade: map['grade'] ?? '',
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
      'examId': examId,
      'studentId': studentId,
      'studentName': studentName,
      'marksObtained': marksObtained,
      'grade': grade,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  ExamResult copyWith({
    String? id,
    String? schoolId,
    String? examId,
    String? studentId,
    String? studentName,
    double? marksObtained,
    String? grade,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return ExamResult(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      marksObtained: marksObtained ?? this.marksObtained,
      grade: grade ?? this.grade,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
