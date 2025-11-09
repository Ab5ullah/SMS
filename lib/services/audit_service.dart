import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';
import '../utils/logger.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log a create action
  Future<void> logCreate({
    required String schoolId,
    required String userId,
    required String userName,
    required String userEmail,
    required String module,
    required String recordId,
    required String recordTitle,
  }) async {
    try {
      final log = AuditLog(
        id: '',
        schoolId: schoolId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        action: 'create',
        module: module,
        recordId: recordId,
        recordTitle: recordTitle,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('audit_logs').add(log.toMap());
      AppLogger.info('Audit log created: $module - $recordTitle');
    } catch (e) {
      AppLogger.error('Error creating audit log: $e');
      // Don't rethrow - audit logs shouldn't break main functionality
    }
  }

  /// Log an update action
  Future<void> logUpdate({
    required String schoolId,
    required String userId,
    required String userName,
    required String userEmail,
    required String module,
    required String recordId,
    required String recordTitle,
    Map<String, dynamic>? changes,
  }) async {
    try {
      final log = AuditLog(
        id: '',
        schoolId: schoolId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        action: 'update',
        module: module,
        recordId: recordId,
        recordTitle: recordTitle,
        changes: changes,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('audit_logs').add(log.toMap());
      AppLogger.info('Audit log updated: $module - $recordTitle');
    } catch (e) {
      AppLogger.error('Error creating audit log: $e');
    }
  }

  /// Log a delete action
  Future<void> logDelete({
    required String schoolId,
    required String userId,
    required String userName,
    required String userEmail,
    required String module,
    required String recordId,
    required String recordTitle,
  }) async {
    try {
      final log = AuditLog(
        id: '',
        schoolId: schoolId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        action: 'delete',
        module: module,
        recordId: recordId,
        recordTitle: recordTitle,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('audit_logs').add(log.toMap());
      AppLogger.info('Audit log deleted: $module - $recordTitle');
    } catch (e) {
      AppLogger.error('Error creating audit log: $e');
    }
  }

  /// Get audit logs for a school
  Stream<QuerySnapshot> getAuditLogs(String schoolId, {int limit = 100}) {
    return _firestore
        .collection('audit_logs')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Get audit logs for a specific module
  Stream<QuerySnapshot> getModuleAuditLogs(
    String schoolId,
    String module, {
    int limit = 50,
  }) {
    return _firestore
        .collection('audit_logs')
        .where('schoolId', isEqualTo: schoolId)
        .where('module', isEqualTo: module)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Get audit logs for a specific record
  Stream<QuerySnapshot> getRecordAuditLogs(
    String schoolId,
    String module,
    String recordId,
  ) {
    return _firestore
        .collection('audit_logs')
        .where('schoolId', isEqualTo: schoolId)
        .where('module', isEqualTo: module)
        .where('recordId', isEqualTo: recordId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get audit logs by user
  Stream<QuerySnapshot> getUserAuditLogs(
    String schoolId,
    String userId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('audit_logs')
        .where('schoolId', isEqualTo: schoolId)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Delete old audit logs (older than specified days)
  Future<void> cleanupOldLogs(String schoolId, int daysToKeep) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep));

      final oldLogs = await _firestore
          .collection('audit_logs')
          .where('schoolId', isEqualTo: schoolId)
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (var doc in oldLogs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info('Cleaned up ${oldLogs.docs.length} old audit logs');
    } catch (e) {
      AppLogger.error('Error cleaning up old audit logs: $e');
    }
  }
}
