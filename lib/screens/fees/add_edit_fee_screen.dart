import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/fee.dart';
import '../../models/student.dart';
import '../../utils/helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/dropdowns.dart';

class AddEditFeeScreen extends StatefulWidget {
  final Fee? fee;

  const AddEditFeeScreen({super.key, this.fee});

  @override
  State<AddEditFeeScreen> createState() => _AddEditFeeScreenState();
}

class _AddEditFeeScreenState extends State<AddEditFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _yearController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  DateTime? _paidDate;
  String _status = 'unpaid';
  String _month = '';
  int _year = DateTime.now().year;
  bool _isLoading = false;
  String? _selectedStudentId;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ]; // Keep for initState month initialization

  @override
  void initState() {
    super.initState();
    if (widget.fee != null) {
      _selectedStudentId = widget.fee!.studentId;
      _studentIdController.text = widget.fee!.studentId;
      _studentNameController.text = widget.fee!.studentName;
      _classNameController.text = widget.fee!.className;
      _sectionController.text = widget.fee!.section;
      _amountController.text = widget.fee!.amount.toString();
      _paidAmountController.text = widget.fee!.paidAmount.toString();
      _remarksController.text = widget.fee!.remarks ?? '';
      _dueDate = widget.fee!.dueDate;
      _paidDate = widget.fee!.paidDate;
      _status = widget.fee!.status;
      _month = widget.fee!.month;
      _year = widget.fee!.year;
      _yearController.text = _year.toString();
    } else {
      _month = _months[DateTime.now().month - 1];
      _paidAmountController.text = '0';
      _yearController.text = _year.toString();
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _classNameController.dispose();
    _sectionController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _remarksController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectPaidDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paidDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _paidDate = picked;
      });
    }
  }

  void _updateStatus() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0;

    setState(() {
      if (paidAmount >= amount) {
        _status = 'paid';
      } else if (paidAmount > 0) {
        _status = 'partial';
      } else {
        _status = 'unpaid';
      }
    });
  }

  Future<void> _saveFee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final feeData = {
        'schoolId': schoolId,
        'studentId': _studentIdController.text.trim(),
        'studentName': _studentNameController.text.trim(),
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'paidAmount': double.parse(_paidAmountController.text.trim()),
        'dueDate': _dueDate.toIso8601String(),
        'paidDate': _paidDate?.toIso8601String(),
        'status': _status,
        'month': _month,
        'year': _year,
        'remarks': _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.fee == null) {
        // Add new fee
        feeData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance.collection('fees').add(feeData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Fee record added successfully');
        }
      } else {
        // Update existing fee
        feeData['createdAt'] = widget.fee!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('fees')
            .doc(widget.fee!.id)
            .update(feeData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Fee record updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving fee record: $e',
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
    final isEdit = widget.fee != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Modern Header with Gradient
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
                        // Student Information Section
                        _buildSectionHeader(
                          'Student Information',
                          Icons.person_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Select Student",
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                StudentDropdown(
                                  schoolId: Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).currentSchool!.id,
                                  selectedValue: _selectedStudentId,
                                  isDark: isDark,
                                  onChanged: (Student? student) {
                                    if (student != null) {
                                      setState(() {
                                        _selectedStudentId = student.id;
                                        _studentIdController.text =
                                            student.id ?? '';
                                        _studentNameController.text =
                                            student.name;
                                        _classNameController.text =
                                            student.className;
                                        _sectionController.text =
                                            student.section;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a student';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                // Display selected student details (read-only)
                                if (_selectedStudentId != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.dashboardFees.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                      border: Border.all(
                                        color: AppColors.dashboardFees
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_rounded,
                                              size: 20,
                                              color: AppColors.dashboardFees,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Student Name',
                                                    style: AppTypography
                                                        .labelSmall
                                                        .copyWith(
                                                          color: isDark
                                                              ? AppColors
                                                                    .textSecondaryDark
                                                              : AppColors
                                                                    .textSecondaryLight,
                                                        ),
                                                  ),
                                                  Text(
                                                    _studentNameController.text,
                                                    style: AppTypography
                                                        .bodyMedium
                                                        .copyWith(
                                                          color: isDark
                                                              ? AppColors
                                                                    .textPrimaryDark
                                                              : AppColors
                                                                    .textPrimaryLight,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.class_rounded,
                                                    size: 18,
                                                    color:
                                                        AppColors.dashboardFees,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.xs,
                                                  ),
                                                  Text(
                                                    'Class: ${_classNameController.text}',
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          color: isDark
                                                              ? AppColors
                                                                    .textSecondaryDark
                                                              : AppColors
                                                                    .textSecondaryLight,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.label_rounded,
                                                    size: 18,
                                                    color:
                                                        AppColors.dashboardFees,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.xs,
                                                  ),
                                                  Text(
                                                    'Section: ${_sectionController.text}',
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          color: isDark
                                                              ? AppColors
                                                                    .textSecondaryDark
                                                              : AppColors
                                                                    .textSecondaryLight,
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
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Fee Details Section
                        _buildSectionHeader(
                          'Fee Details',
                          Icons.account_balance_wallet_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: MonthDropdown(
                                        selectedValue: _month.isEmpty
                                            ? null
                                            : _month,
                                        isDark: isDark,
                                        onChanged: (String? month) {
                                          if (month != null) {
                                            setState(() {
                                              _month = month;
                                            });
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a month';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _yearController,
                                        label: 'Year',
                                        hint: 'Enter year',
                                        prefixIcon:
                                            Icons.calendar_today_rounded,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          _year = int.tryParse(value) ?? _year;
                                        },
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _amountController,
                                        label: 'Total Amount',
                                        hint: 'Enter total amount',
                                        prefixIcon: Icons.money_rounded,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Invalid amount';
                                          }
                                          return null;
                                        },
                                        onChanged: (value) => _updateStatus(),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _paidAmountController,
                                        label: 'Paid Amount',
                                        hint: 'Enter paid amount',
                                        prefixIcon: Icons.payment_rounded,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Invalid amount';
                                          }
                                          return null;
                                        },
                                        onChanged: (value) => _updateStatus(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _buildStatusIndicator(isDark),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Payment Information Section
                        _buildSectionHeader(
                          'Payment Information',
                          Icons.calendar_month_rounded,
                          isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                _buildDatePicker(
                                  context,
                                  isDark,
                                  'Due Date',
                                  _dueDate,
                                  Icons.calendar_today_rounded,
                                  () => _selectDueDate(context),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _buildDatePicker(
                                  context,
                                  isDark,
                                  'Paid Date (Optional)',
                                  _paidDate,
                                  Icons.event_available_rounded,
                                  () => _selectPaidDate(context),
                                  isOptional: true,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomTextField(
                                  controller: _remarksController,
                                  label: 'Remarks (Optional)',
                                  hint: 'Add any additional notes',
                                  prefixIcon: Icons.note_rounded,
                                  maxLines: 3,
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
                              text: isEdit
                                  ? 'Update Fee Record'
                                  : 'Add Fee Record',
                              icon: isEdit
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              isLoading: _isLoading,
                              onPressed: _saveFee,
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
            AppColors.dashboardFees,
            AppColors.dashboardFees.withValues(alpha: 0.8),
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Fee Record' : 'Add New Fee Record',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update fee record information'
                        : 'Fill in the details to add a new fee record',
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
            color: AppColors.dashboardFees.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 20, color: AppColors.dashboardFees),
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

  Widget _buildStatusIndicator(bool isDark) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (_status) {
      case 'paid':
        statusColor = AppColors.successLight;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Fully Paid';
        break;
      case 'partial':
        statusColor = AppColors.warningLight;
        statusIcon = Icons.pending_rounded;
        statusLabel = 'Partially Paid';
        break;
      case 'unpaid':
        statusColor = AppColors.errorLight;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Unpaid';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_rounded;
        statusLabel = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Status',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: AppTypography.titleMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_status == 'partial' || _status == 'paid') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'Rs. ${(double.tryParse(_amountController.text) ?? 0) - (double.tryParse(_paidAmountController.text) ?? 0)}',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    bool isDark,
    String label,
    DateTime? date,
    IconData icon,
    VoidCallback onTap, {
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: onTap,
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
                color: AppColors.dashboardFees.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, size: 20, color: AppColors.dashboardFees),
            ),
            const SizedBox(width: AppSpacing.md),
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
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? Helpers.formatDate(date)
                        : (isOptional ? 'Not set' : 'Select date'),
                    style: AppTypography.bodyMedium.copyWith(
                      color: date != null
                          ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight)
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
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
}
