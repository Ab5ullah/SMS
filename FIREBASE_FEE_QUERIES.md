# Firebase Fee Queries - Complete Reference Guide

This document contains all Firebase Firestore queries for fee management in the School Management System.

---

## 📋 Table of Contents

1. [Collection Structure](#collection-structure)
2. [Required Indexes](#required-indexes)
3. [Basic Queries](#basic-queries)
4. [Status-Based Queries](#status-based-queries)
5. [Time-Based Queries](#time-based-queries)
6. [Class-Based Queries](#class-based-queries)
7. [Combined Queries](#combined-queries)
8. [Statistics & Aggregations](#statistics--aggregations)
9. [Realtime Queries](#realtime-queries)
10. [Batch Operations](#batch-operations)
11. [Usage Examples](#usage-examples)

---

## 🏗️ Collection Structure

### Collection: `fees`

```json
{
  "id": "auto-generated",
  "schoolId": "school_001",
  "studentId": "student_123",
  "studentName": "Ahmed Khan",
  "className": "Class 5",
  "section": "A",
  "amount": 5000.0,
  "paidAmount": 2500.0,
  "dueDate": "2025-01-15T00:00:00.000Z",
  "paidDate": "2025-01-10T00:00:00.000Z",
  "status": "Partial",
  "month": "January",
  "year": 2025,
  "remarks": "Partial payment received",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-10T00:00:00.000Z",
  "synced": true
}
```

### Status Values
- `"Paid"` - Fully paid
- `"Unpaid"` - Not paid at all
- `"Partial"` - Partially paid

---

## 🔐 Required Indexes

Create these composite indexes in Firebase Console:

### Index 1: School + Month + Year
```
Collection: fees
Fields:
  - schoolId (Ascending)
  - month (Ascending)
  - year (Ascending)
  - className (Ascending)
```

### Index 2: School + Status + Due Date
```
Collection: fees
Fields:
  - schoolId (Ascending)
  - status (Ascending)
  - dueDate (Ascending)
```

### Index 3: School + Class + Month
```
Collection: fees
Fields:
  - schoolId (Ascending)
  - className (Ascending)
  - month (Ascending)
  - year (Ascending)
  - status (Ascending)
```

### Index 4: School + Student + Year
```
Collection: fees
Fields:
  - schoolId (Ascending)
  - studentId (Ascending)
  - year (Descending)
  - createdAt (Descending)
```

### Index 5: School + Class + Section
```
Collection: fees
Fields:
  - schoolId (Ascending)
  - className (Ascending)
  - section (Ascending)
  - createdAt (Descending)
```

**To create indexes:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Add fields as shown above
4. Click "Create"

---

## 📖 Basic Queries

### 1. Get All Fees for a School

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Fee>> getAllFees(String schoolId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 2. Get Fees for a Specific Student

```dart
Future<List<Fee>> getStudentFees(String schoolId, String studentId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('studentId', isEqualTo: studentId)
      .orderBy('year', descending: true)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 3. Get Single Fee by ID

```dart
Future<Fee?> getFeeById(String feeId) async {
  DocumentSnapshot doc = await FirebaseFirestore.instance
      .collection('fees')
      .doc(feeId)
      .get();

  if (doc.exists) {
    return Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
  return null;
}
```

---

## 💰 Status-Based Queries

### 1. Get All Paid Fees

```dart
Future<List<Fee>> getPaidFees(String schoolId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('status', isEqualTo: 'Paid')
      .orderBy('paidDate', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 2. Get All Unpaid Fees

```dart
Future<List<Fee>> getUnpaidFees(String schoolId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('status', isEqualTo: 'Unpaid')
      .orderBy('dueDate', descending: false)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 3. Get All Partial Fees

```dart
Future<List<Fee>> getPartialFees(String schoolId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('status', isEqualTo: 'Partial')
      .orderBy('dueDate', descending: false)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

---

## 📅 Time-Based Queries

### 1. Get Fees for a Specific Month

```dart
Future<List<Fee>> getFeesByMonth(String schoolId, String month, int year) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
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
}
```

### 2. Get Fees for a Specific Year

```dart
Future<List<Fee>> getFeesByYear(String schoolId, int year) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('year', isEqualTo: year)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 3. Get Overdue Fees

```dart
Future<List<Fee>> getOverdueFees(String schoolId) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('status', whereIn: ['Unpaid', 'Partial'])
      .where('dueDate', isLessThan: todayStart)
      .orderBy('dueDate', descending: false)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 4. Get Current Month Due Fees

```dart
Future<List<Fee>> getCurrentMonthDueFees(String schoolId) async {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('dueDate', isGreaterThanOrEqualTo: monthStart)
      .where('dueDate', isLessThanOrEqualTo: monthEnd)
      .orderBy('dueDate', descending: false)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

---

## 🏫 Class-Based Queries

### 1. Get Fees by Class

```dart
Future<List<Fee>> getFeesByClass(String schoolId, String className) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('className', isEqualTo: className)
      .orderBy('section')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

### 2. Get Fees by Class and Section

```dart
Future<List<Fee>> getFeesByClassSection(
    String schoolId, String className, String section) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('className', isEqualTo: className)
      .where('section', isEqualTo: section)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}
```

---

## 🔄 Combined Queries

### 1. Unpaid Fees for a Specific Month

```dart
Future<List<Fee>> getUnpaidFeesByMonth(
    String schoolId, String month, int year) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
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
}
```

### 2. Paid Fees for Class in a Month

```dart
Future<List<Fee>> getPaidFeesByClassAndMonth(
    String schoolId, String className, String month, int year) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
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
}
```

---

## 📊 Statistics & Aggregations

### 1. Total Fees Collected

```dart
Future<double> getTotalFeesCollected(String schoolId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .get();

  double total = 0;
  for (var doc in snapshot.docs) {
    final fee = Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    total += fee.paidAmount;
  }
  return total;
}
```

### 2. Total Outstanding Fees

```dart
Future<double> getTotalOutstandingFees(String schoolId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('status', whereIn: ['Unpaid', 'Partial'])
      .get();

  double total = 0;
  for (var doc in snapshot.docs) {
    final fee = Fee.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    total += fee.remainingAmount; // amount - paidAmount
  }
  return total;
}
```

### 3. Monthly Fee Summary

```dart
Future<Map<String, dynamic>> getMonthlyFeeSummary(
    String schoolId, String month, int year) async {
  final fees = await getFeesByMonth(schoolId, month, year);

  int totalCount = fees.length;
  int paidCount = fees.where((f) => f.status == 'Paid').length;
  int unpaidCount = fees.where((f) => f.status == 'Unpaid').length;
  int partialCount = fees.where((f) => f.status == 'Partial').length;

  double totalAmount = fees.fold(0.0, (sum, fee) => sum + fee.amount);
  double paidAmount = fees.fold(0.0, (sum, fee) => sum + fee.paidAmount);
  double pendingAmount = totalAmount - paidAmount;

  return {
    'totalCount': totalCount,
    'paidCount': paidCount,
    'unpaidCount': unpaidCount,
    'partialCount': partialCount,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'pendingAmount': pendingAmount,
    'collectionPercentage': totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0,
  };
}
```

---

## 🔴 Realtime Queries (Streams)

### 1. Realtime All Fees

```dart
Stream<List<Fee>> getFeesStream(String schoolId) {
  return FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Fee.fromMap(doc.data(), doc.id))
          .toList());
}
```

### 2. Realtime Unpaid Fees

```dart
Stream<List<Fee>> getUnpaidFeesStream(String schoolId) {
  return FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('status', isEqualTo: 'Unpaid')
      .orderBy('dueDate', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Fee.fromMap(doc.data(), doc.id))
          .toList());
}
```

### 3. Realtime Student Fees

```dart
Stream<List<Fee>> getStudentFeesStream(String schoolId, String studentId) {
  return FirebaseFirestore.instance
      .collection('fees')
      .where('schoolId', isEqualTo: schoolId)
      .where('studentId', isEqualTo: studentId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Fee.fromMap(doc.data(), doc.id))
          .toList());
}
```

---

## 🔄 Batch Operations

### 1. Add New Fee

```dart
Future<void> addFee(Fee fee) async {
  await FirebaseFirestore.instance
      .collection('fees')
      .add(fee.toMap());
}
```

### 2. Update Fee

```dart
Future<void> updateFee(Fee fee) async {
  if (fee.id == null) throw Exception('Fee ID is null');

  await FirebaseFirestore.instance
      .collection('fees')
      .doc(fee.id)
      .update(fee.toMap());
}
```

### 3. Mark Fee as Paid

```dart
Future<void> markFeeAsPaid(String feeId, double paidAmount, DateTime paidDate) async {
  DocumentSnapshot feeDoc = await FirebaseFirestore.instance
      .collection('fees')
      .doc(feeId)
      .get();

  final fee = Fee.fromMap(feeDoc.data() as Map<String, dynamic>, feeDoc.id);
  final totalPaid = fee.paidAmount + paidAmount;

  String newStatus;
  if (totalPaid >= fee.amount) {
    newStatus = 'Paid';
  } else if (totalPaid > 0) {
    newStatus = 'Partial';
  } else {
    newStatus = 'Unpaid';
  }

  await FirebaseFirestore.instance
      .collection('fees')
      .doc(feeId)
      .update({
    'paidAmount': totalPaid,
    'paidDate': paidDate.toIso8601String(),
    'status': newStatus,
    'updatedAt': DateTime.now().toIso8601String(),
  });
}
```

### 4. Batch Mark Multiple Fees as Paid

```dart
Future<void> batchMarkAsPaid(List<String> feeIds, DateTime paidDate) async {
  WriteBatch batch = FirebaseFirestore.instance.batch();

  for (String feeId in feeIds) {
    DocumentReference feeRef = FirebaseFirestore.instance
        .collection('fees')
        .doc(feeId);

    batch.update(feeRef, {
      'status': 'Paid',
      'paidDate': paidDate.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  await batch.commit();
}
```

### 5. Generate Fees for All Students in a Class

```dart
Future<void> generateClassFees({
  required String schoolId,
  required List<Map<String, dynamic>> students,
  required String month,
  required int year,
  required double amount,
  required DateTime dueDate,
}) async {
  WriteBatch batch = FirebaseFirestore.instance.batch();
  final now = DateTime.now();

  for (var student in students) {
    DocumentReference feeRef = FirebaseFirestore.instance
        .collection('fees')
        .doc();

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
}
```

### 6. Delete Fee

```dart
Future<void> deleteFee(String feeId) async {
  await FirebaseFirestore.instance
      .collection('fees')
      .doc(feeId)
      .delete();
}
```

---

## 💡 Usage Examples

### Example 1: Display Unpaid Fees Dashboard

```dart
class UnpaidFeesDashboard extends StatelessWidget {
  final String schoolId;

  const UnpaidFeesDashboard({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Fee>>(
      stream: FeeQueryService().getUnpaidFeesStream(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No unpaid fees');
        }

        final fees = snapshot.data!;
        final totalDue = fees.fold(0.0, (sum, fee) => sum + fee.remainingAmount);

        return Column(
          children: [
            Text('Total Unpaid: Rs. ${totalDue.toStringAsFixed(0)}'),
            ListView.builder(
              itemCount: fees.length,
              itemBuilder: (context, index) {
                final fee = fees[index];
                return ListTile(
                  title: Text(fee.studentName),
                  subtitle: Text('${fee.className} - ${fee.section}'),
                  trailing: Text('Rs. ${fee.remainingAmount.toStringAsFixed(0)}'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
```

### Example 2: Monthly Fee Collection Report

```dart
Future<void> generateMonthlyReport(String schoolId) async {
  final feeService = FeeQueryService();
  final summary = await feeService.getMonthlyFeeSummary(
    schoolId,
    'January',
    2025,
  );

  print('Monthly Fee Report - January 2025');
  print('====================================');
  print('Total Fees: ${summary['totalCount']}');
  print('Paid: ${summary['paidCount']}');
  print('Unpaid: ${summary['unpaidCount']}');
  print('Partial: ${summary['partialCount']}');
  print('Total Amount: Rs. ${summary['totalAmount']}');
  print('Collected: Rs. ${summary['paidAmount']}');
  print('Pending: Rs. ${summary['pendingAmount']}');
  print('Collection Rate: ${summary['collectionPercentage'].toStringAsFixed(1)}%');
}
```

### Example 3: Search Student Fees

```dart
Future<void> searchAndDisplayStudentFees(
    String schoolId, String studentId) async {
  final feeService = FeeQueryService();
  final fees = await feeService.getStudentFees(schoolId, studentId);

  if (fees.isEmpty) {
    print('No fees found for this student');
    return;
  }

  print('Student Fee History');
  print('===================');
  for (var fee in fees) {
    print('${fee.month} ${fee.year}: Rs. ${fee.amount} - ${fee.status}');
    if (fee.status == 'Partial') {
      print('  Paid: Rs. ${fee.paidAmount}');
      print('  Remaining: Rs. ${fee.remainingAmount}');
    }
  }
}
```

---

## 🎯 Best Practices

1. **Always filter by schoolId first** to prevent cross-school data access
2. **Use indexes** for all compound queries (shown above)
3. **Limit results** using `.limit(n)` for large datasets
4. **Use streams** for real-time updates in UI
5. **Batch operations** for multiple writes to improve performance
6. **Handle errors** gracefully with try-catch blocks
7. **Cache data** locally using SQLite for offline support
8. **Use transactions** for critical operations like payments

---

## 🚀 Quick Start

Import the service:
```dart
import 'package:your_app/services/fee_query_service.dart';

final feeService = FeeQueryService();
```

Get unpaid fees:
```dart
final unpaidFees = await feeService.getUnpaidFees('school_001');
```

Monitor in real-time:
```dart
feeService.getUnpaidFeesStream('school_001').listen((fees) {
  print('Unpaid fees updated: ${fees.length}');
});
```

---

**Generated**: 2025-01-08
**Version**: 1.0.0
**Service File**: `lib/services/fee_query_service.dart`
