import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/student.dart';
import '../../models/class_section.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/dropdowns.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = '';
  String _selectedSection = '';
  String? _selectedClassId;
  final Map<String, String> _attendanceStatus = {};
  bool _isLoading = false;
  List<Student> _students = [];
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  @override
  void dispose() {
    _classController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.dashboardAttendance,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClass.isEmpty || _selectedSection.isEmpty) {
      Helpers.showSnackBar(
        context,
        'Please select class and section',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
          .where('className', isEqualTo: _selectedClass)
          .where('section', isEqualTo: _selectedSection)
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => Student.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList();

        // Sort students by roll number in memory to avoid Firestore composite index requirement
        _students.sort((a, b) {
          // Handle null or empty roll numbers
          final aRoll = int.tryParse(a.rollNumber) ?? 999999;
          final bRoll = int.tryParse(b.rollNumber) ?? 999999;
          return aRoll.compareTo(bRoll);
        });

        // Initialize all as present by default
        _attendanceStatus.clear();
        for (var student in _students) {
          _attendanceStatus[student.id!] = 'present';
        }
      });
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading students: $e',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      Helpers.showSnackBar(
        context,
        'No students to mark attendance',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      for (var student in _students) {
        final status = _attendanceStatus[student.id] ?? 'present';
        final attendanceData = {
          'schoolId': schoolId,
          'studentId': student.id,
          'className': student.className,
          'section': student.section,
          'date': dateOnly.toIso8601String(),
          'status': status,
          'remarks': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'synced': true,
        };

        final docRef = FirebaseFirestore.instance.collection('attendance').doc();
        batch.set(docRef, attendanceData);
      }

      await batch.commit();

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Attendance marked successfully for ${_students.length} students',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving attendance: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Modern Header with Gradient
          _buildGradientHeader(isDark),
          // Content
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading students...')
                : _students.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildStudentsList(isDark),
          ),
        ],
      ),
      // Modern Bottom Action Bar
      bottomNavigationBar: _students.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: 'Save Attendance',
                  icon: Icons.save_rounded,
                  onPressed: _isLoading ? null : _saveAttendance,
                  isLoading: _isLoading,
                  fullWidth: true,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildGradientHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.dashboardAttendance,
            AppColors.dashboardAttendance.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardAttendance.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button and Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Attendance',
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Select class and date to mark attendance',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Helpers.formatDate(_selectedDate),
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Class Dropdown with white theme for gradient header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
                  ),
                  child: ClassDropdown(
                    schoolId: Provider.of<AuthProvider>(context, listen: false).currentSchool!.id,
                    selectedValue: _selectedClassId,
                    isDark: false, // Use light theme since we're on gradient background
                    onChanged: (ClassSection? classSection) {
                      if (classSection != null) {
                        setState(() {
                          _selectedClassId = classSection.id;
                          _selectedClass = classSection.className;
                          _selectedSection = classSection.section;
                          _classController.text = classSection.className;
                          _sectionController.text = classSection.section;
                          _students.clear();
                        });
                        // Auto-load students when class is selected
                        _loadStudents();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Load Students Button
              CustomButton(
                text: 'Load Students',
                icon: Icons.search_rounded,
                onPressed: _isLoading ? null : _loadStudents,
                isLoading: _isLoading,
                fullWidth: true,
                variant: ButtonVariant.secondary,
                size: ButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ModernEmptyState(
      icon: Icons.people_outline_rounded,
      title: 'No Students Loaded',
      subtitle: 'Select class and section, then tap "Load Students" to begin marking attendance',
    );
  }

  Widget _buildStudentsList(bool isDark) {
    // Calculate statistics
    final present = _attendanceStatus.values.where((s) => s == 'present').length;
    final absent = _attendanceStatus.values.where((s) => s == 'absent').length;
    final leave = _attendanceStatus.values.where((s) => s == 'leave').length;

    return Column(
      children: [
        // Quick Stats
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Present',
                  present.toString(),
                  Icons.check_circle_rounded,
                  AppColors.statusPresent,
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickStatCard(
                  'Absent',
                  absent.toString(),
                  Icons.cancel_rounded,
                  AppColors.statusAbsent,
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickStatCard(
                  'Leave',
                  leave.toString(),
                  Icons.access_time_rounded,
                  AppColors.statusLeave,
                  isDark,
                ),
              ),
            ],
          ),
        ),
        // Students List
        Expanded(
          child: ListView.builder(
            itemCount: _students.length,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemBuilder: (context, index) {
              final student = _students[index];
              final status = _attendanceStatus[student.id] ?? 'present';
              return _buildStudentCard(student, status, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student, String status, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'present':
        statusColor = AppColors.statusPresent;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'absent':
        statusColor = AppColors.statusAbsent;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'leave':
        statusColor = AppColors.statusLeave;
        statusIcon = Icons.access_time_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        child: Row(
          children: [
            // Student Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dashboardStudents,
                    AppColors.dashboardStudents.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  student.rollNumber,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll No: ${student.rollNumber} | Class: ${student.className}-${student.section}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Status Dropdown
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButton<String>(
                value: status,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: statusColor,
                  size: 20,
                ),
                style: AppTypography.labelMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                items: [
                  DropdownMenuItem(
                    value: 'present',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.statusPresent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Present',
                          style: TextStyle(color: AppColors.statusPresent),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'absent',
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: AppColors.statusAbsent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Absent',
                          style: TextStyle(color: AppColors.statusAbsent),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.statusLeave,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Leave',
                          style: TextStyle(color: AppColors.statusLeave),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _attendanceStatus[student.id!] = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
