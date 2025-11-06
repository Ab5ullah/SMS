import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/student.dart';
import '../../utils/helpers.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = '';
  String _selectedSection = '';
  final Map<String, String> _attendanceStatus = {};
  bool _isLoading = false;
  List<Student> _students = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClass.isEmpty || _selectedSection.isEmpty) {
      Helpers.showSnackBar(
        context,
        'Please select class and section',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
          .where('className', isEqualTo: _selectedClass)
          .where('section', isEqualTo: _selectedSection)
          .orderBy('rollNumber')
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => Student.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList();

        // Initialize all as present by default
        _attendanceStatus.clear();
        for (var student in _students) {
          _attendanceStatus[student.id!] = 'present';
        }
      });
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error loading students: $e',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      Helpers.showSnackBar(
        context,
        'No students to mark attendance',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final schoolId = authProvider.currentSchool?.id ?? '';
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      for (var student in _students) {
        final status = _attendanceStatus[student.id] ?? 'present';
        final attendanceData = {
          'schoolId': schoolId,
          'studentId': student.id,
          'className': student.className,
          'section': student.section,
          'date': dateOnly.toIso8601String(),
          'status': status,
          'remarks': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'synced': true,
        };

        final docRef = FirebaseFirestore.instance.collection('attendance').doc();
        batch.set(docRef, attendanceData);
      }

      await batch.commit();

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Attendance marked successfully for ${_students.length} students',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving attendance: $e',
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
        title: const Text('Mark Attendance'),
        actions: [
          if (_students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveAttendance,
              tooltip: 'Save Attendance',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      Helpers.formatDate(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                          hintText: 'e.g., 1',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedClass = value.trim();
                            _students.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                          hintText: 'e.g., A',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value.trim();
                            _students.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadStudents,
                    icon: const Icon(Icons.search),
                    label: const Text('Load Students'),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_students.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select class and section to load students',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final status = _attendanceStatus[student.id] ?? 'present';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          student.rollNumber,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          'Roll No: ${student.rollNumber} | Class: ${student.className}-${student.section}'),
                      trailing: DropdownButton<String>(
                        value: status,
                        items: const [
                          DropdownMenuItem(
                            value: 'present',
                            child: Text('Present'),
                          ),
                          DropdownMenuItem(
                            value: 'absent',
                            child: Text('Absent'),
                          ),
                          DropdownMenuItem(
                            value: 'leave',
                            child: Text('Leave'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _attendanceStatus[student.id!] = value!;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _students.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Attendance',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            )
          : null,
    );
  }
}
