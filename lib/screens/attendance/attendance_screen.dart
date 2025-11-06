import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance.dart';
import '../../utils/helpers.dart';
import 'mark_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = '';
  String _selectedSection = '';

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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final schoolId = authProvider.currentSchool?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarkAttendanceScreen(),
                ),
              );
            },
            tooltip: 'Mark Attendance',
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
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                    ),
                    const SizedBox(width: 16),
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
                            _selectedClass = value;
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
                            _selectedSection = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('schoolId', isEqualTo: schoolId)
                  .where('date',
                      isEqualTo: DateTime(_selectedDate.year, _selectedDate.month,
                              _selectedDate.day)
                          .toIso8601String())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var attendanceRecords = snapshot.data!.docs
                    .map((doc) => Attendance.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ))
                    .toList();

                // Filter by class and section if selected
                if (_selectedClass.isNotEmpty) {
                  attendanceRecords = attendanceRecords
                      .where((a) => a.className == _selectedClass)
                      .toList();
                }
                if (_selectedSection.isNotEmpty) {
                  attendanceRecords = attendanceRecords
                      .where((a) => a.section == _selectedSection)
                      .toList();
                }

                if (attendanceRecords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MarkAttendanceScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_task),
                          label: const Text('Mark Attendance'),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate statistics
                final present =
                    attendanceRecords.where((a) => a.status == 'present').length;
                final absent =
                    attendanceRecords.where((a) => a.status == 'absent').length;
                final leave =
                    attendanceRecords.where((a) => a.status == 'leave').length;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Present',
                              present.toString(),
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Absent',
                              absent.toString(),
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Leave',
                              leave.toString(),
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: attendanceRecords.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final attendance = attendanceRecords[index];
                          Color statusColor;
                          IconData statusIcon;

                          switch (attendance.status) {
                            case 'present':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              break;
                            case 'absent':
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                              break;
                            case 'leave':
                              statusColor = Colors.orange;
                              statusIcon = Icons.access_time;
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusIcon = Icons.help;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: Icon(statusIcon, color: Colors.white),
                              ),
                              title: Text(
                                'Student ID: ${attendance.studentId}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      'Class: ${attendance.className} - ${attendance.section}'),
                                  Text('Status: ${attendance.status.toUpperCase()}'),
                                  if (attendance.remarks != null)
                                    Text('Remarks: ${attendance.remarks}'),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
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
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
