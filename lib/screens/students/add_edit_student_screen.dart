import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/student.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _admissionDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _fatherNameController.text = widget.student!.fatherName;
      _classNameController.text = widget.student!.className;
      _sectionController.text = widget.student!.section;
      _rollNumberController.text = widget.student!.rollNumber;
      _contactController.text = widget.student!.contact;
      _addressController.text = widget.student!.address;
      _admissionDate = widget.student!.admissionDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _classNameController.dispose();
    _sectionController.dispose();
    _rollNumberController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _admissionDate) {
      setState(() {
        _admissionDate = picked;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final studentData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'rollNumber': _rollNumberController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'admissionDate': _admissionDate.toIso8601String(),
        'photoUrl': null,
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.student == null) {
        // Add new student
        studentData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('students')
            .add(studentData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Student added successfully');
        }
      } else {
        // Update existing student
        studentData['createdAt'] = widget.student!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.student!.id)
            .update(studentData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Student updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving student: $e',
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
    final isEdit = widget.student != null;

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
                        // Personal Information Section
                        _buildSectionHeader(
                          'Personal Information',
                          Icons.person_rounded,
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
                                  label: 'Student Name',
                                  hint: 'Enter student full name',
                                  prefixIcon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter student name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _fatherNameController,
                                  label: 'Father Name',
                                  hint: 'Enter father full name',
                                  prefixIcon: Icons.person_outline_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter father name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _contactController,
                                  label: 'Contact Number',
                                  hint: 'Enter contact number',
                                  prefixIcon: Icons.phone_rounded,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter contact number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _addressController,
                                  label: 'Address',
                                  hint: 'Enter complete address',
                                  prefixIcon: Icons.location_on_rounded,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter address';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Academic Information Section
                        _buildSectionHeader(
                          'Academic Information',
                          Icons.school_rounded,
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
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _rollNumberController,
                                  label: 'Roll Number',
                                  hint: 'Enter roll number',
                                  prefixIcon: Icons.numbers_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter roll number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _buildDatePicker(context, isDark),
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
                              text: isEdit ? 'Update Student' : 'Add Student',
                              icon: isEdit ? Icons.check_rounded : Icons.person_add_rounded,
                              isLoading: _isLoading,
                              onPressed: _saveStudent,
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
            AppColors.dashboardStudents,
            AppColors.dashboardStudents.withValues(alpha: 0.8),
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
                isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
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
                    isEdit ? 'Edit Student' : 'Add New Student',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update student information'
                        : 'Fill in the details to add a new student',
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
            color: AppColors.dashboardStudents.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.dashboardStudents,
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
                color: AppColors.dashboardStudents.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: AppColors.dashboardStudents,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admission Date',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatDate(_admissionDate),
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
