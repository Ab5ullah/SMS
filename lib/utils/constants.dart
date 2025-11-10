import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'School Management System';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color defaultPrimaryColor = Color(0xFF673AB7);
  static const Color defaultSecondaryColor = Color(0xFF512DA8);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Attendance Status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLeave = 'leave';

  // Fee Status
  static const String feePaid = 'paid';
  static const String feeUnpaid = 'unpaid';
  static const String feePartial = 'partial';

  // Student Status
  static const String studentActive = 'active';
  static const String studentGraduated = 'graduated';
  static const String studentLeft = 'left';

  // License Status
  static const String licenseActive = 'active';
  static const String licenseInactive = 'inactive';

  // User Roles
  static const String rolePrincipal = 'principal';
  static const String roleAdmin = 'admin';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy hh:mm a';

  // Months
  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Classes (can be customized per school)
  static const List<String> classes = [
    'Nursery',
    'Prep',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  // Sections
  static const List<String> sections = ['A', 'B', 'C', 'D', 'E'];

  // Subjects
  static const List<String> subjects = [
    'English',
    'Urdu',
    'Mathematics',
    'Science',
    'Social Studies',
    'Islamiat',
    'Computer',
    'Art',
    'Physical Education',
  ];

  // Grades
  static const List<String> grades = [
    'A+',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
  ];

  // Padding and Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
}
