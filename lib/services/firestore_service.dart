import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/class_section.dart';
import '../models/attendance.dart';
import '../models/fee.dart';
import '../models/exam.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // STUDENTS
  Future<List<Student>> getStudents(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return snapshot.docs
          .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching students: $e');
      return [];
    }
  }

  Future<void> addStudent(Student student) async {
    try {
      await _firestore.collection('students').add(student.toMap());
      AppLogger.info('Student added successfully');
    } catch (e) {
      AppLogger.error('Error adding student: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      if (student.id == null) throw Exception('Student ID is null');
      await _firestore
          .collection('students')
          .doc(student.id)
          .update(student.toMap());
      AppLogger.info('Student updated successfully');
    } catch (e) {
      AppLogger.error('Error updating student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
      AppLogger.info('Student deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting student: $e');
      rethrow;
    }
  }

  // TEACHERS
  Future<List<Teacher>> getTeachers(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('teachers')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return snapshot.docs
          .map((doc) => Teacher.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching teachers: $e');
      return [];
    }
  }

  Future<void> addTeacher(Teacher teacher) async {
    try {
      await _firestore.collection('teachers').add(teacher.toMap());
      AppLogger.info('Teacher added successfully');
    } catch (e) {
      AppLogger.error('Error adding teacher: $e');
      rethrow;
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      if (teacher.id == null) throw Exception('Teacher ID is null');
      await _firestore
          .collection('teachers')
          .doc(teacher.id)
          .update(teacher.toMap());
      AppLogger.info('Teacher updated successfully');
    } catch (e) {
      AppLogger.error('Error updating teacher: $e');
      rethrow;
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).delete();
      AppLogger.info('Teacher deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting teacher: $e');
      rethrow;
    }
  }

  // CLASS SECTIONS
  Future<List<ClassSection>> getClassSections(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('class_sections')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return snapshot.docs
          .map((doc) =>
              ClassSection.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching class sections: $e');
      return [];
    }
  }

  Future<void> addClassSection(ClassSection classSection) async {
    try {
      await _firestore.collection('class_sections').add(classSection.toMap());
      AppLogger.info('Class section added successfully');
    } catch (e) {
      AppLogger.error('Error adding class section: $e');
      rethrow;
    }
  }

  Future<void> updateClassSection(ClassSection classSection) async {
    try {
      if (classSection.id == null) throw Exception('Class section ID is null');
      await _firestore
          .collection('class_sections')
          .doc(classSection.id)
          .update(classSection.toMap());
      AppLogger.info('Class section updated successfully');
    } catch (e) {
      AppLogger.error('Error updating class section: $e');
      rethrow;
    }
  }

  Future<void> deleteClassSection(String classSectionId) async {
    try {
      await _firestore.collection('class_sections').doc(classSectionId).delete();
      AppLogger.info('Class section deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting class section: $e');
      rethrow;
    }
  }

  // ATTENDANCE
  Future<List<Attendance>> getAttendance(
      String schoolId, DateTime date) async {
    try {
      String dateStr = date.toIso8601String().split('T')[0];
      QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('schoolId', isEqualTo: schoolId)
          .where('date', isGreaterThanOrEqualTo: '${dateStr}T00:00:00.000')
          .where('date', isLessThan: '${dateStr}T23:59:59.999')
          .get();

      return snapshot.docs
          .map((doc) =>
              Attendance.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching attendance: $e');
      return [];
    }
  }

  Future<void> markAttendance(List<Attendance> attendanceList) async {
    try {
      WriteBatch batch = _firestore.batch();
      for (var attendance in attendanceList) {
        if (attendance.id != null) {
          batch.update(
            _firestore.collection('attendance').doc(attendance.id),
            attendance.toMap(),
          );
        } else {
          batch.set(
            _firestore.collection('attendance').doc(),
            attendance.toMap(),
          );
        }
      }
      await batch.commit();
      AppLogger.info('Attendance marked successfully');
    } catch (e) {
      AppLogger.error('Error marking attendance: $e');
      rethrow;
    }
  }

  // FEES
  Future<List<Fee>> getFees(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching fees: $e');
      return [];
    }
  }

  Future<void> addFee(Fee fee) async {
    try {
      await _firestore.collection('fees').add(fee.toMap());
      AppLogger.info('Fee added successfully');
    } catch (e) {
      AppLogger.error('Error adding fee: $e');
      rethrow;
    }
  }

  Future<void> updateFee(Fee fee) async {
    try {
      if (fee.id == null) throw Exception('Fee ID is null');
      await _firestore.collection('fees').doc(fee.id).update(fee.toMap());
      AppLogger.info('Fee updated successfully');
    } catch (e) {
      AppLogger.error('Error updating fee: $e');
      rethrow;
    }
  }

  // EXAMS
  Future<List<Exam>> getExams(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exams')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return snapshot.docs
          .map((doc) => Exam.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching exams: $e');
      return [];
    }
  }

  Future<void> addExam(Exam exam) async {
    try {
      await _firestore.collection('exams').add(exam.toMap());
      AppLogger.info('Exam added successfully');
    } catch (e) {
      AppLogger.error('Error adding exam: $e');
      rethrow;
    }
  }

  Future<void> updateExam(Exam exam) async {
    try {
      if (exam.id == null) throw Exception('Exam ID is null');
      await _firestore.collection('exams').doc(exam.id).update(exam.toMap());
      AppLogger.info('Exam updated successfully');
    } catch (e) {
      AppLogger.error('Error updating exam: $e');
      rethrow;
    }
  }

  Future<void> deleteExam(String examId) async {
    try {
      await _firestore.collection('exams').doc(examId).delete();
      AppLogger.info('Exam deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting exam: $e');
      rethrow;
    }
  }

  // EXAM RESULTS
  Future<List<ExamResult>> getExamResults(String schoolId, String examId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exam_results')
          .where('schoolId', isEqualTo: schoolId)
          .where('examId', isEqualTo: examId)
          .get();

      return snapshot.docs
          .map((doc) =>
              ExamResult.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching exam results: $e');
      return [];
    }
  }

  Future<void> addExamResult(ExamResult result) async {
    try {
      await _firestore.collection('exam_results').add(result.toMap());
      AppLogger.info('Exam result added successfully');
    } catch (e) {
      AppLogger.error('Error adding exam result: $e');
      rethrow;
    }
  }

  Future<void> updateExamResult(ExamResult result) async {
    try {
      if (result.id == null) throw Exception('Exam result ID is null');
      await _firestore
          .collection('exam_results')
          .doc(result.id)
          .update(result.toMap());
      AppLogger.info('Exam result updated successfully');
    } catch (e) {
      AppLogger.error('Error updating exam result: $e');
      rethrow;
    }
  }
}
