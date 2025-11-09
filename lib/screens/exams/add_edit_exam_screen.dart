import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/exam.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';

class AddEditExamScreen extends StatefulWidget {
  final Exam? exam;

  const AddEditExamScreen({super.key, this.exam});

  @override
  State<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends State<AddEditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _examDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
      _nameController.text = widget.exam!.name;
      _subjectController.text = widget.exam!.subject;
      _classNameController.text = widget.exam!.className;
      _sectionController.text = widget.exam!.section;
      _totalMarksController.text = widget.exam!.totalMarks.toString();
      _passingMarksController.text = widget.exam!.passingMarks.toString();
      _remarksController.text = widget.exam!.remarks ?? '';
      _examDate = widget.exam!.examDate;
    } else {
      _totalMarksController.text = '100';
      _passingMarksController.text = '40';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _classNameController.dispose();
    _sectionController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _examDate) {
      setState(() {
        _examDate = picked;
      });
    }
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final examData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'subject': _subjectController.text.trim(),
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'examDate': _examDate.toIso8601String(),
        'totalMarks': int.parse(_totalMarksController.text.trim()),
        'passingMarks': int.parse(_passingMarksController.text.trim()),
        'remarks': _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.exam == null) {
        // Add new exam
        examData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('exams')
            .add(examData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Exam added successfully');
        }
      } else {
        // Update existing exam
        examData['createdAt'] = widget.exam!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('exams')
            .doc(widget.exam!.id)
            .update(examData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Exam updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving exam: $e',
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
    final isEdit = widget.exam != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Modern Header
          _buildModernHeader(isDark, isEdit),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Exam Details Section
                        _buildSectionHeader(
                          'Exam Details',
                          Icons.assignment_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _nameController,
                                  label: 'Exam Name',
                                  hint: 'e.g., Mid Term Exam, Final Exam',
                                  prefixIcon: Icons.assignment_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter exam name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _subjectController,
                                  label: 'Subject',
                                  hint: 'e.g., Mathematics, Science',
                                  prefixIcon: Icons.subject_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter subject';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _classNameController,
                                        label: 'Class',
                                        hint: 'e.g., 9th, 10th',
                                        prefixIcon: Icons.class_rounded,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _sectionController,
                                        label: 'Section',
                                        hint: 'e.g., A, B',
                                        prefixIcon: Icons.label_rounded,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Marks Section
                        _buildSectionHeader(
                          'Marks',
                          Icons.grade_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _totalMarksController,
                                        label: 'Total Marks',
                                        hint: 'Enter total marks',
                                        prefixIcon: Icons.grade_rounded,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          final marks = int.tryParse(value);
                                          if (marks == null || marks <= 0) {
                                            return 'Invalid marks';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _passingMarksController,
                                        label: 'Passing Marks',
                                        hint: 'Enter passing marks',
                                        prefixIcon: Icons.check_circle_rounded,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          final passingMarks = int.tryParse(value);
                                          final totalMarks =
                                              int.tryParse(_totalMarksController.text);
                                          if (passingMarks == null || passingMarks <= 0) {
                                            return 'Invalid marks';
                                          }
                                          if (totalMarks != null &&
                                              passingMarks > totalMarks) {
                                            return 'Cannot exceed total';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Schedule Section
                        _buildSectionHeader(
                          'Schedule',
                          Icons.calendar_today_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                _buildDatePicker(context, isDark),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _remarksController,
                                  label: 'Remarks (Optional)',
                                  hint: 'Enter any additional notes',
                                  prefixIcon: Icons.note_rounded,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomButton(
                              text: 'Cancel',
                              variant: ButtonVariant.ghost,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            CustomButton(
                              text: isEdit ? 'Update Exam' : 'Add Exam',
                              icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
                              isLoading: _isLoading,
                              onPressed: _saveExam,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, bool isEdit) {
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
            CustomButton(
              text: '',
              icon: Icons.arrow_back_rounded,
              variant: ButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                isEdit ? Icons.edit_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Exam' : 'Add New Exam',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update exam information'
                        : 'Fill in the details to add a new exam',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.dashboardAttendance.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.dashboardAttendance,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.dashboardAttendance.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: AppColors.dashboardAttendance,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exam Date',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatDate(_examDate),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
