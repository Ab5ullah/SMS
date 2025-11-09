class AuditLog {
  final String id;
  final String schoolId;
  final String userId;
  final String userName;
  final String userEmail;
  final String action; // 'create', 'update', 'delete'
  final String module; // 'students', 'teachers', 'classes', 'attendance', 'fees', 'exams'
  final String recordId;
  final String recordTitle; // e.g., student name, teacher name, etc.
  final Map<String, dynamic>? changes; // For update actions, stores old and new values
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.action,
    required this.module,
    required this.recordId,
    required this.recordTitle,
    this.changes,
    required this.timestamp,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    return AuditLog(
      id: id,
      schoolId: map['schoolId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      action: map['action'] ?? '',
      module: map['module'] ?? '',
      recordId: map['recordId'] ?? '',
      recordTitle: map['recordTitle'] ?? '',
      changes: map['changes'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'action': action,
      'module': module,
      'recordId': recordId,
      'recordTitle': recordTitle,
      'changes': changes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get actionLabel {
    switch (action) {
      case 'create':
        return 'Created';
      case 'update':
        return 'Updated';
      case 'delete':
        return 'Deleted';
      default:
        return action;
    }
  }

  String get moduleLabel {
    switch (module) {
      case 'students':
        return 'Student';
      case 'teachers':
        return 'Teacher';
      case 'classes':
        return 'Class';
      case 'attendance':
        return 'Attendance';
      case 'fees':
        return 'Fee';
      case 'exams':
        return 'Exam';
      default:
        return module;
    }
  }
}
