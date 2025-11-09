class Student {
  final String? id;
  final String schoolId;
  final String name;
  final String fatherName;
  final String? classId;  // Reference to class document ID
  final String className;
  final String section;
  final String rollNumber;
  final String contact;
  final String address;
  final DateTime admissionDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Student({
    this.id,
    required this.schoolId,
    required this.name,
    required this.fatherName,
    this.classId,
    required this.className,
    required this.section,
    required this.rollNumber,
    required this.contact,
    required this.address,
    required this.admissionDate,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Student.fromMap(Map<String, dynamic> map, [String? id]) {
    return Student(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      classId: map['classId'],
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      contact: map['contact'] ?? '',
      address: map['address'] ?? '',
      admissionDate: map['admissionDate'] != null
          ? DateTime.parse(map['admissionDate'])
          : DateTime.now(),
      photoUrl: map['photoUrl'],
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
      'fatherName': fatherName,
      'classId': classId,
      'className': className,
      'section': section,
      'rollNumber': rollNumber,
      'contact': contact,
      'address': address,
      'admissionDate': admissionDate.toIso8601String(),
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Student copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? fatherName,
    String? classId,
    String? className,
    String? section,
    String? rollNumber,
    String? contact,
    String? address,
    DateTime? admissionDate,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Student(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      rollNumber: rollNumber ?? this.rollNumber,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      admissionDate: admissionDate ?? this.admissionDate,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
