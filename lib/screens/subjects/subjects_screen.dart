import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/subject.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';
import 'add_edit_subject_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Modern Header
          _buildModernHeader(isDark),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: ModernSearchBar(
                          controller: _searchController,
                          hint: 'Search subjects...',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      CustomButton(
                        text: 'Add Subject',
                        icon: Icons.add_rounded,
                        onPressed: () => _navigateToAddSubject(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Subjects List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('subjects')
                          .where('schoolId', isEqualTo: schoolId)
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingWidget(
                            message: 'Loading subjects...',
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.errorDark
                                    : AppColors.errorLight,
                              ),
                            ),
                          );
                        }

                        final subjects = snapshot.data?.docs
                                .map((doc) => Subject.fromMap(
                                      doc.data() as Map<String, dynamic>,
                                      doc.id,
                                    ))
                                .where((subject) =>
                                    _searchQuery.isEmpty ||
                                    subject.name
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    subject.shortCode
                                        .toLowerCase()
                                        .contains(_searchQuery))
                                .toList() ??
                            [];

                        if (subjects.isEmpty) {
                          return ModernEmptyState(
                            icon: Icons.book_rounded,
                            title: _searchQuery.isEmpty
                                ? 'No Subjects Yet'
                                : 'No Subjects Found',
                            subtitle: _searchQuery.isEmpty
                                ? 'Create your first subject to get started'
                                : 'Try adjusting your search query',
                            actionText:
                                _searchQuery.isEmpty ? 'Add Subject' : null,
                            onAction: _searchQuery.isEmpty
                                ? () => _navigateToAddSubject(context)
                                : null,
                          );
                        }

                        return ListView.builder(
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return _buildSubjectCard(
                              context,
                              subject,
                              isDark,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subjects Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and manage school subjects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    Subject subject,
    bool isDark,
  ) {
    return CustomCard(
      onTap: () => _showSubjectDetails(context, subject, isDark),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Subject Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dashboardClasses.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.book_rounded,
                color: AppColors.dashboardClasses,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Subject Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Code: ${subject.shortCode}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (subject.teacherName != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            subject.teacherName!,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditSubject(context, subject);
                } else if (value == 'delete') {
                  _confirmDelete(context, subject);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDetails(
    BuildContext context,
    Subject subject,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: subject.name,
        icon: Icons.book_rounded,
        iconColor: AppColors.dashboardClasses,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              'Subject Name',
              subject.name,
              Icons.book_rounded,
              isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildDetailRow(
              'Short Code',
              subject.shortCode,
              Icons.code_rounded,
              isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildDetailRow(
              'Assigned Teacher',
              subject.teacherName ?? 'Not assigned',
              Icons.person_rounded,
              isDark,
            ),
          ],
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
              _navigateToEditSubject(context, subject);
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddSubject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditSubjectScreen(),
      ),
    );
  }

  void _navigateToEditSubject(BuildContext context, Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSubjectScreen(subject: subject),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subject subject) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Subject',
      message: 'Are you sure you want to delete "${subject.name}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(subject.id)
            .delete();

        if (context.mounted) {
          Helpers.showSnackBar(context, 'Subject deleted successfully');
        }
      } catch (e) {
        if (context.mounted) {
          Helpers.showSnackBar(
            context,
            'Error deleting subject: $e',
            isError: true,
          );
        }
      }
    }
  }
}
