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
import 'add_edit_class_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
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
                  .collection('classes')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('className')
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
                  return const LoadingWidget(message: 'Loading classes...');
                }

                final classes = snapshot.data!.docs
                    .map(
                      (doc) => ClassSection.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((classSection) {
                      if (_searchQuery.isEmpty) return true;
                      return classSection.className.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          classSection.section.toLowerCase().contains(
                            _searchQuery,
                          );
                    })
                    .toList();

                if (classes.isEmpty) {
                  return ModernEmptyState(
                    icon: _searchQuery.isEmpty
                        ? Icons.class_outlined
                        : Icons.search_off_rounded,
                    title: _searchQuery.isEmpty
                        ? 'No Classes Found'
                        : 'No Search Results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Get started by adding your first class'
                        : 'No classes match "$_searchQuery"',
                    actionText: _searchQuery.isEmpty ? 'Add Class' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => _navigateToAddClass(context)
                        : null,
                  );
                }

                return _isGridView
                    ? _buildGridView(classes, isDark)
                    : _buildListView(classes, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddClass(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class'),
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
                      'Class Management',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage all your classes in one place',
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
            hint: 'Search by class name or section...',
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

  Widget _buildListView(List<ClassSection> classes, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classSection = classes[index];
        return _buildClassListCard(classSection, isDark);
      },
    );
  }

  Widget _buildGridView(List<ClassSection> classes, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classSection = classes[index];
        return _buildClassGridCard(classSection, isDark);
      },
    );
  }

  Widget _buildClassListCard(ClassSection classSection, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        onTap: () => _showClassDetails(context, classSection, isDark),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dashboardClasses,
                    AppColors.dashboardClasses.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  classSection.className.isNotEmpty
                      ? classSection.className[0].toUpperCase()
                      : '?',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Class Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${classSection.className} - ${classSection.section}',
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
                        icon: Icons.people_rounded,
                        label: '${classSection.capacity} students',
                        color: AppColors.dashboardClasses,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  if (classSection.classTeacherId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.person_rounded,
                          label: 'Teacher assigned',
                          color: AppColors.dashboardTeachers,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
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
                  _showClassDetails(context, classSection, isDark);
                } else if (value == 'edit') {
                  _navigateToEditClass(context, classSection);
                } else if (value == 'delete') {
                  _confirmDelete(context, classSection);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassGridCard(ClassSection classSection, bool isDark) {
    return CustomCard(
      onTap: () => _showClassDetails(context, classSection, isDark),
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
                    AppColors.dashboardClasses,
                    AppColors.dashboardClasses.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  classSection.className.isNotEmpty
                      ? classSection.className[0].toUpperCase()
                      : '?',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${classSection.className} - ${classSection.section}',
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
              'Capacity: ${classSection.capacity}',
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
            if (classSection.classTeacherId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dashboardTeachers.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.dashboardTeachers.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Has Teacher',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.dashboardTeachers,
                    fontSize: 10,
                  ),
                ),
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

  void _navigateToAddClass(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditClassScreen()),
    );
  }

  void _navigateToEditClass(BuildContext context, ClassSection classSection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditClassScreen(classSection: classSection),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClassSection classSection) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Class',
      message:
          'Are you sure you want to delete ${classSection.className}-${classSection.section}? This action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classSection.id)
          .delete();

      if (context.mounted) {
        Helpers.showSnackBar(context, 'Class deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(
          context,
          'Error deleting class: $e',
          isError: true,
        );
      }
    }
  }

  void _showClassDetails(
    BuildContext context,
    ClassSection classSection,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: '${classSection.className} - ${classSection.section}',
        icon: Icons.class_rounded,
        iconColor: AppColors.dashboardClasses,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Class Name',
                classSection.className,
                Icons.class_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Section',
                classSection.section,
                Icons.label_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Capacity',
                '${classSection.capacity} students',
                Icons.people_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Class Teacher',
                classSection.classTeacherId ?? 'Not assigned',
                Icons.person_rounded,
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
              _navigateToEditClass(context, classSection);
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
              color: AppColors.dashboardClasses.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(icon, size: 16, color: AppColors.dashboardClasses),
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
