import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/exam.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';
import 'add_edit_exam_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                  .collection('exams')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('examDate', descending: true)
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
                  return const LoadingWidget(message: 'Loading exams...');
                }

                final exams = snapshot.data!.docs
                    .map(
                      (doc) => Exam.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((exam) {
                      if (_searchQuery.isEmpty) return true;
                      return exam.name.toLowerCase().contains(_searchQuery) ||
                          exam.subject.toLowerCase().contains(_searchQuery) ||
                          exam.className.toLowerCase().contains(_searchQuery);
                    })
                    .toList();

                if (exams.isEmpty) {
                  return ModernEmptyState(
                    icon: _searchQuery.isEmpty
                        ? Icons.assignment_outlined
                        : Icons.search_off_rounded,
                    title: _searchQuery.isEmpty
                        ? 'No Exams Found'
                        : 'No Search Results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Get started by adding your first exam'
                        : 'No exams match "$_searchQuery"',
                    actionText: _searchQuery.isEmpty ? 'Add Exam' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => _navigateToAddExam(context)
                        : null,
                  );
                }

                return _buildListView(exams, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExam(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Exam'),
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
                      'Exam Management',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage all your exams in one place',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
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
            hint: 'Search by exam name, subject, or class...',
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

  Widget _buildListView(List<Exam> exams, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return _buildExamListCard(exam, isDark);
      },
    );
  }

  Widget _buildExamListCard(Exam exam, bool isDark) {
    final isUpcoming = exam.examDate.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        onTap: () => _showExamDetails(context, exam, isDark),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dashboardAttendance,
                    AppColors.dashboardAttendance.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Icon(
                  isUpcoming ? Icons.upcoming_rounded : Icons.history_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Exam Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.name,
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
                        icon: Icons.subject_rounded,
                        label: exam.subject,
                        color: AppColors.dashboardAttendance,
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildInfoChip(
                        icon: Icons.class_rounded,
                        label: '${exam.className} - ${exam.section}',
                        color: AppColors.dashboardClasses,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatDate(exam.examDate),
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.grade_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Total: ${exam.totalMarks} | Pass: ${exam.passingMarks}',
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
                  _showExamDetails(context, exam, isDark);
                } else if (value == 'edit') {
                  _navigateToEditExam(context, exam);
                } else if (value == 'delete') {
                  _confirmDelete(context, exam);
                }
              },
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

  void _navigateToAddExam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditExamScreen()),
    );
  }

  void _navigateToEditExam(BuildContext context, Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditExamScreen(exam: exam)),
    );
  }

  void _confirmDelete(BuildContext context, Exam exam) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Exam',
      message:
          'Are you sure you want to delete ${exam.name}? This action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('exams')
          .doc(exam.id)
          .delete();

      if (context.mounted) {
        Helpers.showSnackBar(context, 'Exam deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Error deleting exam: $e', isError: true);
      }
    }
  }

  void _showExamDetails(BuildContext context, Exam exam, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: exam.name,
        icon: Icons.assignment_rounded,
        iconColor: AppColors.dashboardAttendance,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Subject',
                exam.subject,
                Icons.subject_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Class',
                '${exam.className} - ${exam.section}',
                Icons.class_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Exam Date',
                Helpers.formatDate(exam.examDate),
                Icons.calendar_today_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Total Marks',
                exam.totalMarks.toString(),
                Icons.grade_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Passing Marks',
                exam.passingMarks.toString(),
                Icons.check_circle_rounded,
                isDark,
              ),
              if (exam.remarks != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(
                  'Remarks',
                  exam.remarks!,
                  Icons.note_rounded,
                  isDark,
                ),
              ],
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
              _navigateToEditExam(context, exam);
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
              color: AppColors.dashboardAttendance.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(icon, size: 16, color: AppColors.dashboardAttendance),
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
