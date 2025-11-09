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
import 'add_edit_teacher_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
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
                  .collection('teachers')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('name')
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
                  return const LoadingWidget(message: 'Loading teachers...');
                }

                final teachers = snapshot.data!.docs
                    .map(
                      (doc) => Teacher.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((teacher) {
                      if (_searchQuery.isEmpty) return true;
                      return teacher.name.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          teacher.email.toLowerCase().contains(_searchQuery) ||
                          teacher.contact.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          teacher.subjects.any(
                            (s) => s.toLowerCase().contains(_searchQuery),
                          );
                    })
                    .toList();

                if (teachers.isEmpty) {
                  return ModernEmptyState(
                    icon: _searchQuery.isEmpty
                        ? Icons.person_outline_rounded
                        : Icons.search_off_rounded,
                    title: _searchQuery.isEmpty
                        ? 'No Teachers Found'
                        : 'No Search Results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Get started by adding your first teacher'
                        : 'No teachers match "$_searchQuery"',
                    actionText: _searchQuery.isEmpty ? 'Add Teacher' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => _navigateToAddTeacher(context)
                        : null,
                  );
                }

                return _isGridView
                    ? _buildGridView(teachers, isDark)
                    : _buildListView(teachers, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTeacher(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Teacher'),
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
                      'Teacher Management',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage all your teachers in one place',
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
            hint: 'Search by name, email, contact, or subject...',
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

  Widget _buildListView(List<Teacher> teachers, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return _buildTeacherListCard(teacher, isDark);
      },
    );
  }

  Widget _buildGridView(List<Teacher> teachers, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return _buildTeacherGridCard(teacher, isDark);
      },
    );
  }

  Widget _buildTeacherListCard(Teacher teacher, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        onTap: () => _showTeacherDetails(context, teacher, isDark),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dashboardTeachers,
                    AppColors.dashboardTeachers.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Teacher Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
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
                        icon: Icons.email_rounded,
                        label: teacher.email,
                        color: AppColors.dashboardTeachers,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (teacher.subjects.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: teacher.subjects.take(3).map((subject) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dashboardClasses.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.dashboardClasses.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            subject,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.dashboardClasses,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
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
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        size: 20,
                        color: AppColors.errorLight,
                      ),
                      SizedBox(width: AppSpacing.sm),
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
                  _showTeacherDetails(context, teacher, isDark);
                } else if (value == 'edit') {
                  _navigateToEditTeacher(context, teacher);
                } else if (value == 'delete') {
                  _confirmDelete(context, teacher);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherGridCard(Teacher teacher, bool isDark) {
    return CustomCard(
      onTap: () => _showTeacherDetails(context, teacher, isDark),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dashboardTeachers,
                    AppColors.dashboardTeachers.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              teacher.name,
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
            Text(
              teacher.email,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (teacher.subjects.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: teacher.subjects.take(2).map((subject) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dashboardClasses.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.dashboardClasses.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      subject,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.dashboardClasses,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
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
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTeacher(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTeacherScreen()),
    );
  }

  void _navigateToEditTeacher(BuildContext context, Teacher teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTeacherScreen(teacher: teacher),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Teacher teacher) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Teacher',
      message:
          'Are you sure you want to delete ${teacher.name}? This action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacher.id)
          .delete();

      if (context.mounted) {
        Helpers.showSnackBar(context, 'Teacher deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(
          context,
          'Error deleting teacher: $e',
          isError: true,
        );
      }
    }
  }

  void _showTeacherDetails(BuildContext context, Teacher teacher, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: teacher.name,
        icon: Icons.person_rounded,
        iconColor: AppColors.dashboardTeachers,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Email',
                teacher.email,
                Icons.email_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Contact',
                teacher.contact,
                Icons.phone_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Address',
                teacher.address,
                Icons.location_on_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Qualification',
                teacher.qualification,
                Icons.school_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Subjects',
                teacher.subjects.join(', '),
                Icons.book_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Assigned Classes',
                teacher.assignedClasses.isNotEmpty
                    ? teacher.assignedClasses.join(', ')
                    : 'No classes assigned',
                Icons.class_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Joining Date',
                Helpers.formatDate(teacher.joiningDate),
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
              _navigateToEditTeacher(context, teacher);
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
              color: AppColors.dashboardTeachers.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(icon, size: 16, color: AppColors.dashboardTeachers),
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
