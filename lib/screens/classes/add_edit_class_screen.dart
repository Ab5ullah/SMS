import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/class_section.dart';
import '../../utils/helpers.dart';

class AddEditClassScreen extends StatefulWidget {
  final ClassSection? classSection;

  const AddEditClassScreen({super.key, this.classSection});

  @override
  State<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _classTeacherIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classSection != null) {
      _classNameController.text = widget.classSection!.className;
      _sectionController.text = widget.classSection!.section;
      _capacityController.text = widget.classSection!.capacity.toString();
      _classTeacherIdController.text = widget.classSection!.classTeacherId ?? '';
    } else {
      _capacityController.text = '30';
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    _capacityController.dispose();
    _classTeacherIdController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final now = DateTime.now();
      final classData = {
        'schoolId': schoolId,
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
        'classTeacherId': _classTeacherIdController.text.trim().isEmpty
            ? null
            : _classTeacherIdController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'synced': true,
      };

      if (widget.classSection == null) {
        // Add new class
        classData['createdAt'] = now.toIso8601String();
        await FirebaseFirestore.instance
            .collection('classes')
            .add(classData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Class added successfully');
        }
      } else {
        // Update existing class
        classData['createdAt'] = widget.classSection!.createdAt.toIso8601String();
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classSection!.id)
            .update(classData);
        if (mounted) {
          Helpers.showSnackBar(context, 'Class updated successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving class: $e',
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
        title: Text(widget.classSection == null ? 'Add Class' : 'Edit Class'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                  hintText: 'e.g., 1, 2, 10',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter class name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                  hintText: 'e.g., A, B, C',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter section';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                  hintText: 'Maximum number of students',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classTeacherIdController,
                decoration: const InputDecoration(
                  labelText: 'Class Teacher ID (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter teacher ID',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveClass,
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
                        widget.classSection == null ? 'Add Class' : 'Update Class',
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
