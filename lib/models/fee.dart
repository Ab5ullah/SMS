class Fee {
  final String? id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String className;
  final String section;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'paid', 'unpaid', 'partial'
  final String month;
  final int year;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Fee({
    this.id,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
    required this.amount,
    this.paidAmount = 0.0,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.month,
    required this.year,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Fee.fromMap(Map<String, dynamic> map, [String? id]) {
    return Fee(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now(),
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'])
          : null,
      status: map['status'] ?? 'unpaid',
      month: map['month'] ?? '',
      year: map['year'] ?? DateTime.now().year,
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
      'studentName': studentName,
      'className': className,
      'section': section,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'month': month,
      'year': year,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  double get remainingAmount => amount - paidAmount;

  Fee copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? studentName,
    String? className,
    String? section,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? paidDate,
    String? status,
    String? month,
    int? year,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Fee(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      section: section ?? this.section,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      month: month ?? this.month,
      year: year ?? this.year,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
