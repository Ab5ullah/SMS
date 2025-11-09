import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/class_section.dart';
import '../../models/teacher.dart';
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

class _SubjectTeacherRow {
  String? subjectName;
  String? teacherId;
  String? teacherName;
  TextEditingController subjectController = TextEditingController();

  _SubjectTeacherRow({this.subjectName, this.teacherId, this.teacherName}) {
    if (subjectName != null) {
      subjectController.text = subjectName!;
    }
  }

  void dispose() {
    subjectController.dispose();
  }
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _selectedTeacherId;
  bool _isLoading = false;
  final List<_SubjectTeacherRow> _subjectRows = [];

  @override
  void initState() {
    super.initState();
    if (widget.classSection != null) {
      _classNameController.text = widget.classSection!.className;
      _sectionController.text = widget.classSection!.section;
      _capacityController.text = widget.classSection!.capacity.toString();
      _selectedTeacherId = widget.classSection!.classTeacherId;

      // Load existing subject assignments
      for (var subject in widget.classSection!.subjects) {
        _subjectRows.add(
          _SubjectTeacherRow(
            subjectName: subject.subjectName,
            teacherId: subject.teacherId,
            teacherName: subject.teacherName,
          ),
        );
      }
    } else {
      _capacityController.text = '30';
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    _capacityController.dispose();
    for (var row in _subjectRows) {
      row.dispose();
    }
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
      // Build subjects list
      final subjects = _subjectRows
          .where((row) => row.subjectController.text.trim().isNotEmpty)
          .map(
            (row) => {
              'subjectName': row.subjectController.text.trim(),
              'teacherId': row.teacherId,
              'teacherName': row.teacherName,
            },
          )
          .toList();

      final classData = {
        'schoolId': schoolId,
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
        'classTeacherId': _selectedTeacherId,
        'subjects': subjects,
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.classSection == null) {
        // Add new class
        classData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance.collection('classes').add(classData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Class added successfully');
        }
      } else {
        // Update existing class
        classData['createdAt'] = widget.classSection!.createdAt
            .toIso8601String();
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
        Helpers.showSnackBar(context, 'Error saving class: $e', isError: true);
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

                        // Class Teacher Head Section
                        _buildSectionHeader(
                          'Class Teacher Head',
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
                        const SizedBox(height: AppSpacing.xl),

                        // Subject-Teacher Assignment Section
                        _buildSectionHeader(
                          'Subject-wise Teacher Assignment',
                          Icons.book_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: _buildSubjectAssignmentSection(isDark),
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
                              icon: isEdit
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
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
                'Add teachers first to assign them to classes',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTeacherId,
              decoration: InputDecoration(
                labelText: 'Class Teacher (Optional)',
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
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTeacherId = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                'Select a teacher to assign as class teacher',
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

  Widget _buildSubjectAssignmentSection(bool isDark) {
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

        final teachers =
            snapshot.data?.docs.map((doc) {
              return Teacher.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList() ??
            [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject rows
            if (_subjectRows.isNotEmpty)
              ...List.generate(_subjectRows.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildSubjectRow(
                    _subjectRows[index],
                    index,
                    teachers,
                    isDark,
                  ),
                );
              }),

            // Empty state
            if (_subjectRows.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark.withValues(alpha: 0.5)
                        : AppColors.borderLight.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books_rounded,
                      size: 48,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No subjects assigned yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Subject" to assign subjects and teachers',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // Add Subject Button
            CustomButton(
              text: 'Add Subject',
              icon: Icons.add_rounded,
              variant: ButtonVariant.outline,
              onPressed: () {
                setState(() {
                  _subjectRows.add(_SubjectTeacherRow());
                });
              },
            ),

            if (_subjectRows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Text(
                  'Add subjects and assign teachers for each subject',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSubjectRow(
    _SubjectTeacherRow row,
    int index,
    List<Teacher> teachers,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Subject Name Field
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: row.subjectController,
                  label: 'Subject Name',
                  hint: 'e.g., Mathematics',
                  prefixIcon: Icons.book_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter subject name';
                    }

                    // Check for duplicates
                    final duplicates = _subjectRows.where((r) {
                      return r != row &&
                          r.subjectController.text.trim().toLowerCase() ==
                              value.trim().toLowerCase();
                    }).toList();

                    if (duplicates.isNotEmpty) {
                      return 'Subject already added';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Delete Button
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: AppColors.errorLight,
                    size: AppSpacing.iconSizeLg,
                  ),
                  onPressed: () {
                    setState(() {
                      row.dispose();
                      _subjectRows.removeAt(index);
                    });
                  },
                  tooltip: 'Remove subject',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Teacher Dropdown
          DropdownButtonFormField<String>(
            initialValue: row.teacherId,
            decoration: InputDecoration(
              labelText: 'Assign Teacher (Optional)',
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
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                row.teacherId = value;
                if (value != null) {
                  final teacher = teachers.firstWhere((t) => t.id == value);
                  row.teacherName = teacher.name;
                } else {
                  row.teacherName = null;
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
