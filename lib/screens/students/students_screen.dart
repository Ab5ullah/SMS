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
import 'add_edit_student_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Modern Header with Search
          _buildModernHeader(isDark),
          // Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('rollNumber')
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
                  return const LoadingWidget(message: 'Loading students...');
                }

                final students = snapshot.data!.docs
                    .map(
                      (doc) => Student.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((student) {
                      if (_searchQuery.isEmpty) return true;
                      return student.name.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          student.rollNumber.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          student.fatherName.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          student.contact.toLowerCase().contains(_searchQuery);
                    })
                    .toList();

                if (students.isEmpty) {
                  return ModernEmptyState(
                    icon: _searchQuery.isEmpty
                        ? Icons.school_outlined
                        : Icons.search_off_rounded,
                    title: _searchQuery.isEmpty
                        ? 'No Students Found'
                        : 'No Search Results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Get started by adding your first student'
                        : 'No students match "$_searchQuery"',
                    actionText: _searchQuery.isEmpty ? 'Add Student' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => _navigateToAddStudent(context)
                        : null,
                  );
                }

                return _isGridView
                    ? _buildGridView(students, isDark)
                    : _buildListView(students, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddStudent(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Management',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage all your students in one place',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.view_list_rounded,
                      isSelected: !_isGridView,
                      onTap: () => setState(() => _isGridView = false),
                      isDark: isDark,
                    ),
                    _buildViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      isSelected: _isGridView,
                      onTap: () => setState(() => _isGridView = true),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Modern Search Bar
          ModernSearchBar(
            controller: _searchController,
            hint: 'Search by name, roll number, father name, or contact...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Student> students, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentListCard(student, isDark);
      },
    );
  }

  Widget _buildGridView(List<Student> students, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentGridCard(student, isDark);
      },
    );
  }

  Widget _buildStudentListCard(Student student, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        onTap: () => _showStudentDetails(context, student, isDark),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dashboardStudents,
                    AppColors.dashboardStudents.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
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
                        icon: Icons.numbers_rounded,
                        label: student.rollNumber,
                        color: AppColors.dashboardStudents,
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildInfoChip(
                        icon: Icons.class_rounded,
                        label: '${student.className} - ${student.section}',
                        color: AppColors.dashboardClasses,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        student.contact,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_rounded,
                        size: 20,
                        color: AppColors.errorLight,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Delete',
                        style: TextStyle(color: AppColors.errorLight),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'view') {
                  _showStudentDetails(context, student, isDark);
                } else if (value == 'edit') {
                  _navigateToEditStudent(context, student);
                } else if (value == 'delete') {
                  _confirmDelete(context, student);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentGridCard(Student student, bool isDark) {
    return CustomCard(
      onTap: () => _showStudentDetails(context, student, isDark),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dashboardStudents,
                  AppColors.dashboardStudents.withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: AppTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            student.name,
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          _buildInfoChip(
            icon: Icons.numbers_rounded,
            label: student.rollNumber,
            color: AppColors.dashboardStudents,
            isDark: isDark,
          ),
          const SizedBox(height: 4),
          Text(
            '${student.className} - ${student.section}',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
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

  void _navigateToAddStudent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditStudentScreen()),
    );
  }

  void _navigateToEditStudent(BuildContext context, Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStudentScreen(student: student),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Student student) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Student',
      message:
          'Are you sure you want to delete ${student.name}? This action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(student.id)
          .delete();

      if (context.mounted) {
        Helpers.showSnackBar(context, 'Student deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(
          context,
          'Error deleting student: $e',
          isError: true,
        );
      }
    }
  }

  void _showStudentDetails(BuildContext context, Student student, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: student.name,
        icon: Icons.person_rounded,
        iconColor: AppColors.dashboardStudents,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Roll Number',
                student.rollNumber,
                Icons.numbers_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Class',
                '${student.className} - ${student.section}',
                Icons.class_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Father Name',
                student.fatherName,
                Icons.person_outline_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Contact',
                student.contact,
                Icons.phone_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Address',
                student.address,
                Icons.location_on_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Admission Date',
                Helpers.formatDate(student.admissionDate),
                Icons.calendar_today_rounded,
                isDark,
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'Close',
            variant: ButtonVariant.ghost,
            onPressed: () => Navigator.pop(context),
          ),
          CustomButton(
            text: 'Edit',
            icon: Icons.edit_rounded,
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditStudent(context, student);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.dashboardStudents.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(icon, size: 16, color: AppColors.dashboardStudents),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
