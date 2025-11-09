import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/teacher.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';

class AddEditTeacherScreen extends StatefulWidget {
  final Teacher? teacher;

  const AddEditTeacherScreen({super.key, this.teacher});

  @override
  State<AddEditTeacherScreen> createState() => _AddEditTeacherScreenState();
}

class _AddEditTeacherScreenState extends State<AddEditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _assignedClassesController = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _nameController.text = widget.teacher!.name;
      _contactController.text = widget.teacher!.contact;
      _emailController.text = widget.teacher!.email;
      _addressController.text = widget.teacher!.address;
      _qualificationController.text = widget.teacher!.qualification;
      _subjectsController.text = widget.teacher!.subjects.join(', ');
      _assignedClassesController.text = widget.teacher!.assignedClasses.join(', ');
      _joiningDate = widget.teacher!.joiningDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _qualificationController.dispose();
    _subjectsController.dispose();
    _assignedClassesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _joiningDate) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  List<String> _parseCommaSeparatedList(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final teacherData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'subjects': _parseCommaSeparatedList(_subjectsController.text),
        'assignedClasses': _parseCommaSeparatedList(_assignedClassesController.text),
        'joiningDate': _joiningDate.toIso8601String(),
        'photoUrl': null,
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.teacher == null) {
        // Add new teacher
        teacherData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('teachers')
            .add(teacherData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Teacher added successfully');
        }
      } else {
        // Update existing teacher
        teacherData['createdAt'] = widget.teacher!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(widget.teacher!.id)
            .update(teacherData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Teacher updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving teacher: $e',
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
    final isEdit = widget.teacher != null;

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
                                  label: 'Teacher Name',
                                  hint: 'Enter teacher full name',
                                  prefixIcon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter teacher name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter email address',
                                  prefixIcon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
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

                        // Professional Information Section
                        _buildSectionHeader(
                          'Professional Information',
                          Icons.work_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _qualificationController,
                                  label: 'Qualification',
                                  hint: 'e.g., B.Ed, M.A, M.Sc',
                                  prefixIcon: Icons.school_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter qualification';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _subjectsController,
                                  label: 'Subjects',
                                  hint: 'e.g., Math, Science, English',
                                  prefixIcon: Icons.book_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter at least one subject';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                                  child: Text(
                                    'Separate subjects with commas',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _assignedClassesController,
                                  label: 'Assigned Classes',
                                  hint: 'e.g., 9-A, 10-B, 11-C',
                                  prefixIcon: Icons.class_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter at least one class';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                                  child: Text(
                                    'Separate classes with commas',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
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
                              text: isEdit ? 'Update Teacher' : 'Add Teacher',
                              icon: isEdit ? Icons.check_rounded : Icons.person_add_rounded,
                              isLoading: _isLoading,
                              onPressed: _saveTeacher,
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
            AppColors.dashboardTeachers,
            AppColors.dashboardTeachers.withValues(alpha: 0.8),
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
                    isEdit ? 'Edit Teacher' : 'Add New Teacher',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update teacher information'
                        : 'Fill in the details to add a new teacher',
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
            color: AppColors.dashboardTeachers.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.dashboardTeachers,
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
                color: AppColors.dashboardTeachers.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: AppColors.dashboardTeachers,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joining Date',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatDate(_joiningDate),
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
