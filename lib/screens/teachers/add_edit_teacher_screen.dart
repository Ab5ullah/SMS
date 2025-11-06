import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/teacher.dart';
import '../../utils/helpers.dart';

class AddEditTeacherScreen extends StatefulWidget {
  final Teacher? teacher;

  const AddEditTeacherScreen({super.key, this.teacher});

  @override
  State<AddEditTeacherScreen> createState() => _AddEditTeacherScreenState();
}

class _AddEditTeacherScreenState extends State<AddEditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _assignedClassesController = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      _nameController.text = widget.teacher!.name;
      _contactController.text = widget.teacher!.contact;
      _emailController.text = widget.teacher!.email;
      _addressController.text = widget.teacher!.address;
      _qualificationController.text = widget.teacher!.qualification;
      _subjectsController.text = widget.teacher!.subjects.join(', ');
      _assignedClassesController.text = widget.teacher!.assignedClasses.join(', ');
      _joiningDate = widget.teacher!.joiningDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _qualificationController.dispose();
    _subjectsController.dispose();
    _assignedClassesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _joiningDate) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  List<String> _parseCommaSeparatedList(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final teacherData = {
        'schoolId': schoolId,
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'subjects': _parseCommaSeparatedList(_subjectsController.text),
        'assignedClasses': _parseCommaSeparatedList(_assignedClassesController.text),
        'joiningDate': _joiningDate.toIso8601String(),
        'photoUrl': null,
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.teacher == null) {
        // Add new teacher
        teacherData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('teachers')
            .add(teacherData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Teacher added successfully');
        }
      } else {
        // Update existing teacher
        teacherData['createdAt'] = widget.teacher!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(widget.teacher!.id)
            .update(teacherData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Teacher updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving teacher: $e',
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
        title: Text(widget.teacher == null ? 'Add Teacher' : 'Edit Teacher'),
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
                  labelText: 'Teacher Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter teacher name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(
                  labelText: 'Qualification',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter qualification';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectsController,
                decoration: const InputDecoration(
                  labelText: 'Subjects (comma separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                  hintText: 'e.g., Math, Science, English',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _assignedClassesController,
                decoration: const InputDecoration(
                  labelText: 'Assigned Classes (comma separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                  hintText: 'e.g., 1-A, 2-B, 3-C',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one class';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Joining Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    Helpers.formatDate(_joiningDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTeacher,
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
                        widget.teacher == null ? 'Add Teacher' : 'Update Teacher',
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
