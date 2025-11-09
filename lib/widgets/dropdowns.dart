import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../models/student.dart';
import '../models/class_section.dart';

/// Dropdown for selecting class from Firestore
class ClassDropdown extends StatelessWidget {
  final String schoolId;
  final String? selectedValue;
  final Function(ClassSection?) onChanged;
  final String? Function(String?)? validator;
  final bool isDark;

  const ClassDropdown({
    super.key,
    required this.schoolId,
    this.selectedValue,
    required this.onChanged,
    this.validator,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorDropdown(context);
        }

        if (!snapshot.hasData) {
          return _buildLoadingDropdown(context);
        }

        final classes = snapshot.data!.docs
            .map(
              (doc) => ClassSection.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Sort classes by name in memory to avoid Firestore composite index requirement
        classes.sort((a, b) => a.className.compareTo(b.className));

        if (classes.isEmpty) {
          return _buildEmptyDropdown(context);
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedValue,
            decoration: InputDecoration(
              labelText: 'Select Class',
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              prefixIcon: const Icon(
                Icons.class_rounded,
                color: AppColors.dashboardClasses,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            dropdownColor: isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            items: classes.map((classSection) {
              return DropdownMenuItem<String>(
                value: classSection.id,
                child: Text(
                  '${classSection.className} - ${classSection.section}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final selected = classes.firstWhere((c) => c.id == value);
                onChanged(selected);
              } else {
                onChanged(null);
              }
            },
            validator: validator,
          ),
        );
      },
    );
  }

  Widget _buildErrorDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorLight),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Error loading classes',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.errorLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Loading classes...',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warningLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warningLight),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'No classes found. Please create classes first.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.warningLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown for selecting student from Firestore (optionally filtered by class)
class StudentDropdown extends StatelessWidget {
  final String schoolId;
  final String? selectedValue;
  final Function(Student?) onChanged;
  final String? classId; // Filter by class if provided
  final String? Function(String?)? validator;
  final bool isDark;

  const StudentDropdown({
    super.key,
    required this.schoolId,
    this.selectedValue,
    required this.onChanged,
    this.classId,
    this.validator,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('students')
        .where('schoolId', isEqualTo: schoolId);

    // Filter by class if provided
    if (classId != null && classId!.isNotEmpty) {
      query = query.where('classId', isEqualTo: classId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorDropdown(context);
        }

        if (!snapshot.hasData) {
          return _buildLoadingDropdown(context);
        }

        final students = snapshot.data!.docs
            .map(
              (doc) =>
                  Student.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        // Sort students by name in memory to avoid Firestore composite index requirement
        students.sort((a, b) => a.name.compareTo(b.name));

        if (students.isEmpty) {
          return _buildEmptyDropdown(context);
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            // borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            // border: Border.all(
            //   color: isDark ? AppColors.borderDark : AppColors.borderLight,
            // ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedValue,
            decoration: InputDecoration(
              hintText: 'Select Student',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              prefixIcon: const Icon(
                Icons.person_rounded,
                color: AppColors.dashboardStudents,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            dropdownColor: isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            items: students.map((student) {
              return DropdownMenuItem<String>(
                value: student.id,
                child: Text(
                  '${student.name} (${student.className}-${student.section})',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final selected = students.firstWhere((s) => s.id == value);
                onChanged(selected);
              } else {
                onChanged(null);
              }
            },
            validator: validator,
          ),
        );
      },
    );
  }

  Widget _buildErrorDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorLight),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Error loading students',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.errorLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Loading students...',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warningLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warningLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              classId != null
                  ? 'No students in this class.'
                  : 'No students found. Please add students first.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warningLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple dropdown for month selection
class MonthDropdown extends StatelessWidget {
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool isDark;

  final List<String> months = const [
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

  const MonthDropdown({
    super.key,
    this.selectedValue,
    required this.onChanged,
    this.validator,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: 'Month',
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          prefixIcon: const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.dashboardFees,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        items: months
            .map(
              (month) => DropdownMenuItem(
                value: month,
                child: Text(
                  month,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
