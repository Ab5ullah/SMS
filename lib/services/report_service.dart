import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/fee.dart';
import '../models/exam.dart';
import '../models/school.dart';
import '../utils/logger.dart';

class ReportService {
  // Generate Student List PDF
  static Future<void> generateStudentListPDF({
    required List<Student> students,
    required School school,
    String? className,
    String? section,
  }) async {
    try {
      final pdf = pw.Document();

      // Load school logo if available
      pw.ImageProvider? logo;
      if (school.logoUrl.isNotEmpty) {
        try {
          logo = await networkImage(school.logoUrl);
        } catch (e) {
          AppLogger.warning('Could not load school logo for PDF: $e');
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header with school branding
            _buildPDFHeader(school, logo, 'Student List Report'),
            pw.SizedBox(height: 20),

            // Filter info
            if (className != null || section != null)
              pw.Text(
                'Class: ${className ?? 'All'} | Section: ${section ?? 'All'}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            pw.SizedBox(height: 10),

            // Student table
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Roll No.', isHeader: true),
                    _buildTableCell('Name', isHeader: true),
                    _buildTableCell('Father Name', isHeader: true),
                    _buildTableCell('Class', isHeader: true),
                    _buildTableCell('Section', isHeader: true),
                    _buildTableCell('Contact', isHeader: true),
                  ],
                ),
                // Data rows
                ...students.map((student) => pw.TableRow(
                  children: [
                    _buildTableCell(student.rollNumber),
                    _buildTableCell(student.name),
                    _buildTableCell(student.fatherName),
                    _buildTableCell(student.className),
                    _buildTableCell(student.section),
                    _buildTableCell(student.contact),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Text(
              'Total Students: ${students.length}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),

            // Footer
            pw.Spacer(),
            _buildPDFFooter(),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      AppLogger.info('Student list PDF generated successfully');
    } catch (e) {
      AppLogger.error('Error generating student list PDF: $e');
      rethrow;
    }
  }

  // Generate Attendance Report PDF
  static Future<void> generateAttendanceReportPDF({
    required List<Map<String, dynamic>> attendanceData,
    required School school,
    required DateTime date,
    String? className,
    String? section,
  }) async {
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMM yyyy').format(date);

      pw.ImageProvider? logo;
      if (school.logoUrl.isNotEmpty) {
        try {
          logo = await networkImage(school.logoUrl);
        } catch (e) {
          AppLogger.warning('Could not load school logo for PDF: $e');
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildPDFHeader(school, logo, 'Attendance Report'),
            pw.SizedBox(height: 20),

            pw.Text(
              'Date: $dateStr | Class: ${className ?? 'All'} | Section: ${section ?? 'All'}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Roll No.', isHeader: true),
                    _buildTableCell('Student Name', isHeader: true),
                    _buildTableCell('Class', isHeader: true),
                    _buildTableCell('Section', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                    _buildTableCell('Remarks', isHeader: true),
                  ],
                ),
                ...attendanceData.map((record) => pw.TableRow(
                  children: [
                    _buildTableCell(record['rollNumber'] ?? ''),
                    _buildTableCell(record['studentName'] ?? ''),
                    _buildTableCell(record['className'] ?? ''),
                    _buildTableCell(record['section'] ?? ''),
                    _buildTableCell(record['status'] ?? ''),
                    _buildTableCell(record['remarks'] ?? ''),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 20),
            _buildAttendanceSummary(attendanceData),

            pw.Spacer(),
            _buildPDFFooter(),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      AppLogger.info('Attendance report PDF generated successfully');
    } catch (e) {
      AppLogger.error('Error generating attendance report PDF: $e');
      rethrow;
    }
  }

  // Generate Fee Report PDF
  static Future<void> generateFeeReportPDF({
    required List<Fee> fees,
    required School school,
    String? status,
    String? month,
  }) async {
    try {
      final pdf = pw.Document();

      pw.ImageProvider? logo;
      if (school.logoUrl.isNotEmpty) {
        try {
          logo = await networkImage(school.logoUrl);
        } catch (e) {
          AppLogger.warning('Could not load school logo for PDF: $e');
        }
      }

      double totalAmount = fees.fold(0, (sum, fee) => sum + fee.amount);
      double totalPaid = fees.fold(0, (sum, fee) => sum + fee.paidAmount);
      double totalDue = totalAmount - totalPaid;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildPDFHeader(school, logo, 'Fee Collection Report'),
            pw.SizedBox(height: 20),

            pw.Text(
              'Status: ${status ?? 'All'} | Month: ${month ?? 'All'}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Student', isHeader: true),
                    _buildTableCell('Class', isHeader: true),
                    _buildTableCell('Month', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                    _buildTableCell('Paid', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                  ],
                ),
                ...fees.map((fee) => pw.TableRow(
                  children: [
                    _buildTableCell(fee.studentName),
                    _buildTableCell('${fee.className}-${fee.section}'),
                    _buildTableCell(fee.month),
                    _buildTableCell('Rs. ${fee.amount.toStringAsFixed(0)}'),
                    _buildTableCell('Rs. ${fee.paidAmount.toStringAsFixed(0)}'),
                    _buildTableCell(fee.status),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                color: PdfColors.grey200,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Total Amount: Rs. ${totalAmount.toStringAsFixed(0)}'),
                  pw.Text('Total Paid: Rs. ${totalPaid.toStringAsFixed(0)}'),
                  pw.Text('Total Due: Rs. ${totalDue.toStringAsFixed(0)}'),
                ],
              ),
            ),

            pw.Spacer(),
            _buildPDFFooter(),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      AppLogger.info('Fee report PDF generated successfully');
    } catch (e) {
      AppLogger.error('Error generating fee report PDF: $e');
      rethrow;
    }
  }

  // Generate Exam Results PDF
  static Future<void> generateExamResultsPDF({
    required Exam exam,
    required List<ExamResult> results,
    required School school,
  }) async {
    try {
      final pdf = pw.Document();

      pw.ImageProvider? logo;
      if (school.logoUrl.isNotEmpty) {
        try {
          logo = await networkImage(school.logoUrl);
        } catch (e) {
          AppLogger.warning('Could not load school logo for PDF: $e');
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildPDFHeader(school, logo, 'Exam Results'),
            pw.SizedBox(height: 20),

            pw.Text(
              'Exam: ${exam.name} | Class: ${exam.className}-${exam.section} | Subject: ${exam.subject}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${DateFormat('dd MMM yyyy').format(exam.examDate)} | Total Marks: ${exam.totalMarks} | Passing: ${exam.passingMarks}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Student Name', isHeader: true),
                    _buildTableCell('Marks Obtained', isHeader: true),
                    _buildTableCell('Grade', isHeader: true),
                    _buildTableCell('Remarks', isHeader: true),
                  ],
                ),
                ...results.map((result) => pw.TableRow(
                  children: [
                    _buildTableCell(result.studentName),
                    _buildTableCell('${result.marksObtained}/${exam.totalMarks}'),
                    _buildTableCell(result.grade),
                    _buildTableCell(result.remarks ?? ''),
                  ],
                )),
              ],
            ),

            pw.Spacer(),
            _buildPDFFooter(),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      AppLogger.info('Exam results PDF generated successfully');
    } catch (e) {
      AppLogger.error('Error generating exam results PDF: $e');
      rethrow;
    }
  }

  // Excel Export - Students
  static Future<String?> exportStudentsToExcel({
    required List<Student> students,
    required School school,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Students'];

      // Header row
      sheet.appendRow([
        TextCellValue('Roll Number'),
        TextCellValue('Name'),
        TextCellValue('Father Name'),
        TextCellValue('Class'),
        TextCellValue('Section'),
        TextCellValue('Contact'),
        TextCellValue('Address'),
        TextCellValue('Admission Date'),
      ]);

      // Data rows
      for (var student in students) {
        sheet.appendRow([
          TextCellValue(student.rollNumber),
          TextCellValue(student.name),
          TextCellValue(student.fatherName),
          TextCellValue(student.className),
          TextCellValue(student.section),
          TextCellValue(student.contact),
          TextCellValue(student.address),
          TextCellValue(DateFormat('dd MMM yyyy').format(student.admissionDate)),
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = directory.path;
      final filePath = '$dirPath${Platform.pathSeparator}student_list_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      AppLogger.info('Students exported to Excel: $filePath');
      return filePath;
    } catch (e) {
      AppLogger.error('Error exporting students to Excel: $e');
      return null;
    }
  }

  // Excel Export - Fees
  static Future<String?> exportFeesToExcel({
    required List<Fee> fees,
    required School school,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Fees'];

      // Header row
      sheet.appendRow([
        TextCellValue('Student Name'),
        TextCellValue('Class'),
        TextCellValue('Section'),
        TextCellValue('Month'),
        TextCellValue('Year'),
        TextCellValue('Amount'),
        TextCellValue('Paid Amount'),
        TextCellValue('Status'),
        TextCellValue('Due Date'),
        TextCellValue('Paid Date'),
      ]);

      // Data rows
      for (var fee in fees) {
        sheet.appendRow([
          TextCellValue(fee.studentName),
          TextCellValue(fee.className),
          TextCellValue(fee.section),
          TextCellValue(fee.month),
          TextCellValue(fee.year.toString()),
          TextCellValue(fee.amount.toStringAsFixed(0)),
          TextCellValue(fee.paidAmount.toStringAsFixed(0)),
          TextCellValue(fee.status),
          TextCellValue(DateFormat('dd MMM yyyy').format(fee.dueDate)),
          fee.paidDate != null
              ? TextCellValue(DateFormat('dd MMM yyyy').format(fee.paidDate!))
              : TextCellValue(''),
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = directory.path;
      final filePath = '$dirPath${Platform.pathSeparator}fees_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      AppLogger.info('Fees exported to Excel: $filePath');
      return filePath;
    } catch (e) {
      AppLogger.error('Error exporting fees to Excel: $e');
      return null;
    }
  }

  // Helper: Build PDF Header
  static pw.Widget _buildPDFHeader(School school, pw.ImageProvider? logo, String title) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logo != null)
              pw.Image(logo, width: 60, height: 60)
            else
              pw.Container(width: 60, height: 60),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    school.name,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    school.address,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Tel: ${school.contactNumber}',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.Container(width: 60),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // Helper: Build PDF Footer
  static pw.Widget _buildPDFFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Powered by School Management System',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  // Helper: Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Helper: Build attendance summary
  static pw.Widget _buildAttendanceSummary(List<Map<String, dynamic>> attendanceData) {
    int total = attendanceData.length;
    int present = attendanceData.where((r) => r['status'] == 'Present').length;
    int absent = attendanceData.where((r) => r['status'] == 'Absent').length;
    int leave = attendanceData.where((r) => r['status'] == 'Leave').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: PdfColors.grey200,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(total.toString()),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Present', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(present.toString()),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Absent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(absent.toString()),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Leave', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(leave.toString()),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Attendance %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(total > 0 ? '${((present / total) * 100).toStringAsFixed(1)}%' : '0%'),
            ],
          ),
        ],
      ),
    );
  }

  // Open generated file
  static Future<void> openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      AppLogger.error('Error opening file: $e');
    }
  }
}
