import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee.dart';
import '../utils/logger.dart';

/// Comprehensive Fee Query Service for Firebase Firestore
/// Provides all types of fee-related queries needed for the school management system
class FeeQueryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== BASIC QUERIES ====================

  /// Get all fees for a school
  Future<List<Fee>> getAllFees(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching all fees: $e');
      return [];
    }
  }

  /// Get fees for a specific student
  Future<List<Fee>> getStudentFees(String schoolId, String studentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('studentId', isEqualTo: studentId)
          .orderBy('year', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching student fees: $e');
      return [];
    }
  }

  // ==================== STATUS-BASED QUERIES ====================

  /// Get all paid fees
  Future<List<Fee>> getPaidFees(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('status', isEqualTo: 'Paid')
          .orderBy('paidDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching paid fees: $e');
      return [];
    }
  }

  /// Get all unpaid fees
  Future<List<Fee>> getUnpaidFees(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('status', isEqualTo: 'Unpaid')
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching unpaid fees: $e');
      return [];
    }
  }

  /// Get all partially paid fees
  Future<List<Fee>> getPartialFees(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('status', isEqualTo: 'Partial')
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching partial fees: $e');
      return [];
    }
  }

  // ==================== TIME-BASED QUERIES ====================

  /// Get fees for a specific month and year
  Future<List<Fee>> getFeesByMonth(String schoolId, String month, int year) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .orderBy('className')
          .orderBy('section')
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching fees by month: $e');
      return [];
    }
  }

  /// Get fees for a specific year
  Future<List<Fee>> getFeesByYear(String schoolId, int year) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('year', isEqualTo: year)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching fees by year: $e');
      return [];
    }
  }

  /// Get overdue fees (unpaid fees past due date)
  Future<List<Fee>> getOverdueFees(String schoolId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('status', whereIn: ['Unpaid', 'Partial'])
          .where('dueDate', isLessThan: todayStart)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching overdue fees: $e');
      return [];
    }
  }

  /// Get fees due in current month
  Future<List<Fee>> getCurrentMonthDueFees(String schoolId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('dueDate', isGreaterThanOrEqualTo: monthStart)
          .where('dueDate', isLessThanOrEqualTo: monthEnd)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching current month due fees: $e');
      return [];
    }
  }

  // ==================== CLASS-BASED QUERIES ====================

  /// Get fees for a specific class
  Future<List<Fee>> getFeesByClass(String schoolId, String className) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('className', isEqualTo: className)
          .orderBy('section')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching fees by class: $e');
      return [];
    }
  }

  /// Get fees for a specific class and section
  Future<List<Fee>> getFeesByClassSection(
      String schoolId, String className, String section) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('className', isEqualTo: className)
          .where('section', isEqualTo: section)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching fees by class and section: $e');
      return [];
    }
  }

  // ==================== COMBINED QUERIES ====================

  /// Get unpaid fees for a specific month
  Future<List<Fee>> getUnpaidFeesByMonth(
      String schoolId, String month, int year) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .where('status', isEqualTo: 'Unpaid')
          .orderBy('className')
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching unpaid fees by month: $e');
      return [];
    }
  }

  /// Get paid fees for a specific class in a month
  Future<List<Fee>> getPaidFeesByClassAndMonth(
      String schoolId, String className, String month, int year) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('className', isEqualTo: className)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .where('status', isEqualTo: 'Paid')
          .orderBy('section')
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching paid fees by class and month: $e');
      return [];
    }
  }

  // ==================== STATISTICS & AGGREGATIONS ====================

  /// Get total fees collected for a school
  Future<double> getTotalFeesCollected(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final fee = Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        total += fee.paidAmount;
      }
      return total;
    } catch (e) {
      AppLogger.error('Error calculating total fees collected: $e');
      return 0.0;
    }
  }

  /// Get total outstanding fees (unpaid + partial)
  Future<double> getTotalOutstandingFees(String schoolId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .where('status', whereIn: ['Unpaid', 'Partial'])
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final fee = Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        total += fee.remainingAmount;
      }
      return total;
    } catch (e) {
      AppLogger.error('Error calculating total outstanding fees: $e');
      return 0.0;
    }
  }

  /// Get fee collection summary for a month
  Future<Map<String, dynamic>> getMonthlyFeeSummary(
      String schoolId, String month, int year) async {
    try {
      final fees = await getFeesByMonth(schoolId, month, year);

      int totalCount = fees.length;
      int paidCount = fees.where((f) => f.status == 'Paid').length;
      int unpaidCount = fees.where((f) => f.status == 'Unpaid').length;
      int partialCount = fees.where((f) => f.status == 'Partial').length;

      double totalAmount = fees.fold(0, (sum, fee) => sum + fee.amount);
      double paidAmount = fees.fold(0, (sum, fee) => sum + fee.paidAmount);
      double pendingAmount = totalAmount - paidAmount;

      return {
        'totalCount': totalCount,
        'paidCount': paidCount,
        'unpaidCount': unpaidCount,
        'partialCount': partialCount,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'collectionPercentage':
            totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0,
      };
    } catch (e) {
      AppLogger.error('Error getting monthly fee summary: $e');
      return {};
    }
  }

  /// Get fee collection summary by class
  Future<Map<String, Map<String, dynamic>>> getClasswiseFeeSummary(
      String schoolId) async {
    try {
      final fees = await getAllFees(schoolId);
      Map<String, Map<String, dynamic>> classSummary = {};

      for (var fee in fees) {
        final key = '${fee.className}-${fee.section}';
        if (!classSummary.containsKey(key)) {
          classSummary[key] = {
            'className': fee.className,
            'section': fee.section,
            'totalAmount': 0.0,
            'paidAmount': 0.0,
            'pendingAmount': 0.0,
            'studentCount': 0,
            'paidCount': 0,
            'unpaidCount': 0,
          };
        }

        classSummary[key]!['totalAmount'] += fee.amount;
        classSummary[key]!['paidAmount'] += fee.paidAmount;
        classSummary[key]!['pendingAmount'] += fee.remainingAmount;
        classSummary[key]!['studentCount']++;

        if (fee.status == 'Paid') {
          classSummary[key]!['paidCount']++;
        } else {
          classSummary[key]!['unpaidCount']++;
        }
      }

      return classSummary;
    } catch (e) {
      AppLogger.error('Error getting classwise fee summary: $e');
      return {};
    }
  }

  // ==================== SEARCH QUERIES ====================

  /// Search fees by student name
  Future<List<Fee>> searchFeesByStudentName(
      String schoolId, String searchTerm) async {
    try {
      // Note: Firestore doesn't support case-insensitive search natively
      // This is a basic implementation. For production, consider using Algolia or similar
      QuerySnapshot snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('studentName')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error searching fees by student name: $e');
      // Fallback to client-side filtering
      final allFees = await getAllFees(schoolId);
      return allFees
          .where((fee) =>
              fee.studentName.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    }
  }

  // ==================== REALTIME QUERIES ====================

  /// Get realtime stream of all fees for a school
  Stream<List<Fee>> getFeesStream(String schoolId) {
    return _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get realtime stream of unpaid fees
  Stream<List<Fee>> getUnpaidFeesStream(String schoolId) {
    return _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: 'Unpaid')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get realtime stream of student's fees
  Stream<List<Fee>> getStudentFeesStream(String schoolId, String studentId) {
    return _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ==================== BATCH OPERATIONS ====================

  /// Mark multiple fees as paid in a batch
  Future<void> batchMarkAsPaid(
      List<String> feeIds, DateTime paidDate) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (String feeId in feeIds) {
        DocumentReference feeRef = _firestore.collection('fees').doc(feeId);
        batch.update(feeRef, {
          'status': 'Paid',
          'paidDate': paidDate.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      AppLogger.info('Batch marked ${feeIds.length} fees as paid');
    } catch (e) {
      AppLogger.error('Error in batch mark as paid: $e');
      rethrow;
    }
  }

  /// Generate fees for all students in a class for a month
  Future<void> generateClassFees({
    required String schoolId,
    required List<Map<String, dynamic>> students,
    required String month,
    required int year,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      final now = DateTime.now();

      for (var student in students) {
        DocumentReference feeRef = _firestore.collection('fees').doc();

        batch.set(feeRef, {
          'schoolId': schoolId,
          'studentId': student['id'],
          'studentName': student['name'],
          'className': student['className'],
          'section': student['section'],
          'amount': amount,
          'paidAmount': 0.0,
          'dueDate': dueDate.toIso8601String(),
          'status': 'Unpaid',
          'month': month,
          'year': year,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'synced': true,
        });
      }

      await batch.commit();
      AppLogger.info('Generated fees for ${students.length} students');
    } catch (e) {
      AppLogger.error('Error generating class fees: $e');
      rethrow;
    }
  }
}
