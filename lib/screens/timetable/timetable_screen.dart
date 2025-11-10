import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/timetable.dart';
import '../../models/class_section.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'edit_timetable_slot_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _selectedClassId;
  String? _selectedClassName;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final List<String> _timeSlots = [
    '08:00-08:45',
    '08:45-09:30',
    '09:30-10:15',
    '10:15-10:30', // Break
    '10:30-11:15',
    '11:15-12:00',
    '12:00-12:45',
    '12:45-01:30', // Lunch
    '01:30-02:15',
    '02:15-03:00',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          _buildModernHeader(isDark),
          _buildClassSelector(isDark),
          Expanded(
            child: _selectedClassId == null
                ? _buildNoClassSelected(isDark)
                : _buildTimetableGrid(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.dashboardAttendance,
            AppColors.dashboardAttendance.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.calendar_view_week_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timetable Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedClassName ?? 'Select a class to view timetable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedClassId != null)
              IconButton(
                icon: const Icon(Icons.print_rounded, color: Colors.white),
                onPressed: () => _printTimetable(),
                tooltip: 'Print Timetable',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('schoolId', isEqualTo: schoolId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text(
              'Error loading classes: ${snapshot.error}',
              style: TextStyle(color: AppColors.errorDark),
            );
          }

          final classes = snapshot.data?.docs
                  .map((doc) => ClassSection.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ))
                  .toList() ??
              [];

          if (classes.isEmpty) {
            return Text(
              'No classes available. Please add classes first.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            );
          }

          return DropdownButtonFormField<String>(
            initialValue: _selectedClassId,
            decoration: InputDecoration(
              labelText: 'Select Class',
              prefixIcon: Icon(
                Icons.class_rounded,
                color: AppColors.dashboardAttendance,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.dashboardAttendance,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
            ),
            items: classes.map((classSection) {
              return DropdownMenuItem<String>(
                value: classSection.id,
                child: Text('${classSection.className} - ${classSection.section}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
                final selectedClass = classes.firstWhere((c) => c.id == value);
                _selectedClassName =
                    '${selectedClass.className} - ${selectedClass.section}';
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildNoClassSelected(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_view_week_outlined,
            size: 80,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Class Selected',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please select a class to view and manage timetable',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timetable')
          .where('schoolId', isEqualTo: schoolId)
          .where('classId', isEqualTo: _selectedClassId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading timetable: ${snapshot.error}',
              style: TextStyle(color: AppColors.errorDark),
            ),
          );
        }

        final timetableEntries = snapshot.data?.docs
                .map((doc) => Timetable.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList() ??
            [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Table(
                border: TableBorder.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  width: 1,
                ),
                defaultColumnWidth: const FixedColumnWidth(150),
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.dashboardAttendance.withValues(alpha: 0.1),
                    ),
                    children: [
                      _buildHeaderCell('Time', isDark),
                      ..._daysOfWeek.map((day) => _buildHeaderCell(day, isDark)),
                    ],
                  ),
                  // Time slot rows
                  ..._timeSlots.map((timeSlot) {
                    return TableRow(
                      children: [
                        _buildTimeSlotCell(timeSlot, isDark),
                        ..._daysOfWeek.map((day) {
                          final entry = timetableEntries.firstWhere(
                            (e) => e.dayOfWeek == day && e.timeSlot == timeSlot,
                            orElse: () => Timetable(
                              schoolId: schoolId,
                              classId: _selectedClassId!,
                              className: _selectedClassName!,
                              dayOfWeek: day,
                              timeSlot: timeSlot,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );
                          return _buildTimetableCell(entry, isDark);
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.dashboardAttendance,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeSlotCell(String timeSlot, bool isDark) {
    final isBreak = timeSlot == '10:15-10:30' || timeSlot == '12:45-01:30';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: isBreak
          ? AppColors.warningLight.withValues(alpha: 0.1)
          : null,
      child: Text(
        timeSlot,
        style: AppTypography.bodySmall.copyWith(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontWeight: isBreak ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimetableCell(Timetable entry, bool isDark) {
    final isBreak = entry.timeSlot == '10:15-10:30' || entry.timeSlot == '12:45-01:30';

    if (isBreak) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        color: AppColors.warningLight.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            entry.timeSlot == '10:15-10:30' ? 'Break' : 'Lunch',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.warningDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _editTimeSlot(entry),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        color: entry.subjectId != null
            ? AppColors.dashboardAttendance.withValues(alpha: 0.05)
            : null,
        child: entry.subjectId != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.subjectName ?? '',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.teacherName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.teacherName!,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              )
            : Center(
                child: Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
      ),
    );
  }

  void _editTimeSlot(Timetable entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTimetableSlotScreen(entry: entry),
      ),
    );
  }

  void _printTimetable() {
    // TODO: Implement print/PDF generation
    Helpers.showSnackBar(
      context,
      'Print functionality coming soon',
    );
  }
}
