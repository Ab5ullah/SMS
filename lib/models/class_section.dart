class ClassSection {
  final String? id;
  final String schoolId;
  final String className;
  final String section;
  final String? classTeacherId;
  final int capacity;
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
