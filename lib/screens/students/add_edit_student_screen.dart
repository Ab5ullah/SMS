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
  final _rollNumberController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedClassId;
  String _selectedClassName = '';
  String _selectedSection = '';
  DateTime _admissionDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _fatherNameController.text = widget.student!.fatherName;
      _selectedClassId = widget.student!.classId;
      _selectedClassName = widget.student!.className;
      _selectedSection = widget.student!.section;
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

      // Check capacity before adding/updating student
      if (_selectedClassId != null) {
        // Fetch the class to check capacity
        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(_selectedClassId)
            .get();

        if (classDoc.exists) {
          final classData = classDoc.data() as Map<String, dynamic>;
          final classCapacity = classData['capacity'] ?? 30;

          // Count current students in the class
          final studentsQuery = await FirebaseFirestore.instance
              .collection('students')
              .where('classId', isEqualTo: _selectedClassId)
              .get();

          int currentStudentCount = studentsQuery.docs.length;

          // If editing, exclude the current student from count
          if (widget.student != null && widget.student!.classId == _selectedClassId) {
            currentStudentCount--;
          }

          // Check if class is full
          if (currentStudentCount >= classCapacity) {
            if (mounted) {
              Helpers.showSnackBar(
                context,
                'Class is full! Capacity: $classCapacity students. Please select another class or increase capacity.',
                isError: true,
              );
            }
            return;
          }
        }
      }

      final now = DateTime.now();
      final studentData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'classId': _selectedClassId,
        'className': _selectedClassName,
        'section': _selectedSection,
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
                                _buildClassSelector(isDark),
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
                              icon: isEdit
                                  ? Icons.check_rounded
                                  : Icons.person_add_rounded,
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
          child: Icon(icon, size: 20, color: AppColors.dashboardStudents),
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

  Widget _buildClassSelector(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('className')
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
              'Error loading classes: ${snapshot.error}',
              style: TextStyle(color: AppColors.errorDark),
            ),
          );
        }

        final classes =
            snapshot.data?.docs
                .map(
                  (doc) => ClassSection.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList() ??
            [];

        if (classes.isEmpty) {
          return Container(
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
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 48,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No classes available',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create classes first to assign students',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClassId,
              decoration: InputDecoration(
                labelText: 'Select Class & Section',
                hintText: 'Choose a class',
                prefixIcon: Icon(
                  Icons.class_rounded,
                  color: AppColors.dashboardStudents,
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
                    color: AppColors.dashboardStudents,
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
                  child: Text(
                    '${classSection.className} - ${classSection.section} (Capacity: ${classSection.capacity})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a class';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  if (value != null) {
                    final selectedClass = classes.firstWhere(
                      (c) => c.id == value,
                    );
                    _selectedClassName = selectedClass.className;
                    _selectedSection = selectedClass.section;
                  }
                });
              },
            ),
            if (_selectedClassId != null) ...[
              const SizedBox(height: AppSpacing.xs),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('classId', isEqualTo: _selectedClassId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final selectedClass = classes.firstWhere(
                    (c) => c.id == _selectedClassId,
                  );
                  final currentCount = snapshot.data!.docs.length;
                  final capacity = selectedClass.capacity;
                  final availableSpots = capacity - currentCount;
                  final percentage = (currentCount / capacity * 100).round();

                  Color statusColor;
                  if (percentage >= 100) {
                    statusColor = isDark ? AppColors.errorDark : AppColors.errorLight;
                  } else if (percentage >= 80) {
                    statusColor = isDark ? AppColors.warningDark : AppColors.warningLight;
                  } else {
                    statusColor = isDark ? AppColors.successDark : AppColors.successLight;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: $_selectedClassName - $_selectedSection',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.dashboardStudents,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '$currentCount / $capacity students ($availableSpots ${availableSpots == 1 ? 'spot' : 'spots'} available)',
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
