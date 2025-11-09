import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/class_section.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';

class AddEditClassScreen extends StatefulWidget {
  final ClassSection? classSection;

  const AddEditClassScreen({super.key, this.classSection});

  @override
  State<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _classTeacherIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classSection != null) {
      _classNameController.text = widget.classSection!.className;
      _sectionController.text = widget.classSection!.section;
      _capacityController.text = widget.classSection!.capacity.toString();
      _classTeacherIdController.text = widget.classSection!.classTeacherId ?? '';
    } else {
      _capacityController.text = '30';
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    _capacityController.dispose();
    _classTeacherIdController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final classData = {
        'schoolId': schoolId,
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
        'classTeacherId': _classTeacherIdController.text.trim().isEmpty
            ? null
            : _classTeacherIdController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.classSection == null) {
        // Add new class
        classData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('classes')
            .add(classData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Class added successfully');
        }
      } else {
        // Update existing class
        classData['createdAt'] = widget.classSection!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classSection!.id)
            .update(classData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Class updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving class: $e',
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
    final isEdit = widget.classSection != null;

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
                        // Class Information Section
                        _buildSectionHeader(
                          'Class Information',
                          Icons.class_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _classNameController,
                                  label: 'Class Name',
                                  hint: 'e.g., 1, 2, 10',
                                  prefixIcon: Icons.class_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter class name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _sectionController,
                                  label: 'Section',
                                  hint: 'e.g., A, B, C',
                                  prefixIcon: Icons.label_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter section';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _capacityController,
                                  label: 'Capacity',
                                  hint: 'Maximum number of students',
                                  prefixIcon: Icons.people_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter capacity';
                                    }
                                    final capacity = int.tryParse(value);
                                    if (capacity == null || capacity <= 0) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Teacher Assignment Section
                        _buildSectionHeader(
                          'Teacher Assignment',
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
                                  controller: _classTeacherIdController,
                                  label: 'Class Teacher ID (Optional)',
                                  hint: 'Enter teacher ID',
                                  prefixIcon: Icons.person_rounded,
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                                  child: Text(
                                    'Leave empty if no teacher is assigned yet',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
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
                              text: isEdit ? 'Update Class' : 'Add Class',
                              icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
                              isLoading: _isLoading,
                              onPressed: _saveClass,
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
            AppColors.dashboardClasses,
            AppColors.dashboardClasses.withValues(alpha: 0.8),
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
                    isEdit ? 'Edit Class' : 'Add New Class',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update class information'
                        : 'Fill in the details to add a new class',
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
            color: AppColors.dashboardClasses.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.dashboardClasses,
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
}
