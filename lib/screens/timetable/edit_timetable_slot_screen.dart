import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/timetable.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';

class EditTimetableSlotScreen extends StatefulWidget {
  final Timetable entry;

  const EditTimetableSlotScreen({super.key, required this.entry});

  @override
  State<EditTimetableSlotScreen> createState() =>
      _EditTimetableSlotScreenState();
}

class _EditTimetableSlotScreenState extends State<EditTimetableSlotScreen> {
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.entry.subjectId;
    _selectedSubjectName = widget.entry.subjectName;
    _selectedTeacherId = widget.entry.teacherId;
    _selectedTeacherName = widget.entry.teacherName;
  }

  Future<void> _saveSlot() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final slotData = {
        'schoolId': schoolId,
        'classId': widget.entry.classId,
        'className': widget.entry.className,
        'dayOfWeek': widget.entry.dayOfWeek,
        'timeSlot': widget.entry.timeSlot,
        'subjectId': _selectedSubjectId,
        'subjectName': _selectedSubjectName,
        'teacherId': _selectedTeacherId,
        'teacherName': _selectedTeacherName,
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.entry.id == null) {
        // Create new entry
        slotData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance.collection('timetable').add(slotData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Time slot assigned successfully');
        }
      } else {
        // Update existing entry
        slotData['createdAt'] = widget.entry.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('timetable')
            .doc(widget.entry.id)
            .update(slotData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Time slot updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving time slot: $e',
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

  Future<void> _clearSlot() async {
    if (widget.entry.id == null) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Clear Time Slot',
        content: const Text('Are you sure you want to clear this time slot?'),
        actions: [
          CustomButton(
            text: 'Cancel',
            variant: ButtonVariant.ghost,
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomButton(
            text: 'Clear',
            variant: ButtonVariant.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('timetable')
          .doc(widget.entry.id)
          .delete();

      if (mounted) {
        Helpers.showSnackBar(context, 'Time slot cleared successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error clearing time slot: $e',
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
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          _buildModernHeader(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSlotInfo(isDark),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSubjectSelector(isDark),
                  const SizedBox(height: AppSpacing.xl),
                  _buildTeacherSelector(isDark),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.entry.id != null)
                        CustomButton(
                          text: 'Clear Slot',
                          variant: ButtonVariant.outline,
                          onPressed: _clearSlot,
                          icon: Icons.clear_rounded,
                        ),
                      const Spacer(),
                      CustomButton(
                        text: 'Cancel',
                        variant: ButtonVariant.ghost,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      CustomButton(
                        text: 'Save',
                        icon: Icons.check_rounded,
                        isLoading: _isLoading,
                        onPressed: _saveSlot,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.edit_calendar_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Time Slot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.className,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotInfo(bool isDark) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardAttendance.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.dashboardAttendance,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Slot Information',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow('Day', widget.entry.dayOfWeek, isDark),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow('Time', widget.entry.timeSlot, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardClasses.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.book_rounded,
                    size: 20,
                    color: AppColors.dashboardClasses,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Select Subject',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subjects')
                  .where('schoolId', isEqualTo: schoolId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(
                    'Error loading subjects: ${snapshot.error}',
                    style: TextStyle(color: AppColors.errorDark),
                  );
                }

                final subjects = snapshot.data?.docs
                        .map((doc) => Subject.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ))
                        .toList() ??
                    [];

                if (subjects.isEmpty) {
                  return Text(
                    'No subjects available. Please add subjects first.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Select a subject',
                    prefixIcon: Icon(
                      Icons.book_rounded,
                      color: AppColors.dashboardClasses,
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
                        color: AppColors.dashboardClasses,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None - Free period'),
                    ),
                    ...subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject.id,
                        child: Text('${subject.name} (${subject.shortCode})'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value;
                      if (value != null) {
                        final subject =
                            subjects.firstWhere((s) => s.id == value);
                        _selectedSubjectName = subject.name;
                      } else {
                        _selectedSubjectName = null;
                      }
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherSelector(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.dashboardTeachers.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.dashboardTeachers,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Select Teacher (Optional)',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teachers')
                  .where('schoolId', isEqualTo: schoolId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(
                    'Error loading teachers: ${snapshot.error}',
                    style: TextStyle(color: AppColors.errorDark),
                  );
                }

                final teachers = snapshot.data?.docs
                        .map((doc) => Teacher.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ))
                        .toList() ??
                    [];

                if (teachers.isEmpty) {
                  return Text(
                    'No teachers available.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedTeacherId,
                  decoration: InputDecoration(
                    labelText: 'Teacher',
                    hintText: 'Select a teacher',
                    prefixIcon: Icon(
                      Icons.person_rounded,
                      color: AppColors.dashboardTeachers,
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
                        color: AppColors.dashboardTeachers,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...teachers.map((teacher) {
                      return DropdownMenuItem<String>(
                        value: teacher.id,
                        child: Text(teacher.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTeacherId = value;
                      if (value != null) {
                        final teacher =
                            teachers.firstWhere((t) => t.id == value);
                        _selectedTeacherName = teacher.name;
                      } else {
                        _selectedTeacherName = null;
                      }
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
