import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';
import 'mark_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = '';
  String _selectedSection = '';
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
              onSurface: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final schoolId = authProvider.currentSchool?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Modern Header
          _buildModernHeader(isDark),
          // Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('schoolId', isEqualTo: schoolId)
                  .where(
                    'date',
                    isEqualTo: DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                    ).toIso8601String(),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: AppColors.errorLight,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Error: ${snapshot.error}',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.errorLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(
                    message: 'Loading attendance records...',
                  );
                }

                var attendanceRecords = snapshot.data!.docs
                    .map(
                      (doc) => Attendance.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                // Filter by class and section if selected
                if (_selectedClass.isNotEmpty) {
                  attendanceRecords = attendanceRecords
                      .where((a) => a.className == _selectedClass)
                      .toList();
                }
                if (_selectedSection.isNotEmpty) {
                  attendanceRecords = attendanceRecords
                      .where((a) => a.section == _selectedSection)
                      .toList();
                }

                if (attendanceRecords.isEmpty) {
                  return ModernEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'No Attendance Records',
                    subtitle:
                        'No attendance records found for the selected filters',
                    actionText: 'Mark Attendance',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarkAttendanceScreen(),
                        ),
                      );
                    },
                  );
                }

                // Calculate statistics
                final present = attendanceRecords
                    .where((a) => a.status == 'present')
                    .length;
                final absent = attendanceRecords
                    .where((a) => a.status == 'absent')
                    .length;
                final leave = attendanceRecords
                    .where((a) => a.status == 'leave')
                    .length;

                return Column(
                  children: [
                    // Statistics Cards
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Present',
                              present.toString(),
                              Icons.check_circle_rounded,
                              AppColors.statusPresent,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildStatCard(
                              'Absent',
                              absent.toString(),
                              Icons.cancel_rounded,
                              AppColors.statusAbsent,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildStatCard(
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
                    // Attendance List
                    Expanded(
                      child: ListView.builder(
                        itemCount: attendanceRecords.length,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final attendance = attendanceRecords[index];
                          return _buildAttendanceCard(attendance, isDark);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MarkAttendanceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Mark Attendance'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // use 0 for sharp corners
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.dashboardAttendance,
                      AppColors.dashboardAttendance.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.fact_check_rounded,
                  color: Colors.white,
                  size: AppSpacing.iconSizeLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Management',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Track and manage student attendance records',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Filters
          Row(
            children: [
              // Date Picker
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 04,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: AppColors.dashboardAttendance,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Helpers.formatDate(_selectedDate),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Class Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: TextField(
                    controller: _classController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Class',
                      hintText: 'e.g., 1',
                      prefixIcon: Icon(
                        Icons.class_rounded,
                        color: AppColors.dashboardAttendance,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.dashboardAttendance,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value.trim();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Section Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: TextField(
                    controller: _sectionController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Section',
                      hintText: 'e.g., A',
                      prefixIcon: Icon(
                        Icons.label_rounded,
                        color: AppColors.dashboardAttendance,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.dashboardAttendance,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedSection = value.trim();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return CustomCard(
      hoverable: false,
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSpacing.iconSizeLg),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.numericLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance attendance, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (attendance.status) {
      case 'present':
        statusColor = AppColors.statusPresent;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Present';
        break;
      case 'absent':
        statusColor = AppColors.statusAbsent;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Absent';
        break;
      case 'leave':
        statusColor = AppColors.statusLeave;
        statusIcon = Icons.access_time_rounded;
        statusText = 'Leave';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_rounded;
        statusText = 'Unknown';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: AppSpacing.iconSizeLg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Attendance Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student ID: ${attendance.studentId}',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.class_rounded,
                        label:
                            '${attendance.className} - ${attendance.section}',
                        color: AppColors.dashboardClasses,
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildInfoChip(
                        icon: statusIcon,
                        label: statusText,
                        color: statusColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  if (attendance.remarks != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.note_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attendance.remarks!,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
