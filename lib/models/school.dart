class School {
  final String id;
  final String name;
  final String logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String licenseStatus; // 'active' or 'inactive'
  final DateTime expiryDate;
  final String address;
  final String contactNumber;
  final String email;

  School({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.licenseStatus,
    required this.expiryDate,
    required this.address,
    required this.contactNumber,
    required this.email,
  });

  factory School.fromMap(Map<String, dynamic> map, String id) {
    return School(
      id: id,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      primaryColor: map['primaryColor'] ?? '#673AB7',
      secondaryColor: map['secondaryColor'] ?? '#512DA8',
      licenseStatus: map['licenseStatus'] ?? 'inactive',
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : DateTime.now(),
      address: map['address'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'licenseStatus': licenseStatus,
      'expiryDate': expiryDate.toIso8601String(),
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
    };
  }

  bool get isLicenseActive {
    return licenseStatus == 'active' && expiryDate.isAfter(DateTime.now());
  }
}
