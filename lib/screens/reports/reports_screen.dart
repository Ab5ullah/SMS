import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/report_service.dart';
import '../../models/student.dart';
import '../../models/attendance.dart';
import '../../models/fee.dart';
import '../../models/class_section.dart';
import '../../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedReportType = 'students';
  bool _isGenerating = false;

  // Filters
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedMonth;
  String? _selectedStatus;
  DateTime _selectedDate = DateTime.now();

  // Data
  List<ClassSection> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolId = authProvider.currentSchool!.id;
    final classes = await _firestoreService.getClassSections(schoolId);
    setState(() {
      _classes = classes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports & Export',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Generate and export reports in PDF or Excel format',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Report Type Selection
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Report Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildReportTypeChip(
                              'students',
                              'Student List',
                              Icons.people,
                              Colors.blue,
                            ),
                            _buildReportTypeChip(
                              'teachers',
                              'Teacher List',
                              Icons.person,
                              Colors.green,
                            ),
                            _buildReportTypeChip(
                              'attendance',
                              'Attendance Report',
                              Icons.fact_check,
                              Colors.orange,
                            ),
                            _buildReportTypeChip(
                              'fees',
                              'Fee Collection',
                              Icons.payment,
                              Colors.purple,
                            ),
                            _buildReportTypeChip(
                              'exams',
                              'Exam Results',
                              Icons.assignment,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filters Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFiltersForReportType(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : () => _generateReport('pdf'),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate PDF'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating || !_supportsExcel()
                                ? null
                                : () => _generateReport('excel'),
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Export to Excel'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isGenerating)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedReportType == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedReportType = value;
          _resetFilters();
        });
      },
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildFiltersForReportType() {
    switch (_selectedReportType) {
      case 'students':
      case 'teachers':
        return _buildClassSectionFilter();
      case 'attendance':
        return _buildAttendanceFilter();
      case 'fees':
        return _buildFeeFilter();
      case 'exams':
        return _buildExamFilter();
      default:
        return const SizedBox();
    }
  }

  Widget _buildClassSectionFilter() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('class_$_selectedClass'),
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
            ),
            value: _selectedClass,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Classes')),
              ..._classes.map(
                (c) => DropdownMenuItem(
                  value: c.className,
                  child: Text(c.className),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClass = value;
                _selectedSection = null;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('section_$_selectedSection'),
            decoration: const InputDecoration(
              labelText: 'Section',
              border: OutlineInputBorder(),
            ),
            value: _selectedSection,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Sections')),
              if (_selectedClass != null)
                ..._classes
                    .where((c) => c.className == _selectedClass)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.section,
                        child: Text(c.section),
                      ),
                    ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSection = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceFilter() {
    return Row(
      children: [
        Expanded(child: _buildClassSectionFilter()),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeFilter() {
    final months = [
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
    ];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('status_$_selectedStatus'),
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Status')),
              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
              DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
              DropdownMenuItem(value: 'Partial', child: Text('Partial')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('month_$_selectedMonth'),
            decoration: const InputDecoration(
              labelText: 'Month',
              border: OutlineInputBorder(),
            ),
            value: _selectedMonth,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Months')),
              ...months.map((m) => DropdownMenuItem(value: m, child: Text(m))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMonth = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamFilter() {
    return const Text(
      'Select an exam from the Exams module to generate results report',
      style: TextStyle(fontSize: 14, color: Colors.grey),
    );
  }

  bool _supportsExcel() {
    return _selectedReportType == 'students' ||
        _selectedReportType == 'fees' ||
        _selectedReportType == 'teachers';
  }

  void _resetFilters() {
    setState(() {
      _selectedClass = null;
      _selectedSection = null;
      _selectedMonth = null;
      _selectedStatus = null;
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _generateReport(String format) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final school = authProvider.currentSchool!;
      final schoolId = school.id;

      switch (_selectedReportType) {
        case 'students':
          await _generateStudentReport(schoolId, school, format);
          break;
        case 'teachers':
          await _generateTeacherReport(schoolId, school, format);
          break;
        case 'attendance':
          await _generateAttendanceReport(schoolId, school, format);
          break;
        case 'fees':
          await _generateFeeReport(schoolId, school, format);
          break;
        case 'exams':
          if (!mounted) return;
          Helpers.showSnackBar(
            context,
            'Please select an exam from the Exams module',
            isError: true,
          );
          break;
      }

      if (!mounted) return;
      Helpers.showSnackBar(context, 'Report generated successfully!');
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        'Error generating report: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateStudentReport(
    String schoolId,
    school,
    String format,
  ) async {
    List<Student> students = await _firestoreService.getStudents(schoolId);

    // Apply filters
    if (_selectedClass != null) {
      students = students.where((s) => s.className == _selectedClass).toList();
    }
    if (_selectedSection != null) {
      students = students.where((s) => s.section == _selectedSection).toList();
    }

    if (format == 'pdf') {
      await ReportService.generateStudentListPDF(
        students: students,
        school: school,
        className: _selectedClass,
        section: _selectedSection,
      );
    } else {
      final filePath = await ReportService.exportStudentsToExcel(
        students: students,
        school: school,
      );
      if (filePath != null) {
        await ReportService.openFile(filePath);
      }
    }
  }

  Future<void> _generateTeacherReport(
    String schoolId,
    school,
    String format,
  ) async {
    // Similar implementation for teachers
    if (!mounted) return;
    Helpers.showSnackBar(context, 'Teacher report generation coming soon!');
  }

  Future<void> _generateAttendanceReport(
    String schoolId,
    school,
    String format,
  ) async {
    List<Attendance> attendance = await _firestoreService.getAttendance(
      schoolId,
      _selectedDate,
    );
    List<Student> students = await _firestoreService.getStudents(schoolId);

    // Create attendance data with student details
    List<Map<String, dynamic>> attendanceData = [];
    for (var record in attendance) {
      final student = students.firstWhere(
        (s) => s.id == record.studentId,
        orElse: () => Student(
          schoolId: schoolId,
          name: 'Unknown',
          fatherName: '',
          className: record.className,
          section: record.section,
          rollNumber: '',
          contact: '',
          address: '',
          admissionDate: DateTime.now(),
          photoUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      attendanceData.add({
        'rollNumber': student.rollNumber,
        'studentName': student.name,
        'className': record.className,
        'section': record.section,
        'status': record.status,
        'remarks': record.remarks,
      });
    }

    // Apply filters
    if (_selectedClass != null) {
      attendanceData = attendanceData
          .where((a) => a['className'] == _selectedClass)
          .toList();
    }
    if (_selectedSection != null) {
      attendanceData = attendanceData
          .where((a) => a['section'] == _selectedSection)
          .toList();
    }

    await ReportService.generateAttendanceReportPDF(
      attendanceData: attendanceData,
      school: school,
      date: _selectedDate,
      className: _selectedClass,
      section: _selectedSection,
    );
  }

  Future<void> _generateFeeReport(
    String schoolId,
    school,
    String format,
  ) async {
    List<Fee> fees = await _firestoreService.getFees(schoolId);

    // Apply filters
    if (_selectedStatus != null) {
      fees = fees.where((f) => f.status == _selectedStatus).toList();
    }
    if (_selectedMonth != null) {
      fees = fees.where((f) => f.month == _selectedMonth).toList();
    }

    if (format == 'pdf') {
      await ReportService.generateFeeReportPDF(
        fees: fees,
        school: school,
        status: _selectedStatus,
        month: _selectedMonth,
      );
    } else {
      final filePath = await ReportService.exportFeesToExcel(
        fees: fees,
        school: school,
      );
      if (filePath != null) {
        await ReportService.openFile(filePath);
      }
    }
  }
}
