import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';

class AddEditSubjectScreen extends StatefulWidget {
  final Subject? subject;

  const AddEditSubjectScreen({super.key, this.subject});

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _shortCodeController.text = widget.subject!.shortCode;
      _selectedTeacherId = widget.subject!.teacherId;
      _selectedTeacherName = widget.subject!.teacherName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final subjectData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'shortCode': _shortCodeController.text.trim().toUpperCase(),
        'teacherId': _selectedTeacherId,
        'teacherName': _selectedTeacherName,
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.subject == null) {
        // Add new subject
        subjectData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('subjects')
            .add(subjectData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Subject added successfully');
        }
      } else {
        // Update existing subject
        subjectData['createdAt'] = widget.subject!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subject!.id)
            .update(subjectData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Subject updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving subject: $e',
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
    final isEdit = widget.subject != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Modern Header
          _buildModernHeader(isDark, isEdit),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subject Information Section
                    _buildSectionHeader(
                      'Subject Information',
                      Icons.book_rounded,
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
                              label: 'Subject Name',
                              hint: 'e.g., Mathematics',
                              prefixIcon: Icons.book_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter subject name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CustomTextField(
                              controller: _shortCodeController,
                              label: 'Short Code',
                              hint: 'e.g., MATH',
                              prefixIcon: Icons.code_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter short code';
                                }
                                if (value.trim().length > 10) {
                                  return 'Code must be 10 characters or less';
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
                      'Teacher Assignment (Optional)',
                      Icons.person_rounded,
                      isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: _buildTeacherSelector(isDark),
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
                          text: isEdit ? 'Update Subject' : 'Add Subject',
                          icon: isEdit
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          isLoading: _isLoading,
                          onPressed: _saveSubject,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
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
              child: Icon(
                isEdit ? Icons.edit_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Subject' : 'Add New Subject',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update subject information'
                        : 'Create a new subject',
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

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.dashboardClasses.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 20, color: AppColors.dashboardClasses),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherSelector(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Error loading teachers: ${snapshot.error}',
              style: TextStyle(color: AppColors.errorDark),
            ),
          );
        }

        final teachers =
            snapshot.data?.docs.map((doc) {
              return Teacher.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList() ??
            [];

        if (teachers.isEmpty) {
          return Column(
            children: [
              Icon(
                Icons.person_off_rounded,
                size: 48,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No teachers available',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add teachers first to assign them to subjects',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedTeacherId,
              decoration: InputDecoration(
                labelText: 'Assign Teacher (Optional)',
                hintText: 'Select a teacher',
                prefixIcon: Icon(
                  Icons.person_rounded,
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
                  child: Text('None - No teacher assigned'),
                ),
                ...teachers.map((teacher) {
                  return DropdownMenuItem<String>(
                    value: teacher.id,
                    child: Text(
                      '${teacher.name} - ${teacher.subjects.join(', ')}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTeacherId = value;
                  if (value != null) {
                    final teacher = teachers.firstWhere((t) => t.id == value);
                    _selectedTeacherName = teacher.name;
                  } else {
                    _selectedTeacherName = null;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                'Optionally assign a teacher to this subject',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
