import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/fee.dart';
import '../../utils/helpers.dart';

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
  DateTime _dueDate = DateTime.now();
  DateTime? _paidDate;
  String _status = 'unpaid';
  String _month = '';
  int _year = DateTime.now().year;
  bool _isLoading = false;

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
    'December'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fee != null) {
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
    } else {
      _month = _months[DateTime.now().month - 1];
      _paidAmountController.text = '0';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fee == null ? 'Add Fee Record' : 'Edit Fee Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _month,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      items: _months
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _month = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _year.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _year = int.tryParse(value) ?? _year;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money),
                        prefixText: 'Rs. ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _paidAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                        prefixText: 'Rs. ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    Helpers.formatDate(_dueDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectPaidDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Paid Date (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _paidDate != null
                        ? Helpers.formatDate(_paidDate!)
                        : 'Not paid yet',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                child: Text(
                  _status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _status == 'paid'
                        ? Colors.green
                        : _status == 'partial'
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFee,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.fee == null
                            ? 'Add Fee Record'
                            : 'Update Fee Record',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
