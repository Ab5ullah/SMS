import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/fee.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';
import 'add_edit_fee_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, paid, unpaid, partial

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
                  .collection('fees')
                  .where('schoolId', isEqualTo: schoolId)
                  .orderBy('dueDate', descending: true)
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
                  return const LoadingWidget(message: 'Loading fee records...');
                }

                var fees = snapshot.data!.docs
                    .map(
                      (doc) => Fee.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((fee) {
                      // Apply status filter
                      if (_statusFilter != 'all' &&
                          fee.status != _statusFilter) {
                        return false;
                      }
                      // Apply search filter
                      if (_searchQuery.isEmpty) return true;
                      return fee.studentName.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          fee.studentId.toLowerCase().contains(_searchQuery);
                    })
                    .toList();

                if (fees.isEmpty) {
                  return ModernEmptyState(
                    icon: _searchQuery.isEmpty && _statusFilter == 'all'
                        ? Icons.payment_outlined
                        : Icons.search_off_rounded,
                    title: _searchQuery.isEmpty && _statusFilter == 'all'
                        ? 'No Fee Records Found'
                        : 'No Search Results',
                    subtitle: _searchQuery.isEmpty && _statusFilter == 'all'
                        ? 'Get started by adding your first fee record'
                        : 'No fee records match your filters',
                    actionText: _searchQuery.isEmpty && _statusFilter == 'all'
                        ? 'Add Fee Record'
                        : null,
                    onAction: _searchQuery.isEmpty && _statusFilter == 'all'
                        ? () => _navigateToAddFee(context)
                        : null,
                  );
                }

                // Calculate statistics
                final totalAmount = fees.fold<double>(
                  0,
                  (sum, fee) => sum + fee.amount,
                );
                final totalPaid = fees.fold<double>(
                  0,
                  (sum, fee) => sum + fee.paidAmount,
                );
                final totalPending = totalAmount - totalPaid;

                return Column(
                  children: [
                    // Statistics Cards
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              'Rs. ${totalAmount.toStringAsFixed(0)}',
                              AppColors.dashboardFees,
                              Icons.account_balance_wallet_rounded,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildStatCard(
                              'Paid',
                              'Rs. ${totalPaid.toStringAsFixed(0)}',
                              AppColors.successLight,
                              Icons.check_circle_rounded,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildStatCard(
                              'Pending',
                              'Rs. ${totalPending.toStringAsFixed(0)}',
                              AppColors.warningLight,
                              Icons.pending_rounded,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fee List
                    Expanded(
                      child: ListView.builder(
                        itemCount: fees.length,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemBuilder: (context, index) {
                          final fee = fees[index];
                          return _buildFeeCard(fee, isDark);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddFee(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fee'),
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
                      'Fee Management',
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Track and manage all fee collections',
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
            hint: 'Search by student name or ID...',
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
          const SizedBox(height: AppSpacing.md),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Paid', 'paid', isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Unpaid', 'unpaid', isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Partial', 'partial', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _statusFilter == value;
    Color chipColor;

    switch (value) {
      case 'paid':
        chipColor = AppColors.successLight;
        break;
      case 'unpaid':
        chipColor = AppColors.errorLight;
        break;
      case 'partial':
        chipColor = AppColors.warningLight;
        break;
      default:
        chipColor = AppColors.dashboardFees;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _statusFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCard(Fee fee, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (fee.status) {
      case 'paid':
        statusColor = AppColors.successLight;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Paid';
        break;
      case 'unpaid':
        statusColor = AppColors.errorLight;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Unpaid';
        break;
      case 'partial':
        statusColor = AppColors.warningLight;
        statusIcon = Icons.pending_rounded;
        statusLabel = 'Partial';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_rounded;
        statusLabel = 'Unknown';
    }

    // Check if overdue
    final isOverdue =
        fee.status != 'paid' && fee.dueDate.isBefore(DateTime.now());
    if (isOverdue) {
      statusColor = AppColors.errorLight;
      statusLabel = 'Overdue';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        onTap: () => _showFeeDetails(context, fee, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee.studentName,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fee.className} - ${fee.section} | ${fee.month} ${fee.year}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Menu
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
                      _showFeeDetails(context, fee, isDark);
                    } else if (value == 'edit') {
                      _navigateToEditFee(context, fee);
                    } else if (value == 'delete') {
                      _confirmDelete(context, fee);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Fee Details
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFeeInfoChip(
                      'Amount',
                      'Rs. ${fee.amount.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                      AppColors.dashboardFees,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildFeeInfoChip(
                      'Paid',
                      'Rs. ${fee.paidAmount.toStringAsFixed(0)}',
                      Icons.payment_rounded,
                      AppColors.successLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildFeeInfoChip(
                      'Due',
                      Helpers.formatDate(fee.dueDate),
                      Icons.calendar_today_rounded,
                      isOverdue
                          ? AppColors.errorLight
                          : AppColors.dashboardFees,
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

  Widget _buildFeeInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAddFee(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditFeeScreen()),
    );
  }

  void _navigateToEditFee(BuildContext context, Fee fee) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditFeeScreen(fee: fee)),
    );
  }

  void _confirmDelete(BuildContext context, Fee fee) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Fee Record',
      message:
          'Are you sure you want to delete this fee record for ${fee.studentName}? This action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('fees').doc(fee.id).delete();

      if (context.mounted) {
        Helpers.showSnackBar(context, 'Fee record deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(
          context,
          'Error deleting fee record: $e',
          isError: true,
        );
      }
    }
  }

  void _showFeeDetails(BuildContext context, Fee fee, bool isDark) {
    Color statusColor;
    switch (fee.status) {
      case 'paid':
        statusColor = AppColors.successLight;
        break;
      case 'unpaid':
        statusColor = AppColors.errorLight;
        break;
      case 'partial':
        statusColor = AppColors.warningLight;
        break;
      default:
        statusColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: fee.studentName,
        icon: Icons.payment_rounded,
        iconColor: AppColors.dashboardFees,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Student ID',
                fee.studentId,
                Icons.badge_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Class',
                '${fee.className} - ${fee.section}',
                Icons.class_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Month',
                '${fee.month} ${fee.year}',
                Icons.calendar_month_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Amount',
                'Rs. ${fee.amount}',
                Icons.account_balance_wallet_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Paid Amount',
                'Rs. ${fee.paidAmount}',
                Icons.payment_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Remaining',
                'Rs. ${fee.remainingAmount}',
                Icons.pending_rounded,
                isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, size: 16, color: statusColor),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Status: ${fee.status.toUpperCase()}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Due Date',
                Helpers.formatDate(fee.dueDate),
                Icons.calendar_today_rounded,
                isDark,
              ),
              if (fee.paidDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(
                  'Paid Date',
                  Helpers.formatDate(fee.paidDate!),
                  Icons.event_available_rounded,
                  isDark,
                ),
              ],
              if (fee.remarks != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(
                  'Remarks',
                  fee.remarks!,
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
              _navigateToEditFee(context, fee);
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
              color: AppColors.dashboardFees.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(icon, size: 16, color: AppColors.dashboardFees),
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
