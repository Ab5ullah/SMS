import '../services/firestore_service.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/attendance.dart';
import '../models/fee.dart';
import '../utils/logger.dart';

class StatisticsService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<Map<String, dynamic>> getSchoolStatistics(String schoolId) async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _firestoreService.getStudents(schoolId),
        _firestoreService.getTeachers(schoolId),
        _firestoreService.getFees(schoolId),
        _firestoreService.getAttendance(schoolId, DateTime.now()),
      ]);

      final students = results[0] as List<Student>;
      final teachers = results[1] as List<Teacher>;
      final fees = results[2] as List<Fee>;
      final todayAttendance = results[3] as List<Attendance>;

      // Calculate statistics
      final totalStudents = students.length;
      final totalTeachers = teachers.length;

      // Calculate total fees collected
      double totalFeesCollected = 0;
      for (var fee in fees) {
        totalFeesCollected += fee.paidAmount;
      }

      // Calculate today's attendance percentage
      double attendancePercentage = 0;
      if (todayAttendance.isNotEmpty) {
        final presentCount = todayAttendance
            .where((a) => a.status.toLowerCase() == 'present')
            .length;
        attendancePercentage = (presentCount / todayAttendance.length) * 100;
      }

      // Get class-wise student count
      Map<String, int> classWiseCount = {};
      for (var student in students) {
        final key = '${student.className}-${student.section}';
        classWiseCount[key] = (classWiseCount[key] ?? 0) + 1;
      }

      // Get fee statistics
      final paidFees = fees.where((f) => f.status == 'Paid').length;
      final unpaidFees = fees.where((f) => f.status == 'Unpaid').length;
      final partialFees = fees.where((f) => f.status == 'Partial').length;

      double totalFeesExpected = 0;
      double totalFeesDue = 0;
      for (var fee in fees) {
        totalFeesExpected += fee.amount;
        totalFeesDue += (fee.amount - fee.paidAmount);
      }

      return {
        'totalStudents': totalStudents,
        'totalTeachers': totalTeachers,
        'totalFeesCollected': totalFeesCollected,
        'attendancePercentage': attendancePercentage,
        'attendanceToday': todayAttendance.length,
        'presentToday': todayAttendance
            .where((a) => a.status.toLowerCase() == 'present')
            .length,
        'absentToday': todayAttendance
            .where((a) => a.status.toLowerCase() == 'absent')
            .length,
        'classWiseCount': classWiseCount,
        'paidFeesCount': paidFees,
        'unpaidFeesCount': unpaidFees,
        'partialFeesCount': partialFees,
        'totalFeesExpected': totalFeesExpected,
        'totalFeesDue': totalFeesDue,
      };
    } catch (e) {
      AppLogger.error('Error fetching school statistics: $e');
      return {
        'totalStudents': 0,
        'totalTeachers': 0,
        'totalFeesCollected': 0.0,
        'attendancePercentage': 0.0,
        'attendanceToday': 0,
        'presentToday': 0,
        'absentToday': 0,
        'classWiseCount': {},
        'paidFeesCount': 0,
        'unpaidFeesCount': 0,
        'partialFeesCount': 0,
        'totalFeesExpected': 0.0,
        'totalFeesDue': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities(String schoolId) async {
    try {
      // Get recent students (last 5)
      final students = await _firestoreService.getStudents(schoolId);
      students.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      List<Map<String, dynamic>> activities = [];

      for (var i = 0; i < (students.length > 5 ? 5 : students.length); i++) {
        activities.add({
          'type': 'student_added',
          'message': 'New student enrolled: ${students[i].name}',
          'time': students[i].createdAt,
          'icon': 'person_add',
        });
      }

      // Sort by time
      activities.sort((a, b) =>
        (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      return activities.take(10).toList();
    } catch (e) {
      AppLogger.error('Error fetching recent activities: $e');
      return [];
    }
  }
}
