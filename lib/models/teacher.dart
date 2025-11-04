class Teacher {
  final String? id;
  final String schoolId;
  final String name;
  final String contact;
  final String email;
  final String address;
  final List<String> subjects;
  final List<String> assignedClasses;
  final String qualification;
  final DateTime joiningDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Teacher({
    this.id,
    required this.schoolId,
    required this.name,
    required this.contact,
    required this.email,
    required this.address,
    required this.subjects,
    required this.assignedClasses,
    required this.qualification,
    required this.joiningDate,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory Teacher.fromMap(Map<String, dynamic> map, [String? id]) {
    return Teacher(
      id: id ?? map['id'],
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      subjects: map['subjects'] != null
          ? List<String>.from(map['subjects'])
          : [],
      assignedClasses: map['assignedClasses'] != null
          ? List<String>.from(map['assignedClasses'])
          : [],
      qualification: map['qualification'] ?? '',
      joiningDate: map['joiningDate'] != null
          ? DateTime.parse(map['joiningDate'])
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
      'contact': contact,
      'email': email,
      'address': address,
      'subjects': subjects,
      'assignedClasses': assignedClasses,
      'qualification': qualification,
      'joiningDate': joiningDate.toIso8601String(),
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  Teacher copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? contact,
    String? email,
    String? address,
    List<String>? subjects,
    List<String>? assignedClasses,
    String? qualification,
    DateTime? joiningDate,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Teacher(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      address: address ?? this.address,
      subjects: subjects ?? this.subjects,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      qualification: qualification ?? this.qualification,
      joiningDate: joiningDate ?? this.joiningDate,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
