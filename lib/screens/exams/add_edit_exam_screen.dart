import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/exam.dart';
import '../../utils/helpers.dart';

class AddEditExamScreen extends StatefulWidget {
  final Exam? exam;

  const AddEditExamScreen({super.key, this.exam});

  @override
  State<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends State<AddEditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _examDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
      _nameController.text = widget.exam!.name;
      _subjectController.text = widget.exam!.subject;
      _classNameController.text = widget.exam!.className;
      _sectionController.text = widget.exam!.section;
      _totalMarksController.text = widget.exam!.totalMarks.toString();
      _passingMarksController.text = widget.exam!.passingMarks.toString();
      _remarksController.text = widget.exam!.remarks ?? '';
      _examDate = widget.exam!.examDate;
    } else {
      _totalMarksController.text = '100';
      _passingMarksController.text = '40';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _classNameController.dispose();
    _sectionController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _examDate) {
      setState(() {
        _examDate = picked;
      });
    }
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final examData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'subject': _subjectController.text.trim(),
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'examDate': _examDate.toIso8601String(),
        'totalMarks': int.parse(_totalMarksController.text.trim()),
        'passingMarks': int.parse(_passingMarksController.text.trim()),
        'remarks': _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.exam == null) {
        // Add new exam
        examData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('exams')
            .add(examData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Exam added successfully');
        }
      } else {
        // Update existing exam
        examData['createdAt'] = widget.exam!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('exams')
            .doc(widget.exam!.id)
            .update(examData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Exam updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving exam: $e',
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
        title: Text(widget.exam == null ? 'Add Exam' : 'Edit Exam'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exam Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                  hintText: 'e.g., Mid Term Exam, Final Exam',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter exam name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                  hintText: 'e.g., Mathematics, Science',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter subject';
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
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Exam Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    Helpers.formatDate(_examDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalMarksController,
                      decoration: const InputDecoration(
                        labelText: 'Total Marks',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grade),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final marks = int.tryParse(value);
                        if (marks == null || marks <= 0) {
                          return 'Invalid marks';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _passingMarksController,
                      decoration: const InputDecoration(
                        labelText: 'Passing Marks',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final passingMarks = int.tryParse(value);
                        final totalMarks =
                            int.tryParse(_totalMarksController.text);
                        if (passingMarks == null || passingMarks <= 0) {
                          return 'Invalid marks';
                        }
                        if (totalMarks != null &&
                            passingMarks > totalMarks) {
                          return 'Cannot exceed total';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
                onPressed: _isLoading ? null : _saveExam,
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
                        widget.exam == null ? 'Add Exam' : 'Update Exam',
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
