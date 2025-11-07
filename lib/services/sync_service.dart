import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/class_section.dart';
import '../models/attendance.dart';
import '../models/fee.dart';
import '../models/exam.dart';
import '../utils/logger.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Sync status callback
  Function(SyncStatus)? onSyncStatusChanged;

  /// Initialize sync service with auto-sync
  Future<void> initialize({bool enableAutoSync = true}) async {
    AppLogger.info('Initializing Sync Service...');

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Start auto-sync timer (every 5 minutes)
    if (enableAutoSync) {
      startAutoSync(duration: const Duration(minutes: 5));
    }

    AppLogger.info('Sync Service initialized successfully');
  }

  /// Start automatic sync timer
  void startAutoSync({Duration duration = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(duration, (timer) async {
      if (await isOnline()) {
        await performFullSync();
      }
    });
    AppLogger.info('Auto-sync started with interval: ${duration.inMinutes} minutes');
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    AppLogger.info('Auto-sync stopped');
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
    } catch (e) {
      AppLogger.error('Error checking connectivity: $e');
      return false;
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    if (isConnected) {
      AppLogger.info('Device is online. Starting sync...');
      performFullSync();
    } else {
      AppLogger.info('Device is offline. Sync paused.');
    }
  }

  /// Perform full bidirectional sync
  Future<SyncResult> performFullSync({String? schoolId}) async {
    if (_isSyncing) {
      AppLogger.warning('Sync already in progress. Skipping...');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (!await isOnline()) {
      AppLogger.warning('Device is offline. Cannot sync.');
      return SyncResult(success: false, message: 'Device is offline');
    }

    _isSyncing = true;
    _notifyStatus(SyncStatus.syncing);

    try {
      AppLogger.info('Starting full sync...');
      final startTime = DateTime.now();

      int uploadedCount = 0;
      int downloadedCount = 0;
      int conflictsResolved = 0;

      // Step 1: Push local changes to Firestore
      uploadedCount += await _syncStudentsToCloud(schoolId);
      uploadedCount += await _syncTeachersToCloud(schoolId);
      uploadedCount += await _syncClassSectionsToCloud(schoolId);
      uploadedCount += await _syncAttendanceToCloud(schoolId);
      uploadedCount += await _syncFeesToCloud(schoolId);
      uploadedCount += await _syncExamsToCloud(schoolId);
      uploadedCount += await _syncExamResultsToCloud(schoolId);

      // Step 2: Pull remote changes from Firestore
      downloadedCount += await _syncStudentsFromCloud(schoolId);
      downloadedCount += await _syncTeachersFromCloud(schoolId);
      downloadedCount += await _syncClassSectionsFromCloud(schoolId);
      downloadedCount += await _syncAttendanceFromCloud(schoolId);
      downloadedCount += await _syncFeesFromCloud(schoolId);
      downloadedCount += await _syncExamsFromCloud(schoolId);
      downloadedCount += await _syncExamResultsFromCloud(schoolId);

      _lastSyncTime = DateTime.now();
      final duration = _lastSyncTime!.difference(startTime);

      _isSyncing = false;
      _notifyStatus(SyncStatus.completed);

      final message =
          'Sync completed in ${duration.inSeconds}s. Uploaded: $uploadedCount, Downloaded: $downloadedCount';
      AppLogger.info(message);

      return SyncResult(
        success: true,
        message: message,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        conflictsResolved: conflictsResolved,
      );
    } catch (e) {
      _isSyncing = false;
      _notifyStatus(SyncStatus.failed);
      AppLogger.error('Sync failed: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  // ============ STUDENTS SYNC ============

  Future<int> _syncStudentsToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'students',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final student = Student.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            // Update existing record
            await _firestore
                .collection('students')
                .doc(record['id'])
                .set(student.toMap(), SetOptions(merge: true));
          } else {
            // Create new record
            final docRef =
                await _firestore.collection('students').add(student.toMap());
            // Update local record with Firestore ID
            await db.update(
              'students',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          // Mark as synced
          await db.update(
            'students',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing student ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count students to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing students to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncStudentsFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final student = Student.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'students',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          // Insert new record
          await db.insert('students', {
            ...student.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          // Check if cloud version is newer
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (student.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'students',
              {...student.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count students from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing students from cloud: $e');
      return 0;
    }
  }

  // ============ TEACHERS SYNC ============

  Future<int> _syncTeachersToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'teachers',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final teacher = Teacher.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            await _firestore
                .collection('teachers')
                .doc(record['id'])
                .set(teacher.toMap(), SetOptions(merge: true));
          } else {
            final docRef =
                await _firestore.collection('teachers').add(teacher.toMap());
            await db.update(
              'teachers',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          await db.update(
            'teachers',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing teacher ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count teachers to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing teachers to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncTeachersFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('teachers')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final teacher = Teacher.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'teachers',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('teachers', {
            ...teacher.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (teacher.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'teachers',
              {...teacher.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count teachers from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing teachers from cloud: $e');
      return 0;
    }
  }

  // ============ CLASS SECTIONS SYNC ============

  Future<int> _syncClassSectionsToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'class_sections',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final classSection = ClassSection.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            await _firestore
                .collection('class_sections')
                .doc(record['id'])
                .set(classSection.toMap(), SetOptions(merge: true));
          } else {
            final docRef = await _firestore
                .collection('class_sections')
                .add(classSection.toMap());
            await db.update(
              'class_sections',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          await db.update(
            'class_sections',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing class section ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count class sections to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing class sections to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncClassSectionsFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('class_sections')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final classSection = ClassSection.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'class_sections',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('class_sections', {
            ...classSection.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (classSection.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'class_sections',
              {...classSection.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count class sections from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing class sections from cloud: $e');
      return 0;
    }
  }

  // ============ ATTENDANCE SYNC ============

  Future<int> _syncAttendanceToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'attendance',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final attendance = Attendance.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            await _firestore
                .collection('attendance')
                .doc(record['id'])
                .set(attendance.toMap(), SetOptions(merge: true));
          } else {
            final docRef = await _firestore
                .collection('attendance')
                .add(attendance.toMap());
            await db.update(
              'attendance',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          await db.update(
            'attendance',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing attendance ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count attendance records to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing attendance to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncAttendanceFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final attendance = Attendance.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'attendance',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('attendance', {
            ...attendance.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (attendance.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'attendance',
              {...attendance.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count attendance records from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing attendance from cloud: $e');
      return 0;
    }
  }

  // ============ FEES SYNC ============

  Future<int> _syncFeesToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'fees',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final fee = Fee.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            await _firestore
                .collection('fees')
                .doc(record['id'])
                .set(fee.toMap(), SetOptions(merge: true));
          } else {
            final docRef =
                await _firestore.collection('fees').add(fee.toMap());
            await db.update(
              'fees',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          await db.update(
            'fees',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing fee ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count fees to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing fees to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncFeesFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('fees')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final fee = Fee.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'fees',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('fees', {
            ...fee.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (fee.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'fees',
              {...fee.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count fees from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing fees from cloud: $e');
      return 0;
    }
  }

  // ============ EXAMS SYNC ============

  Future<int> _syncExamsToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'exams',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final exam = Exam.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            await _firestore
                .collection('exams')
                .doc(record['id'])
                .set(exam.toMap(), SetOptions(merge: true));
          } else {
            final docRef =
                await _firestore.collection('exams').add(exam.toMap());
            await db.update(
              'exams',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          await db.update(
            'exams',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing exam ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count exams to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing exams to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncExamsFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final exam = Exam.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'exams',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('exams', {
            ...exam.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (exam.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'exams',
              {...exam.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count exams from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing exams from cloud: $e');
      return 0;
    }
  }

  // ============ EXAM RESULTS SYNC ============

  Future<int> _syncExamResultsToCloud(String? schoolId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> records = await db.query(
        'exam_results',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (records.isEmpty) return 0;

      int count = 0;
      for (var record in records) {
        final result = ExamResult.fromMap(record, record['id']);
        try {
          if (record['id'] != null && record['id'].toString().isNotEmpty) {
            await _firestore
                .collection('exam_results')
                .doc(record['id'])
                .set(result.toMap(), SetOptions(merge: true));
          } else {
            final docRef = await _firestore
                .collection('exam_results')
                .add(result.toMap());
            await db.update(
              'exam_results',
              {'id': docRef.id, 'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }

          await db.update(
            'exam_results',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          count++;
        } catch (e) {
          AppLogger.error('Error syncing exam result ${record['id']}: $e');
        }
      }

      AppLogger.info('Synced $count exam results to cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing exam results to cloud: $e');
      return 0;
    }
  }

  Future<int> _syncExamResultsFromCloud(String? schoolId) async {
    if (schoolId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('exam_results')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      final db = await _dbHelper.database;
      int count = 0;

      for (var doc in snapshot.docs) {
        final result = ExamResult.fromMap(doc.data(), doc.id);
        final existing = await db.query(
          'exam_results',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('exam_results', {
            ...result.toMap(),
            'id': doc.id,
            'synced': 1,
          });
          count++;
        } else {
          final localUpdated = DateTime.parse(existing.first['updatedAt'] as String);
          if (result.updatedAt.isAfter(localUpdated)) {
            await db.update(
              'exam_results',
              {...result.toMap(), 'synced': 1},
              where: 'id = ?',
              whereArgs: [doc.id],
            );
            count++;
          }
        }
      }

      AppLogger.info('Synced $count exam results from cloud');
      return count;
    } catch (e) {
      AppLogger.error('Error syncing exam results from cloud: $e');
      return 0;
    }
  }

  /// Get sync status
  SyncInfo getSyncInfo() {
    return SyncInfo(
      isSyncing: _isSyncing,
      lastSyncTime: _lastSyncTime,
      isOnline: _connectivity.checkConnectivity().then((results) =>
          results.isNotEmpty && !results.contains(ConnectivityResult.none)),
    );
  }

  /// Notify listeners of sync status change
  void _notifyStatus(SyncStatus status) {
    onSyncStatusChanged?.call(status);
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    AppLogger.info('Sync Service disposed');
  }
}

// ============ MODELS ============

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;
  final int conflictsResolved;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.conflictsResolved = 0,
  });
}

class SyncInfo {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final Future<bool> isOnline;

  SyncInfo({
    required this.isSyncing,
    required this.lastSyncTime,
    required this.isOnline,
  });
}
